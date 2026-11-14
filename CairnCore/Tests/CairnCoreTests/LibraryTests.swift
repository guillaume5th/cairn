@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct SubscriptionTests {
    @Test func storeRoundTrip() throws {
        let context = try makeContext()
        context.insert(Feed(url: "https://a.test", title: "A"))
        #expect(try context.fetch(FetchDescriptor<Feed>()).map(\.title) == ["A"])
    }

    @Test func addValidFeed() async throws {
        let context = try makeContext()
        let feed = try await Library.addFeed(urlString: " https://rss.test/feed ", context: context, fetcher: stubFetcher, now: fixtureNow)
        #expect(feed.title == "Blog RSS")
        #expect(feed.url == "https://rss.test/feed")
        #expect(feed.articles?.count == 2)
        #expect(feed.unreadCount == 2)
    }

    @Test func addInvalidURL() async throws {
        let context = try makeContext()
        await #expect(throws: CairnError.invalidURL) {
            _ = try await Library.addFeed(urlString: "pas une url", context: context, fetcher: stubFetcher)
        }
        await #expect(throws: CairnError.notAFeed) {
            _ = try await Library.addFeed(urlString: "https://html.test/", context: context, fetcher: stubFetcher)
        }
        await #expect(throws: CairnError.httpStatus(500)) {
            _ = try await Library.addFeed(urlString: "https://broken.test/", context: context, fetcher: stubFetcher)
        }
        #expect(try context.fetchCount(FetchDescriptor<Feed>()) == 0)
    }

    @Test func onlyOrphanArticlesCanBeDeleted() async throws {
        let context = try makeContext()
        let feed = try await Library.addFeed(urlString: "https://rss.test/feed", context: context, fetcher: stubFetcher, now: fixtureNow)
        let article = try #require(feed.articles?.first { $0.externalID == "rss-1" })
        Library.keep(article, in: try Library.ensureCairn(context: context))

        Library.delete(article, context: context)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Article>()) == 2)

        Library.delete(feed, context: context)
        try context.save() // nullify detaches the article on save
        Library.delete(article, context: context)
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Article>()) == 0)
    }

    @Test func addDuplicate() async throws {
        let context = try makeContext()
        _ = try await Library.addFeed(urlString: "https://rss.test/feed", context: context, fetcher: stubFetcher, now: fixtureNow)
        await #expect(throws: CairnError.alreadySubscribed) {
            _ = try await Library.addFeed(urlString: "https://rss.test/feed", context: context, fetcher: stubFetcher, now: fixtureNow)
        }
        #expect(try context.fetchCount(FetchDescriptor<Feed>()) == 1)
    }

    @Test func deletingFeedKeepsKeptArticles() async throws {
        let context = try makeContext()
        let feed = try await Library.addFeed(urlString: "https://rss.test/feed", context: context, fetcher: stubFetcher, now: fixtureNow)
        let kept = try #require(feed.articles?.first { $0.externalID == "rss-1" })
        Library.keep(kept, in: try Library.ensureCairn(context: context))
        kept.note = "à relire"
        feed.iconData = pageIcon

        Library.delete(feed, context: context)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<Article>())
        #expect(remaining.map(\.externalID) == ["rss-1"])
        #expect(remaining.first?.feed == nil)
        #expect(remaining.first?.sourceTitle == "Blog RSS")
        #expect(remaining.first?.note == "à relire")
        #expect(remaining.first?.sourceIconData == pageIcon)
        #expect(try context.fetchCount(FetchDescriptor<Feed>()) == 0)
    }
}

@MainActor
struct IngestionTests {
    @Test func secondIngestionAddsNothingAndKeepsState() throws {
        let context = try makeContext()
        let parsed = try FeedParser.parse(fixture("rss.xml"))
        let feed = Feed(url: "https://rss.test/feed", title: "Blog RSS")
        context.insert(feed)

        #expect(Library.ingest(parsed, into: feed, context: context, now: fixtureNow) == 2)
        let article = try #require(feed.articles?.first { $0.externalID == "rss-1" })
        article.isRead = true
        Library.keep(article, in: try Library.ensureCairn(context: context))
        article.note = "note"
        try Library.addTag(named: "Swift", to: article, context: context)

        #expect(Library.ingest(parsed, into: feed, context: context, now: fixtureNow) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Article>()) == 2)
        #expect(article.isRead && article.isKept && article.note == "note" && article.tags?.count == 1)
    }

    @Test func undatedItemGetsFetchDate() throws {
        let context = try makeContext()
        let feed = Feed(url: "u", title: "t")
        context.insert(feed)
        Library.ingest(try FeedParser.parse(fixture("rss.xml")), into: feed, context: context, now: fixtureNow)
        #expect(feed.articles?.first { $0.externalID == "https://rss.example/2" }?.publishedAt == fixtureNow)
    }

    @Test func itemsOlderThanRetentionAreSkipped() throws {
        let context = try makeContext()
        let feed = Feed(url: "u", title: "t")
        context.insert(feed)
        let old = ParsedItem(externalID: "old", link: "", title: "", publishedAt: fixtureNow.addingTimeInterval(-31 * 86_400), content: nil)
        let recent = ParsedItem(externalID: "recent", link: "", title: "", publishedAt: fixtureNow.addingTimeInterval(-29 * 86_400), content: nil)
        Library.ingest(ParsedFeed(title: "", items: [old, recent]), into: feed, context: context, now: fixtureNow)
        #expect(feed.articles?.map(\.externalID) == ["recent"])
    }

    @Test func refreshRecordsAndClearsErrors() async throws {
        let context = try makeContext()
        let good = Feed(url: "https://rss.test/feed", title: "RSS")
        let bad = Feed(url: "https://broken.test/feed", title: "Cassé")
        context.insert(good)
        context.insert(bad)
        good.lastError = "ancienne erreur"

        try await Library.refreshAll(context: context, fetcher: stubFetcher, now: fixtureNow)

        #expect(good.lastError == nil)
        #expect(good.articles?.count == 2)
        #expect(bad.lastError != nil)
    }

    @Test func fetchBypassesLocalCache() async throws {
        // fresh.test answers only requests that ignore the local HTTP cache.
        _ = try await stubFetcher.fetch(URL(string: "https://fresh.test/feed")!)
    }
}

@MainActor
struct FolderTests {
    @Test func createRejectsBlankAndDuplicateNames() throws {
        let context = try makeContext()
        let swift = try Library.createFolder(named: "  Swift ", context: context)
        #expect(swift.name == "Swift")
        #expect(throws: CairnError.duplicateFolder) { try Library.createFolder(named: "swîft", context: context) }
        #expect(throws: CairnError.emptyFolderName) { try Library.createFolder(named: "  ", context: context) }
        #expect(try context.fetchCount(FetchDescriptor<Folder>()) == 1)
    }

    @Test func renameKeepsFeedsAndChecksOtherFolders() throws {
        let context = try makeContext()
        let swift = try Library.createFolder(named: "Swift", context: context)
        try Library.createFolder(named: "Rust", context: context)
        let feed = Feed(url: "https://a.test", title: "A")
        context.insert(feed)
        Library.move(feed, to: swift)

        try Library.rename(swift, to: "SWIFT", context: context) // its own name, other case
        #expect(throws: CairnError.duplicateFolder) { try Library.rename(swift, to: "rust", context: context) }
        try Library.rename(swift, to: "Apple", context: context)
        #expect(swift.name == "Apple" && swift.key == "apple" && feed.folder === swift)
    }

    @Test func moveAndDeleteKeepFeedsAndArticles() throws {
        let context = try makeContext()
        let a = try Library.createFolder(named: "A", context: context)
        let b = try Library.createFolder(named: "B", context: context)
        let feed = Feed(url: "https://a.test", title: "A")
        context.insert(feed)
        let article = Article(externalID: "1", link: "", title: "t", publishedAt: fixtureNow, content: nil, sourceTitle: "A")
        article.feed = feed
        context.insert(article)

        Library.move(feed, to: a)
        Library.move(feed, to: b)
        #expect(feed.folder === b && a.feeds?.isEmpty == true && b.unreadCount == 1)
        Library.move(feed, to: nil)
        #expect(feed.folder == nil)

        Library.move(feed, to: a)
        Library.delete(a, context: context)
        try context.save()
        #expect(feed.folder == nil)
        #expect(try context.fetchCount(FetchDescriptor<Feed>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<Article>()) == 1)
    }
}

@MainActor
struct MultipleCairnTests {
    private func article(_ id: String, context: ModelContext) -> Article {
        let article = Article(externalID: id, link: "", title: id, publishedAt: fixtureNow, content: nil, sourceTitle: "")
        context.insert(article)
        return article
    }

    @Test func keepInACairnAndMoveKeepsNoteTagsAndDate() throws {
        let context = try makeContext()
        let perso = try Library.createCairn(named: "Perso", context: context)
        let pro = try Library.createCairn(named: "Pro", context: context)
        let a = article("a", context: context)
        Library.keep(a, in: perso, now: fixtureNow)
        a.note = "note"
        try Library.addTag(named: "swift", to: a, context: context)

        Library.keep(a, in: pro, now: fixtureNow.addingTimeInterval(60))
        #expect(a.cairn === pro && a.isKept && a.keptAt == fixtureNow)
        #expect(a.note == "note" && a.tags?.map(\.name) == ["swift"])
        #expect(perso.articles?.isEmpty == true && pro.articles?.count == 1)

        Library.unkeep(a)
        #expect(!a.isKept && a.cairn == nil && a.note.isEmpty && a.tags?.isEmpty == true)
    }

    @Test func namesAreUniqueIgnoringCaseAndAccents() throws {
        let context = try makeContext()
        let pro = try Library.createCairn(named: " Pro ", context: context)
        #expect(pro.name == "Pro")
        #expect(throws: CairnError.duplicateCairn) { try Library.createCairn(named: "prô", context: context) }
        #expect(throws: CairnError.emptyCairnName) { try Library.createCairn(named: " ", context: context) }
        let perso = try Library.createCairn(named: "Perso", context: context)
        #expect(throws: CairnError.duplicateCairn) { try Library.rename(perso, to: "PRO", context: context) }
        try Library.rename(pro, to: "PRO", context: context)
        #expect(pro.name == "PRO")
    }

    @Test func deleteUnkeepsItsArticlesButNeverTheLastCairn() throws {
        let context = try makeContext()
        let perso = try Library.createCairn(named: "Perso", context: context)
        let pro = try Library.createCairn(named: "Pro", context: context)
        let a = article("a", context: context)
        let b = article("b", context: context)
        Library.keep(a, in: pro)
        Library.keep(b, in: perso)
        a.note = "note"

        try Library.delete(pro, context: context)
        try context.save()
        #expect(!a.isKept && a.cairn == nil && a.note.isEmpty)
        #expect(b.isKept && b.cairn === perso)
        #expect(throws: CairnError.lastCairn) { try Library.delete(perso, context: context) }
        #expect(try context.fetchCount(FetchDescriptor<Article>()) == 2)
    }

    @Test func ensureCairnFilesKeptArticlesOnce() throws {
        let context = try makeContext()
        let kept = article("kept", context: context)
        kept.isKept = true // kept before cairns existed
        kept.note = "note"
        let other = article("other", context: context)

        let cairn = try Library.ensureCairn(context: context)
        #expect(cairn.name == "Cairn" && kept.cairn === cairn && kept.note == "note" && other.cairn == nil)
        #expect(try Library.ensureCairn(context: context) === cairn)
        #expect(try context.fetchCount(FetchDescriptor<Cairn>()) == 1)
    }
}

@MainActor
struct OPMLTests {
    @Test func parseKeepsTopLevelFolders() throws {
        let feeds = try OPML.parse(fixture("folders.opml"))
        #expect(feeds == [
            OPMLFeed(title: "Swift.org", url: "https://swift.org/atom.xml", folder: "Swift"),
            OPMLFeed(title: "Deep", url: "https://deep.example/feed", folder: "Swift"),
            OPMLFeed(title: "Top level & co", url: "https://top.example/rss"),
        ])
    }

    @Test func importReusesFoldersAndLeavesFollowedFeedsInPlace() throws {
        let context = try makeContext()
        let swift = try Library.createFolder(named: "swîft", context: context)
        let followed = Feed(url: "https://top.example/rss", title: "Top")
        context.insert(followed)
        let elsewhere = try Library.createFolder(named: "Ailleurs", context: context)
        Library.move(followed, to: elsewhere)

        #expect(try Library.importOPML(fixture("folders.opml"), context: context) == (2, 1))
        let feeds = try context.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.url)]))
        #expect(feeds.map { $0.folder?.name } == ["swîft", "swîft", "Ailleurs"])
        #expect(try context.fetchCount(FetchDescriptor<Folder>()) == 2)
        #expect(swift.feeds?.count == 2)

        #expect(try Library.importOPML(fixture("folders.opml"), context: context) == (0, 3))
        #expect(followed.folder === elsewhere)
    }

    @Test func invalidFile() throws {
        #expect(throws: CairnError.invalidOPML) { try OPML.parse(fixture("invalid.opml")) }
        #expect(throws: CairnError.invalidOPML) { try OPML.parse(Data("<rss></rss>".utf8)) }
    }

    @Test func reimportAddsNothing() throws {
        let context = try makeContext()
        let data = try fixture("folders.opml")
        #expect(try Library.importOPML(data, context: context) == (3, 0))
        #expect(try Library.importOPML(data, context: context) == (0, 3))
        #expect(try context.fetchCount(FetchDescriptor<Feed>()) == 3)
    }

    @Test func exportThenImportIntoEmptyLibrary() throws {
        let source = try makeContext()
        source.insert(Feed(url: "https://a.test/feed?x=1&y=2", title: "A & \"B\" <c>"))
        source.insert(Feed(url: "https://b.test/rss", title: "Blog B"))
        source.insert(Feed(url: "https://c.test/rss", title: "C"))
        let dev = try Library.createFolder(named: "Dev & <co>", context: source)
        for feed in try source.fetch(FetchDescriptor<Feed>()) where feed.title != "C" { Library.move(feed, to: dev) }
        let exported = try Library.exportOPML(context: source)

        let target = try makeContext()
        #expect(try Library.importOPML(exported, context: target) == (3, 0))
        let feeds = try target.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.url)]))
        #expect(feeds.map(\.url) == ["https://a.test/feed?x=1&y=2", "https://b.test/rss", "https://c.test/rss"])
        #expect(feeds.map(\.title) == ["A & \"B\" <c>", "Blog B", "C"])
        #expect(feeds.map { $0.folder?.name } == ["Dev & <co>", "Dev & <co>", nil])
        #expect(try target.fetchCount(FetchDescriptor<Folder>()) == 1)
    }
}

@MainActor
struct CairnTests {
    private func article(_ id: String, daysAgo: Double, context: ModelContext) -> Article {
        let article = Article(externalID: id, link: "", title: id, publishedAt: fixtureNow.addingTimeInterval(-daysAgo * 86_400),
                              content: nil, sourceTitle: "")
        context.insert(article)
        return article
    }

    @Test func purgeRemovesOnlyOldUnkept() throws {
        let context = try makeContext()
        _ = article("old", daysAgo: 31, context: context)
        Library.keep(article("oldKept", daysAgo: 31, context: context), in: try Library.ensureCairn(context: context))
        _ = article("recent", daysAgo: 1, context: context)

        try Library.purge(context: context, now: fixtureNow)

        let ids = try context.fetch(FetchDescriptor<Article>(sortBy: [SortDescriptor(\.externalID)])).map(\.externalID)
        #expect(ids == ["oldKept", "recent"])
    }

    @Test func unkeepClearsNoteAndTags() throws {
        let context = try makeContext()
        let a = article("a", daysAgo: 1, context: context)
        Library.keep(a, in: try Library.ensureCairn(context: context), now: fixtureNow)
        #expect(a.keptAt == fixtureNow)
        a.note = "note"
        try Library.addTag(named: "swift", to: a, context: context)

        Library.unkeep(a)
        #expect(!a.isKept && a.keptAt == nil && a.note.isEmpty && a.tags?.isEmpty == true)
    }

    @Test func tagsAreCaseInsensitive() throws {
        let context = try makeContext()
        let a = article("a", daysAgo: 1, context: context)
        let b = article("b", daysAgo: 1, context: context)
        try Library.addTag(named: "Swift", to: a, context: context)
        try Library.addTag(named: " swift ", to: b, context: context)
        try Library.addTag(named: "SWIFT", to: a, context: context)

        #expect(try context.fetchCount(FetchDescriptor<CairnCore.Tag>()) == 1)
        #expect(a.tags?.count == 1)
        #expect(b.tags?.first?.name == "Swift")

        Library.removeTag(try #require(a.tags?.first), from: a)
        #expect(a.tags?.isEmpty == true)
        #expect(b.tags?.count == 1)
    }

    @Test func searchCoversNoteTagsAndIgnoresAccents() throws {
        let context = try makeContext()
        let byNote = article("Titre neutre", daysAgo: 1, context: context)
        byNote.note = "à creuser : kubernetes operators"
        let byAccent = article("Déploiement continu", daysAgo: 1, context: context)
        let byTag = article("Autre", daysAgo: 1, context: context)
        try Library.addTag(named: "Observabilité", to: byTag, context: context)
        let all = [byNote, byAccent, byTag]

        #expect(Library.search("KUBERNETES", in: all) == [byNote])
        #expect(Library.search("deploiement", in: all) == [byAccent])
        #expect(Library.search("observabilite", in: all) == [byTag])
        #expect(Library.search("  ", in: all) == all)
    }

    @Test func snippetShowsWhyAnArticleMatches() throws {
        let context = try makeContext()
        let inTitle = article("Kubernetes en production", daysAgo: 1, context: context)
        inTitle.note = "kubernetes"
        let byNote = article("Titre neutre", daysAgo: 1, context: context)
        byNote.note = "à creuser : kubernetes operators"
        let byTag = article("Autre", daysAgo: 1, context: context)
        try Library.addTag(named: "Observabilité", to: byTag, context: context)
        let byContent = article("Sans rapport", daysAgo: 1, context: context)
        byContent.content = "<p>Le <b>d&eacute;ploiement</b> continu&nbsp;&#8212; enfin.</p>"

        #expect(Library.snippet(for: "kubernetes", in: inTitle) == nil)
        #expect(Library.snippet(for: "KUBERNETES", in: byNote) == "à creuser : kubernetes operators")
        #expect(Library.snippet(for: "observabilite", in: byTag) == "Observabilité")
        #expect(Library.snippet(for: "deploiement", in: byContent) == "Le déploiement continu — enfin.")
        #expect(Library.snippet(for: "absent", in: byContent) == nil)
        #expect(Library.snippet(for: " ", in: byContent) == nil)
    }

    @Test func snippetCutsLongTextOnSpaces() throws {
        let words = (1...60).map { "mot\($0)" }.joined(separator: " ")
        let text = words.replacing("mot30 ", with: "cible ")
        let snippet = Library.excerpt(text, around: try #require(text.range(of: "cible")))
        #expect(snippet.hasPrefix("…mot"))
        #expect(snippet.hasSuffix("…"))
        #expect(snippet.contains("cible"))
        #expect(!snippet.dropFirst().dropLast().split(separator: " ").contains { !$0.hasPrefix("mot") && $0 != "cible" })
        #expect(snippet.count < 140)
        #expect(Library.matchRanges(of: "MOT1", in: "mot1 Mot10 mot2").count == 2)
    }
}

@MainActor
struct NextUnreadTests {
    private func articles(_ read: [Bool]) throws -> [Article] {
        let context = try makeContext()
        let list = read.enumerated().map { index, isRead in
            let article = Article(externalID: "\(index)", link: "", title: "\(index)", publishedAt: fixtureNow, content: nil, sourceTitle: "")
            article.isRead = isRead
            context.insert(article)
            return article
        }
        try context.save()
        return list
    }

    @Test func afterCurrentThenWrapping() throws {
        let list = try articles([false, true, true, false, true])
        #expect(Library.nextUnread(after: list[1].persistentModelID, in: list) === list[3])
        #expect(Library.nextUnread(after: list[3].persistentModelID, in: list) === list[0])
        #expect(Library.nextUnread(after: nil, in: list) === list[0])
    }

    @Test func noneLeft() throws {
        let list = try articles([true, false, true])
        #expect(Library.nextUnread(after: list[1].persistentModelID, in: list) == nil)
        #expect(Library.nextUnread(after: nil, in: try articles([true, true])) == nil)
    }
}

@MainActor
struct RenameTests {
    @Test func renameFeedAndItsArticles() throws {
        let context = try makeContext()
        let feed = Feed(url: "https://a.test", title: "Simon Willison's Weblog")
        context.insert(feed)
        let article = Article(externalID: "1", link: "", title: "A", publishedAt: fixtureNow, content: nil, sourceTitle: feed.title)
        context.insert(article)
        article.feed = feed
        try Library.rename(feed, to: "  Simon ")
        #expect(feed.title == "Simon" && article.sourceTitle == "Simon")
        #expect(throws: CairnError.emptyFeedName) { try Library.rename(feed, to: "  ") }
        #expect(feed.title == "Simon")
    }

    private func keptArticle(_ id: String, tags: [String], in context: ModelContext) throws -> Article {
        let article = Article(externalID: id, link: "", title: id, publishedAt: fixtureNow, content: nil, sourceTitle: "")
        context.insert(article)
        for name in tags { try Library.addTag(named: name, to: article, context: context) }
        return article
    }

    @Test func renameTag() throws {
        let context = try makeContext()
        let article = try keptArticle("1", tags: ["swfit"], in: context)
        let tag = try #require(article.tags?.first)
        let kept = try Library.rename(tag, to: "swift", context: context)
        #expect(kept === tag && article.tags?.map(\.name) == ["swift"] && tag.key == "swift")
        #expect(throws: CairnError.emptyTagName) { try Library.rename(tag, to: " ", context: context) }
    }

    @Test func renameMergesIntoExistingTag() throws {
        let context = try makeContext()
        let a = try keptArticle("a", tags: ["IA"], in: context)
        let b = try keptArticle("b", tags: ["intelligence artificielle"], in: context)
        let c = try keptArticle("c", tags: ["IA", "intelligence artificielle"], in: context)
        try context.save()
        let long = try #require(b.tags?.first)
        let kept = try Library.rename(long, to: "ia", context: context)
        try context.save()
        #expect(kept.name == "IA")
        for article in [a, b, c] { #expect(article.tags?.map(\.name) == ["IA"]) }
        #expect(try context.fetchCount(FetchDescriptor<CairnCore.Tag>()) == 1)
    }

    @Test func deleteTag() throws {
        let context = try makeContext()
        let a = try keptArticle("a", tags: ["brouillon", "swift"], in: context)
        try context.save()
        Library.delete(try #require(a.tags?.first { $0.name == "brouillon" }), context: context)
        try context.save()
        #expect(a.tags?.map(\.name) == ["swift"])
    }
}

struct RetentionTests {
    // A suite of its own: the shared defaults would change the cutoff of tests running in parallel.
    @Test func daysFollowTheSetting() throws {
        let defaults = try #require(UserDefaults(suiteName: "RetentionTests"))
        defaults.removePersistentDomain(forName: "RetentionTests")
        #expect(Retention.days(in: defaults) == 30)
        defaults.set(90, forKey: Retention.key)
        #expect(Retention.days(in: defaults) == 90)
        defaults.removePersistentDomain(forName: "RetentionTests")
    }
}
