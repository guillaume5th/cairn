@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct DuplicateTests {
    @Test func linkKeyIgnoresNoise() {
        let key = Library.linkKey("https://exemple.fr/post")
        #expect(key == "exemple.fr/post")
        for variant in ["http://www.exemple.fr/post/", "https://EXEMPLE.fr/post#top", "https://exemple.fr/post?utm_source=rss&utm_medium=x"] {
            #expect(Library.linkKey(variant) == key)
        }
        #expect(Library.linkKey("https://exemple.fr/post?id=2&utm_source=rss") == "exemple.fr/post?id=2")
        #expect(Library.linkKey("https://exemple.fr/autre") != key)
        #expect(Library.linkKey("") == nil)
        #expect(Library.linkKey("pas un lien") == nil)
    }

    private func item(_ id: String, _ link: String) -> ParsedItem {
        ParsedItem(externalID: id, link: link, title: id, publishedAt: fixtureNow, content: nil)
    }

    private func feed(_ title: String, _ context: ModelContext) -> Feed {
        let feed = Feed(url: "https://\(title).test/feed", title: title)
        context.insert(feed)
        return feed
    }

    @Test func duplicateFromAnotherFeedIsRead() throws {
        let context = try makeContext()
        let blog = feed("blog", context), aggregator = feed("agg", context)
        Library.ingest(ParsedFeed(title: "", items: [item("b1", "https://exemple.fr/post")]), into: blog, context: context, now: fixtureNow)
        Library.ingest(ParsedFeed(title: "", items: [item("a1", "http://www.exemple.fr/post/?utm_source=rss"), item("a2", "https://exemple.fr/neuf")]),
                       into: aggregator, context: context, now: fixtureNow)
        let copies = aggregator.articles ?? []
        #expect(copies.first { $0.externalID == "a1" }?.isRead == true)
        #expect(copies.first { $0.externalID == "a2" }?.isRead == false)
        #expect(blog.articles?.first?.isRead == false)
    }

    @Test func duplicatesInTheSameRefreshAndLinklessItems() throws {
        let context = try makeContext()
        let one = feed("un", context), two = feed("deux", context)
        var links = try Library.knownLinks(context: context)
        let items = [item("x", "https://exemple.fr/x"), item("vide", "")]
        Library.ingest(ParsedFeed(title: "", items: items), into: one, knownLinks: &links, context: context, now: fixtureNow)
        Library.ingest(ParsedFeed(title: "", items: items), into: two, knownLinks: &links, context: context, now: fixtureNow)
        #expect((one.articles ?? []).allSatisfy { !$0.isRead })
        #expect(two.articles?.first { $0.externalID == "x" }?.isRead == true)
        #expect(two.articles?.first { $0.externalID == "vide" }?.isRead == false)
    }

    private func article(_ id: String, _ link: String, read: Bool = false, context: ModelContext) -> Article {
        let article = Article(externalID: id, link: link, title: id, publishedAt: fixtureNow, content: nil, sourceTitle: "")
        article.isRead = read
        context.insert(article)
        return article
    }

    @Test func withoutDuplicatesPrefersKeptThenUnreadThenFirst() throws {
        let context = try makeContext()
        let a1 = article("a1", "https://a.test/1", read: true, context: context)
        let a2 = article("a2", "https://www.a.test/1", read: true, context: context)
        let b1 = article("b1", "https://a.test/2", read: true, context: context)
        let b2 = article("b2", "https://a.test/2", context: context)
        let c1 = article("c1", "https://a.test/3", context: context)
        let c2 = article("c2", "https://a.test/3", context: context)
        Library.keep(c2, in: try Library.ensureCairn(context: context))
        let none1 = article("n1", "", context: context), none2 = article("n2", "", context: context)
        let result = Library.withoutDuplicates([a1, a2, b1, b2, c1, c2, none1, none2]).map(\.externalID)
        #expect(result == ["a1", "b2", "c2", "n1", "n2"])
    }
}
