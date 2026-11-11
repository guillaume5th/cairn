@testable import CairnCore
import Foundation
import Testing

struct FeedParserTests {
    @Test func rss() throws {
        let feed = try FeedParser.parse(fixture("rss.xml"))
        #expect(feed.title == "Blog RSS")
        #expect(feed.items.count == 2)
        #expect(feed.siteURL == "https://rss.example/")
        #expect(feed.iconURL == nil, "RSS declares no icon (<image> is a logo)")

        let first = feed.items[0]
        #expect(first.externalID == "rss-1")
        #expect(first.link == "https://rss.example/1")
        #expect(first.publishedAt != nil)
        #expect(first.content == "<p>Contenu <b>complet</b></p>", "content:encoded wins over description")

        let second = feed.items[1]
        #expect(second.externalID == "https://rss.example/2", "no guid falls back to link")
        #expect(second.publishedAt == nil)
        #expect(second.content == "Seulement un résumé")
    }

    @Test func atom() throws {
        let feed = try FeedParser.parse(fixture("atom.xml"))
        #expect(feed.title == "Blog Atom")
        #expect(feed.siteURL == "https://atom.example/", "alternate link, not self")
        #expect(feed.iconURL == "https://atom.example/icon.png", "icon, not logo")
        let entry = try #require(feed.items.first)
        #expect(entry.externalID == "urn:atom-1")
        #expect(entry.link == "https://atom.example/1", "alternate link, not self")
        #expect(entry.publishedAt != nil, "falls back to updated")
        #expect(entry.content == "<p>Contenu Atom</p>")
    }

    @Test func jsonFeed() throws {
        let feed = try FeedParser.parse(fixture("feed.json"))
        #expect(feed.title == "Blog JSON")
        #expect(feed.siteURL == "https://json.example/")
        #expect(feed.iconURL == "https://json.example/favicon.png", "favicon wins over the larger icon")
        #expect(feed.items == [ParsedItem(externalID: "json-1", link: "https://json.example/1", title: "Article JSON",
                                          publishedAt: ISO8601DateFormatter().date(from: "2026-11-09T10:00:00Z"),
                                          content: "<p>Contenu JSON</p>")])
    }

    @Test func notAFeed() {
        #expect(throws: CairnError.notAFeed) { try FeedParser.parse(Data("<html></html>".utf8)) }
    }
}

struct FeedFetcherTests {
    @Test func oneFailingFeedDoesNotBlockOthers() async throws {
        let results = await stubFetcher.fetchAll(["https://rss.test/feed", "https://broken.test/feed", "https://atom.test/feed"])
        #expect(try results["https://rss.test/feed"]?.get().title == "Blog RSS")
        #expect(try results["https://atom.test/feed"]?.get().title == "Blog Atom")
        #expect(throws: CairnError.httpStatus(500)) { try results["https://broken.test/feed"]?.get() }
    }
}
