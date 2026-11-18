@testable import CairnCore
import Foundation
import Testing

struct NormalizedURLTests {
    @Test func domainAloneGetsHTTPS() throws {
        #expect(try Library.normalizedURL(" exemple.com ").absoluteString == "https://exemple.com")
    }

    @Test func domainAndPathGetHTTPS() throws {
        #expect(try Library.normalizedURL("exemple.com/blog").absoluteString == "https://exemple.com/blog")
    }

    @Test func fullURLUnchanged() throws {
        #expect(try Library.normalizedURL("http://exemple.com/feed.xml").absoluteString == "http://exemple.com/feed.xml")
    }

    @Test func otherSchemesAndNonsenseRejected() {
        #expect(throws: CairnError.invalidURL) { try Library.normalizedURL("ftp://exemple.com") }
        #expect(throws: CairnError.invalidURL) { try Library.normalizedURL("pas une url") }
        #expect(throws: CairnError.invalidURL) { try Library.normalizedURL("") }
    }
}

struct FeedDiscoveryTests {
    func discover(_ input: String) async throws -> [DiscoveredFeed] {
        try await Library.discoverFeeds(urlString: input, fetcher: stubFetcher)
    }

    @Test func feedAddressIsTheFeed() async throws {
        let feeds = try await discover("https://rss.test/feed")
        #expect(feeds.map(\.url) == ["https://rss.test/feed"])
        #expect(feeds.first?.title?.isEmpty == false)
    }

    @Test func pageDeclaringOneFeed() async throws {
        #expect(try await discover("blog.test") == [DiscoveredFeed(url: "https://blog.test/atom", title: "Blog")])
    }

    @Test func pageDeclaringSeveralFeedsKeepsOrderWithoutDuplicates() async throws {
        #expect(try await discover("https://multi.test/").map(\.url) == ["https://multi.test/feed", "https://multi.test/comments/feed"])
    }

    @Test func jsonFeedWithRelativeHref() async throws {
        #expect(try await discover("https://json.test/").map(\.url) == ["https://json.test/feed.json"])
    }

    @Test func firstUsualPathInOrder() async throws {
        #expect(try await discover("usual.test").map(\.url) == ["https://usual.test/rss.xml"])
    }

    @Test func noFeedAnywhere() async {
        await #expect(throws: CairnError.noFeedFound) { try await discover("https://nofeed.test/") }
    }

    @Test func unreachableSiteIsAnHTTPError() async {
        await #expect(throws: CairnError.httpStatus(500)) { try await discover("https://broken.test/") }
    }

    @Test func declaredFeedsFoundAfterHeadClose() {
        let html = #"<html><head></head><body><link rel="alternate" type="application/rss+xml" href="https://s.test/f.xml"></body></html>"#
        #expect(Library.declaredFeeds(inHTML: html, baseURL: URL(string: "https://s.test/")!).map(\.url) == ["https://s.test/f.xml"])
    }

    @Test func declaredFeedsIgnoreNonFeedAlternates() {
        let html = #"<link rel="alternate" type="text/html" href="/fr/"><link rel="alternate" href="/x"><link rel="feed" type="application/rss+xml" href="/f">"#
        #expect(Library.declaredFeeds(inHTML: html, baseURL: URL(string: "https://s.test/")!).isEmpty)
    }
}

struct HTMLEntityTests {
    @Test func namedAndNumericEntities() {
        #expect(HTMLHead.decode("News &raquo; Feed &#8211; &#x2014; &amp; &inconnu;") == "News » Feed – — & &inconnu;")
    }

    @Test func plainJSONIsNotAFeed() {
        let html = #"<link rel="alternate" type="application/json" href="/wp-json/wp/v2/pages/1">"#
        #expect(Library.declaredFeeds(inHTML: html, baseURL: URL(string: "https://s.test/")!).isEmpty)
    }
}
