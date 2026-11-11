import Foundation
import SwiftData

public enum Retention {
    public static let days = 30

    public static func cutoff(now: Date = .now) -> Date {
        now.addingTimeInterval(-Double(days) * 86_400)
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

    /// Creates a feed for each OPML entry not already followed. Feeds get their articles on the next refresh.
    public static func importOPML(_ data: Data, context: ModelContext) throws -> (added: Int, skipped: Int) {
        let entries = try OPML.parse(data)
        var known = Set(try context.fetch(FetchDescriptor<Feed>()).map(\.url))
        var added = 0
        for entry in entries where known.insert(entry.url).inserted {
            context.insert(Feed(url: entry.url, title: entry.title))
            added += 1
        }
        return (added, entries.count - added)
    }

    public static func exportOPML(context: ModelContext) throws -> Data {
        let feeds = try context.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.title)]))
        return OPML.export(feeds.map { OPMLFeed(title: $0.title, url: $0.url) })
    }

    private static func isSubscribed(_ url: String, context: ModelContext) throws -> Bool {
        try context.fetchCount(FetchDescriptor<Feed>(predicate: #Predicate { $0.url == url })) > 0
    }

    // MARK: Fetching

    @MainActor
    public static func refreshAll(context: ModelContext, fetcher: FeedFetcher, now: Date = .now) async throws {
        let feeds = try context.fetch(FetchDescriptor<Feed>())
        let results = await fetcher.fetchAll(feeds.map(\.url))
        for feed in feeds where !feed.isDeleted {
            switch results[feed.url] {
            case let .success(parsed): ingest(parsed, into: feed, context: context, now: now)
            case let .failure(error): feed.lastError = error.localizedDescription
            case nil: break
            }
        }
    }

    /// Inserts the items not yet known for this feed. Existing articles are never touched,
    /// so read/kept/note/tags survive. Items older than the retention window are skipped.
    @discardableResult
    public static func ingest(_ parsed: ParsedFeed, into feed: Feed, context: ModelContext, now: Date = .now) -> Int {
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
            added += 1
        }
        feed.lastError = nil
        feed.siteURLHint = parsed.siteURL
        feed.iconURLHint = parsed.iconURL
        return added
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

    /// Deletes non-kept articles published before the retention window.
    public static func purge(context: ModelContext, now: Date = .now) throws {
        let cutoff = Retention.cutoff(now: now)
        let old = try context.fetch(FetchDescriptor<Article>(predicate: #Predicate { !$0.isKept && $0.publishedAt < cutoff }))
        for article in old {
            context.delete(article)
        }
    }

    /// Deletes an article whose subscription is gone. Articles of a followed feed are left alone:
    /// the next refresh would bring them back.
    public static func delete(_ article: Article, context: ModelContext) {
        guard article.feed == nil else { return }
        context.delete(article)
    }

    // MARK: Cairn

    /// Keeping stamps `keptAt`; un-keeping drops the note and tags (the UI confirms first when there is a note).
    public static func setKept(_ kept: Bool, _ article: Article, now: Date = .now) {
        article.isKept = kept
        article.keptAt = kept ? now : nil
        if !kept {
            article.note = ""
            article.tags = []
        }
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

    public static func removeTag(_ tag: Tag, from article: Article) {
        article.tags?.removeAll { $0.key == tag.key }
    }

    /// Case- and diacritic-insensitive search over title, content, note and tag names.
    // shortcut: linear in-memory scan, replace with an index if the cairn grows past ~10k articles or typing lags.
    public static func search(_ query: String, in articles: [Article]) -> [Article] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return articles }
        return articles.filter { article in
            [article.title, article.content ?? "", article.note].contains { $0.localizedStandardContains(query) }
                || (article.tags ?? []).contains { $0.name.localizedStandardContains(query) }
        }
    }
}
