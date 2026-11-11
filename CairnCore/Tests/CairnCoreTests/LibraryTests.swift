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
        Library.setKept(true, article)

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
        Library.setKept(true, kept)
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
        Library.setKept(true, article)
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
struct OPMLTests {
    @Test func parseFlattensFolders() throws {
        let feeds = try OPML.parse(fixture("folders.opml"))
        #expect(feeds == [
            OPMLFeed(title: "Swift.org", url: "https://swift.org/atom.xml"),
            OPMLFeed(title: "Deep", url: "https://deep.example/feed"),
            OPMLFeed(title: "Top level & co", url: "https://top.example/rss"),
        ])
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
        let exported = try Library.exportOPML(context: source)

        let target = try makeContext()
        #expect(try Library.importOPML(exported, context: target) == (2, 0))
        let feeds = try target.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.url)]))
        #expect(feeds.map(\.url) == ["https://a.test/feed?x=1&y=2", "https://b.test/rss"])
        #expect(feeds.map(\.title) == ["A & \"B\" <c>", "Blog B"])
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
        Library.setKept(true, article("oldKept", daysAgo: 31, context: context))
        _ = article("recent", daysAgo: 1, context: context)

        try Library.purge(context: context, now: fixtureNow)

        let ids = try context.fetch(FetchDescriptor<Article>(sortBy: [SortDescriptor(\.externalID)])).map(\.externalID)
        #expect(ids == ["oldKept", "recent"])
    }

    @Test func unkeepClearsNoteAndTags() throws {
        let context = try makeContext()
        let a = article("a", daysAgo: 1, context: context)
        Library.setKept(true, a, now: fixtureNow)
        #expect(a.keptAt == fixtureNow)
        a.note = "note"
        try Library.addTag(named: "swift", to: a, context: context)

        Library.setKept(false, a)
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
}
