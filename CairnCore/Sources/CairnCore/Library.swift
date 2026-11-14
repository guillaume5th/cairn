import Foundation
import SwiftData

/// How long unkept articles stay: purged after, and not imported when older. Set in Settings, on this Mac.
public enum Retention {
    public static let key = "articleRetentionDays"
    public static let defaultDays = 30

    public static func days(in defaults: UserDefaults = .standard) -> Int {
        defaults.object(forKey: key) as? Int ?? defaultDays
    }

    public static func cutoff(now: Date = .now) -> Date {
        now.addingTimeInterval(-Double(days()) * 86_400)
    }
}

/// All operations on the user's library. Changes are left to the context's autosave.
public enum Library {
    // MARK: Subscriptions

    @MainActor
    public static func addFeed(urlString: String, context: ModelContext, fetcher: FeedFetcher, now: Date = .now) async throws -> Feed {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed), ["http", "https"].contains(url.scheme?.lowercased()), url.host() != nil else {
            throw CairnError.invalidURL
        }
        guard try !isSubscribed(trimmed, context: context) else { throw CairnError.alreadySubscribed }
        let parsed = try await fetcher.fetch(url)
        // Re-check: another add may have finished while we were fetching.
        guard try !isSubscribed(trimmed, context: context) else { throw CairnError.alreadySubscribed }

        let feed = Feed(url: trimmed, title: parsed.title.isEmpty ? (url.host() ?? trimmed) : parsed.title)
        context.insert(feed)
        ingest(parsed, into: feed, context: context, now: now)
        return feed
    }

    /// Deletes the feed and its non-kept articles; kept articles stay in the cairn with a copy of the feed icon.
    public static func delete(_ feed: Feed, context: ModelContext) {
        for article in feed.articles ?? [] {
            if article.isKept {
                article.sourceIconData = feed.iconData
            } else {
                context.delete(article)
            }
        }
        context.delete(feed)
    }

    /// Creates a feed for each OPML entry not already followed, in its folder (matched by key, created if missing).
    /// Feeds already followed keep their folder. Feeds get their articles on the next refresh.
    public static func importOPML(_ data: Data, context: ModelContext) throws -> (added: Int, skipped: Int) {
        let entries = try OPML.parse(data)
        var known = Set(try context.fetch(FetchDescriptor<Feed>()).map(\.url))
        var folders = Dictionary(try context.fetch(FetchDescriptor<Folder>()).map { ($0.key, $0) }, uniquingKeysWith: { a, _ in a })
        var added = 0
        for entry in entries where known.insert(entry.url).inserted {
            let feed = Feed(url: entry.url, title: entry.title)
            context.insert(feed)
            if let name = entry.folder {
                let key = tagKey(name)
                if folders[key] == nil {
                    let folder = Folder(name: name)
                    context.insert(folder)
                    folders[key] = folder
                }
                feed.folder = folders[key]
            }
            added += 1
        }
        return (added, entries.count - added)
    }

    public static func exportOPML(context: ModelContext) throws -> Data {
        let feeds = try context.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.title)]))
            .sorted { ($0.folder?.name ?? "").localizedStandardCompare($1.folder?.name ?? "") == .orderedAscending }
        return OPML.export(feeds.map { OPMLFeed(title: $0.title, url: $0.url, folder: $0.folder?.name) })
    }

    public static func isSubscribed(_ url: String, context: ModelContext) throws -> Bool {
        try context.fetchCount(FetchDescriptor<Feed>(predicate: #Predicate { $0.url == url })) > 0
    }

    // MARK: Fetching

    @MainActor
    /// Returns the number of articles added to each feed that got some.
    @discardableResult
    public static func refreshAll(context: ModelContext, fetcher: FeedFetcher, now: Date = .now) async throws -> [Feed: Int] {
        let feeds = try context.fetch(FetchDescriptor<Feed>())
        let results = await fetcher.fetchAll(feeds.map(\.url))
        var added: [Feed: Int] = [:]
        var links = try knownLinks(context: context)
        for feed in feeds where !feed.isDeleted {
            switch results[feed.url] {
            case let .success(parsed):
                let count = ingest(parsed, into: feed, knownLinks: &links, context: context, now: now)
                if count > 0 { added[feed] = count }
            case let .failure(error): feed.lastError = error.localizedDescription
            case nil: break
            }
        }
        return added
    }

    /// Inserts the items not yet known for this feed. Existing articles are never touched,
    /// so read/kept/note/tags survive. Items older than the retention window are skipped.
    @discardableResult
    public static func ingest(_ parsed: ParsedFeed, into feed: Feed, context: ModelContext, now: Date = .now) -> Int {
        var links = (try? knownLinks(context: context)) ?? []
        return ingest(parsed, into: feed, knownLinks: &links, context: context, now: now)
    }

    /// `knownLinks` holds the `linkKey` of every stored article; an item whose link is already in it is a duplicate
    /// from another feed and is inserted read. Inserted links are added to it.
    @discardableResult
    static func ingest(_ parsed: ParsedFeed, into feed: Feed, knownLinks: inout Set<String>, context: ModelContext, now: Date) -> Int {
        let cutoff = Retention.cutoff(now: now)
        var known = Set((feed.articles ?? []).map(\.externalID))
        var added = 0
        for item in parsed.items {
            let date = item.publishedAt ?? now
            guard date >= cutoff, known.insert(item.externalID).inserted else { continue }
            let article = Article(externalID: item.externalID, link: item.link, title: item.title,
                                  publishedAt: date, content: item.content, sourceTitle: feed.title)
            context.insert(article)
            article.feed = feed
            article.audioURL = item.audioURL
            if let key = linkKey(item.link), !knownLinks.insert(key).inserted { article.isRead = true }
            added += 1
        }
        feed.lastError = nil
        feed.siteURLHint = parsed.siteURL
        feed.iconURLHint = parsed.iconURL
        return added
    }

    static func knownLinks(context: ModelContext) throws -> Set<String> {
        Set(try context.fetch(FetchDescriptor<Article>()).compactMap { linkKey($0.link) })
    }

    // MARK: Duplicates

    /// Identity of an article's link across feeds: scheme, `www.`, host case, trailing `/`, fragment and `utm_*`
    /// parameters ignored. Nil for an empty or host-less link, which is never a duplicate.
    public static func linkKey(_ link: String) -> String? {
        guard let parts = URLComponents(string: link.trimmingCharacters(in: .whitespacesAndNewlines)),
              var host = parts.host?.lowercased(), !host.isEmpty else { return nil }
        if host.hasPrefix("www.") { host.removeFirst(4) }
        var path = parts.percentEncodedPath
        while path.hasSuffix("/") { path.removeLast() }
        let query = (parts.percentEncodedQuery ?? "").split(separator: "&").filter { !$0.lowercased().hasPrefix("utm_") }
        return host + (parts.port.map { ":\($0)" } ?? "") + path + (query.isEmpty ? "" : "?" + query.joined(separator: "&"))
    }

    /// One article per `linkKey`, in the given order: the kept copy, else an unread one, else the first.
    public static func withoutDuplicates(_ articles: [Article]) -> [Article] {
        func rank(_ article: Article) -> Int { article.isKept ? 0 : article.isRead ? 2 : 1 }
        let keys = articles.map { linkKey($0.link) }
        var best: [String: Article] = [:]
        for (article, key) in zip(articles, keys) {
            guard let key else { continue }
            if let current = best[key], rank(current) <= rank(article) { continue }
            best[key] = article
        }
        return zip(articles, keys).filter { article, key in key.map { best[$0] === article } ?? true }.map(\.0)
    }

    // MARK: Icons

    public static let iconCheckInterval: TimeInterval = 7 * 86_400

    /// Looks up the icon of every feed never checked or checked more than `iconCheckInterval` ago.
    /// A found icon replaces the stored one; a failed lookup keeps it. Either way the check date is updated.
    @MainActor
    public static func refreshIcons(context: ModelContext, fetcher: FeedFetcher, now: Date = .now) async throws {
        let due = now.addingTimeInterval(-iconCheckInterval)
        let feeds = try context.fetch(FetchDescriptor<Feed>()).filter { ($0.iconCheckedAt ?? .distantPast) < due }
        guard !feeds.isEmpty else { return }
        let found = await fetcher.fetchIcons(feeds.map {
            IconRequest(feedURL: $0.url, siteURL: $0.siteURLHint, iconURL: $0.iconURLHint)
        })
        for feed in feeds where !feed.isDeleted {
            if let data = found[feed.url] { feed.iconData = data }
            feed.iconCheckedAt = now
        }
    }

    // MARK: Reading

    /// The first unread article after `current` in `articles`, wrapping to the top; nil when none but `current` is unread.
    public static func nextUnread(after current: PersistentIdentifier?, in articles: [Article]) -> Article? {
        let start = articles.firstIndex { $0.persistentModelID == current }.map { $0 + 1 } ?? 0
        return (articles[start...] + articles[..<start]).first { !$0.isRead && $0.persistentModelID != current }
    }

    /// Deletes non-kept articles published before the retention window, except unread ones in the read-later queue.
    public static func purge(context: ModelContext, now: Date = .now) throws {
        let cutoff = Retention.cutoff(now: now)
        let old = try context.fetch(FetchDescriptor<Article>(predicate: #Predicate { !$0.isKept && $0.publishedAt < cutoff }))
        for article in old where !article.isQueued {
            context.delete(article)
        }
    }

    /// Deletes an article whose subscription is gone. Articles of a followed feed are left alone:
    /// the next refresh would bring them back.
    public static func delete(_ article: Article, context: ModelContext) {
        guard article.feed == nil else { return }
        context.delete(article)
    }

    // MARK: Digests

    /// Articles published in the 24 hours before `now`, newest first.
    public static func digestArticles(context: ModelContext, now: Date = .now) throws -> [Article] {
        let start = now.addingTimeInterval(-86_400)
        return withoutDuplicates(try context.fetch(FetchDescriptor<Article>(
            predicate: #Predicate { $0.publishedAt > start && $0.publishedAt <= now },
            sortBy: [SortDescriptor(\.publishedAt, order: .reverse)])))
    }

    public static func digestItems(for articles: [Article]) -> [DigestItem] {
        articles.map { DigestItem(title: $0.title, source: $0.feed?.title ?? $0.sourceTitle, link: $0.link) }
    }

    /// Fits Apple's on-device model: 4,096 tokens for prompt and answer together.
    static let digestPromptBudget = 6_000
    static let digestExcerptLength = 200

    /// Instructions, then one line per article: source, title and a short excerpt while the budget allows,
    /// then source and title only, then nothing (the article still appears in the digest's list).
    public static func digestPrompt(for articles: [Article]) -> String {
        var prompt = """
        Résume en français, en Markdown, les articles ci-dessous publiés ces dernières 24 heures. \
        Regroupe les sujets proches sous de courts intertitres, reste factuel et n'invente rien.

        """
        var titlesOnly = false
        for article in articles {
            let head = "\n- [\(article.feed?.title ?? article.sourceTitle)] \(article.title)"
            let excerpt = String(plainText(readableContent(article) ?? "").prefix(digestExcerptLength))
            let full = excerpt.isEmpty ? head : head + " — " + excerpt
            if !titlesOnly, prompt.count + full.count <= digestPromptBudget {
                prompt += full
            } else if prompt.count + head.count <= digestPromptBudget {
                titlesOnly = true
                prompt += head
            } else {
                break
            }
        }
        return prompt
    }

    /// Instructions, the title, then the article's plain text cut to fit the same budget as a digest.
    public static func articleSummaryPrompt(for article: Article) -> String {
        let head = """
        Résume en français, en Markdown, l'article ci-dessous en quelques phrases ou puces. \
        Reste factuel et n'invente rien.

        Titre : \(article.title)

        """
        return head + plainText(readableContent(article) ?? "").prefix(max(0, digestPromptBudget - head.count))
    }

    static let excerptLength = 500

    /// The article's full text when it was loaded, else the feed's content: what summaries read.
    public static func readableContent(_ article: Article) -> String? {
        article.fullContent ?? article.content
    }

    /// Articles of feeds set to "Toujours charger les articles complets", published since it was turned on, whose full
    /// text was never attempted. Newest first.
    public static func articlesAwaitingFullContent(context: ModelContext) throws -> [Article] {
        try context.fetch(FetchDescriptor<Feed>()).flatMap { feed -> [Article] in
            guard let since = feed.loadsFullContentSince else { return [] }
            return (feed.articles ?? []).filter { $0.publishedAt >= since && $0.fullContentFetchedAt == nil }
        }
        .sorted { $0.publishedAt > $1.publishedAt }
    }

    /// Stores the outcome of a full-text load: the text on success; on failure only the attempt, the feed's content
    /// staying as it was.
    public static func recordFullContent(_ result: Result<ExtractedArticle, any Error>, for article: Article, now: Date = .now) {
        article.fullContentFetchedAt = now
        if case let .success(extracted) = result {
            article.fullContent = extracted.content
            article.showsFeedContent = false
        }
    }

    /// What the reading pane shows: the full text unless the user went back to the feed's content.
    public static func displayedContent(_ article: Article) -> String? {
        article.showsFeedContent ? article.content : readableContent(article)
    }

    /// Whether the article's summary was made from a short excerpt given by the feed, not from its full text.
    public static func isExcerpt(_ article: Article) -> Bool {
        if article.fullContent != nil, let loaded = article.fullContentFetchedAt, (article.summaryDate ?? .distantFuture) >= loaded {
            return false
        }
        return plainText(article.content ?? "").count < excerptLength
    }

    /// Deletes digests created more than `days` days before `now`.
    public static func purgeDigests(context: ModelContext, olderThan days: Int, now: Date = .now) throws {
        let cutoff = now.addingTimeInterval(-Double(days) * 86_400)
        for digest in try context.fetch(FetchDescriptor<Digest>(predicate: #Predicate { $0.createdAt < cutoff })) {
            context.delete(digest)
        }
    }

    // MARK: Folders

    @discardableResult
    public static func createFolder(named name: String, context: ModelContext) throws -> Folder {
        let name = try checkedName(name, among: context.fetch(FetchDescriptor<Folder>()), key: \.key,
                                   empty: .emptyFolderName, duplicate: .duplicateFolder)
        let folder = Folder(name: name)
        context.insert(folder)
        return folder
    }

    public static func rename(_ folder: Folder, to name: String, context: ModelContext) throws {
        let name = try checkedName(name, among: context.fetch(FetchDescriptor<Folder>()), key: \.key, excluding: folder,
                                   empty: .emptyFolderName, duplicate: .duplicateFolder)
        folder.name = name
        folder.key = tagKey(name)
    }

    /// The user's title replaces the feed's own for good (refreshes never set it), also on articles already received.
    public static func rename(_ feed: Feed, to name: String) throws {
        let title = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { throw CairnError.emptyFeedName }
        feed.title = title
        for article in feed.articles ?? [] { article.sourceTitle = title }
    }

    /// `nil` moves the feed back to the root.
    public static func move(_ feed: Feed, to folder: Folder?) {
        feed.folder = folder
    }

    /// Its feeds stay, at the root (nullify rule).
    public static func delete(_ folder: Folder, context: ModelContext) {
        context.delete(folder)
    }

    /// Trimmed name, rejected when blank or taken by another model (case and accents ignored).
    /// Compared in memory: there are only a handful of folders and cairns.
    private static func checkedName<T: PersistentModel>(_ name: String, among models: [T], key: KeyPath<T, String>,
                                                        excluding model: T? = nil,
                                                        empty: CairnError, duplicate: CairnError) throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let newKey = tagKey(trimmed)
        guard !newKey.isEmpty else { throw empty }
        guard !models.contains(where: { $0[keyPath: key] == newKey && $0 !== model }) else { throw duplicate }
        return trimmed
    }

    // MARK: Cairn

    /// Keeps the article in `cairn`, stamping `keptAt`; an article already kept moves there with its note,
    /// tags and `keptAt`.
    public static func keep(_ article: Article, in cairn: Cairn, now: Date = .now) {
        if !article.isKept {
            article.isKept = true
            article.keptAt = now
        }
        article.cairn = cairn
    }

    /// The note with `passage` appended as a Markdown quote, after a blank line; a blank passage leaves it unchanged.
    public static func appendQuote(_ passage: String, to note: String) -> String {
        let trimmed = passage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return note }
        let quote = trimmed.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "> " + $0.trimmingCharacters(in: .whitespaces) }.joined(separator: "\n")
        let head = note.replacing(/\s+\z/, with: "") // trailing blank lines only: the start of the note is the user's
        return head.isEmpty ? quote : head + "\n\n" + quote
    }

    /// Puts the article in the read-later queue, unread; one already queued keeps its place.
    public static func readLater(_ article: Article, now: Date = .now) {
        if !article.isQueued { article.readLaterAt = now }
        article.isRead = false
    }

    public static func removeFromReadLater(_ article: Article) {
        article.readLaterAt = nil
    }

    /// Drops the note and tags (the UI confirms first when there are some).
    public static func unkeep(_ article: Article) {
        article.isKept = false
        article.keptAt = nil
        article.cairn = nil
        article.note = ""
        article.tags = []
    }

    @discardableResult
    public static func createCairn(named name: String, context: ModelContext) throws -> Cairn {
        let name = try checkedName(name, among: context.fetch(FetchDescriptor<Cairn>()), key: \.key,
                                   empty: .emptyCairnName, duplicate: .duplicateCairn)
        let cairn = Cairn(name: name)
        context.insert(cairn)
        return cairn
    }

    public static func rename(_ cairn: Cairn, to name: String, context: ModelContext) throws {
        let name = try checkedName(name, among: context.fetch(FetchDescriptor<Cairn>()), key: \.key, excluding: cairn,
                                   empty: .emptyCairnName, duplicate: .duplicateCairn)
        cairn.name = name
        cairn.key = tagKey(name)
    }

    /// Un-keeps its articles, then deletes it. The last cairn cannot be deleted.
    public static func delete(_ cairn: Cairn, context: ModelContext) throws {
        guard try context.fetchCount(FetchDescriptor<Cairn>()) > 1 else { throw CairnError.lastCairn }
        for article in cairn.articles ?? [] { unkeep(article) }
        context.delete(cairn)
    }

    /// Makes sure a cairn exists (« Cairn » on first launch) and files every kept article without a cairn
    /// (kept before cairns existed, or synced from an older device) into the first one by name.
    @discardableResult
    public static func ensureCairn(context: ModelContext) throws -> Cairn {
        let cairn: Cairn
        if let first = try context.fetch(FetchDescriptor<Cairn>(sortBy: [SortDescriptor(\.name)])).first {
            cairn = first
        } else {
            cairn = Cairn(name: "Cairn")
            context.insert(cairn)
        }
        for article in try context.fetch(FetchDescriptor<Article>(predicate: #Predicate { $0.isKept }))
        where article.cairn == nil {
            article.cairn = cairn
        }
        return cairn
    }

    public static func tagKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// Adds a tag to the article, reusing an existing tag with the same key.
    public static func addTag(named name: String, to article: Article, context: ModelContext) throws {
        let key = tagKey(name)
        guard !key.isEmpty, !(article.tags ?? []).contains(where: { $0.key == key }) else { return }
        let tag: Tag
        if let existing = try context.fetch(FetchDescriptor<Tag>(predicate: #Predicate { $0.key == key })).first {
            tag = existing
        } else {
            tag = Tag(name: name.trimmingCharacters(in: .whitespacesAndNewlines))
            context.insert(tag)
        }
        article.tags = (article.tags ?? []) + [tag]
    }

    /// Renames the tag in every cairn. A name another tag already has merges this tag into it.
    /// Returns the tag that remains.
    @discardableResult
    public static func rename(_ tag: Tag, to name: String, context: ModelContext) throws -> Tag {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let key = tagKey(trimmed)
        guard !key.isEmpty else { throw CairnError.emptyTagName }
        guard let other = try context.fetch(FetchDescriptor<Tag>(predicate: #Predicate { $0.key == key })).first(where: { $0 !== tag }) else {
            tag.name = trimmed
            tag.key = key
            return tag
        }
        for article in tag.articles ?? [] where !(article.tags ?? []).contains(where: { $0 === other }) {
            article.tags = (article.tags ?? []) + [other]
        }
        context.delete(tag)
        return other
    }

    /// Removed from every article (nullify rule).
    public static func delete(_ tag: Tag, context: ModelContext) {
        context.delete(tag)
    }

    public static func removeTag(_ tag: Tag, from article: Article) {
        article.tags?.removeAll { $0.key == tag.key }
    }

    /// Every occurrence of the query in `text`, ignoring case and accents like `search`, for highlighting.
    public static func matchRanges(of query: String, in text: String) -> [Range<String.Index>] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return [] }
        var ranges: [Range<String.Index>] = []
        var start = text.startIndex
        while let range = text.range(of: query, options: [.caseInsensitive, .diacriticInsensitive], range: start..<text.endIndex) {
            ranges.append(range)
            start = range.upperBound
        }
        return ranges
    }

    /// Short excerpt around the query's first occurrence in the note, a tag or the content, for a search result
    /// whose title does not show the query; nil when the title shows it or nothing readable matches.
    public static func snippet(for query: String, in article: Article) -> String? {
        // Checked first: every row asks, and turning the content's HTML into text is the costly part.
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              matchRanges(of: query, in: article.title).isEmpty else { return nil }
        let sources = [article.note] + (article.tags ?? []).map(\.name) + [plainText(article.content ?? "")]
        for text in sources {
            if let range = matchRanges(of: query, in: text).first { return excerpt(text, around: range) }
        }
        return nil
    }

    /// Short excerpt around the query's first occurrence in the digest text (Markdown marks and line breaks dropped), then in an
    /// article title or source; nil when the query is empty or not found.
    public static func snippet(for query: String, in digest: Digest) -> String? {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let text = digest.text.replacing(/[*#`_]/, with: "").split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let sources = [text] + digest.items.flatMap { [$0.title, $0.source] }
        for text in sources {
            if let range = matchRanges(of: query, in: text).first { return excerpt(text, around: range) }
        }
        return nil
    }

    /// ~40 characters before and ~80 after the match, cut on a space, with "…" where text was dropped.
    static func excerpt(_ text: String, around range: Range<String.Index>) -> String {
        var lower = text.index(range.lowerBound, offsetBy: -40, limitedBy: text.startIndex) ?? text.startIndex
        var upper = text.index(range.upperBound, offsetBy: 80, limitedBy: text.endIndex) ?? text.endIndex
        if lower > text.startIndex, let space = text[lower..<range.lowerBound].firstIndex(of: " ") {
            lower = text.index(after: space)
        }
        if upper < text.endIndex, let space = text[range.upperBound..<upper].lastIndex(of: " ") { upper = space }
        return (lower > text.startIndex ? "…" : "") + text[lower..<upper] + (upper < text.endIndex ? "…" : "")
    }

    /// Feed HTML reduced to readable text: tags dropped, common entities decoded, whitespace collapsed.
    // shortcut: decodes only the usual named entities and numeric ones; a rare named entity stays as written.
    static func plainText(_ html: String) -> String {
        var text = html.replacing(/<[^>]*>/, with: " ")
        for (entity, character) in ["&nbsp;": " ", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&apos;": "'",
                                    "&eacute;": "é", "&egrave;": "è", "&agrave;": "à", "&ccedil;": "ç", "&rsquo;": "’",
                                    "&lsquo;": "‘", "&ldquo;": "“", "&rdquo;": "”", "&hellip;": "…", "&mdash;": "—"] {
            text = text.replacing(entity, with: character)
        }
        text = text.replacing(/&#(x?)([0-9a-fA-F]+);/) { match in
            UInt32(match.2, radix: match.1.isEmpty ? 10 : 16).flatMap(Unicode.Scalar.init).map { String($0) } ?? String(match.0)
        }
        text = text.replacing("&amp;", with: "&")
        return text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }

    /// Digests whose text, or an article title or source, contains the query (case and accents ignored, like articles).
    public static func search(_ query: String, in digests: [Digest]) -> [Digest] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return digests }
        return digests.filter { digest in
            digest.text.localizedStandardContains(query)
                || digest.items.contains { $0.title.localizedStandardContains(query) || $0.source.localizedStandardContains(query) }
        }
    }

    /// Case- and diacritic-insensitive search over title, content, note and tag names.
    // shortcut: linear in-memory scan over the listed articles (all received ones in "Tous les articles"), replace with
    // an index if a list grows past ~10k articles or typing lags.
    public static func search(_ query: String, in articles: [Article]) -> [Article] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return articles }
        return articles.filter { article in
            [article.title, article.content ?? "", article.note].contains { $0.localizedStandardContains(query) }
                || (article.tags ?? []).contains { $0.name.localizedStandardContains(query) }
        }
    }
}
