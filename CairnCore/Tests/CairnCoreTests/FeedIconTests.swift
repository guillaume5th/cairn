@testable import CairnCore
import AppKit
import Foundation
import SwiftData
import Testing

struct DeclaredIconTests {
    let base = URL(string: "https://site.test/blog/")!

    func icons(_ html: String) -> [String] {
        FeedIcon.declaredIcons(inHTML: html, baseURL: base).map(\.absoluteString)
    }

    @Test func relIcon() {
        #expect(icons(#"<head><link rel="icon" href="/favicon.png"></head>"#) == ["https://site.test/favicon.png"])
    }

    @Test func shortcutIconWithAttributesReorderedAndUppercase() {
        #expect(icons(#"<HEAD><LINK HREF='img/fav.ico' type="image/x-icon" REL="Shortcut Icon"/></HEAD>"#)
            == ["https://site.test/blog/img/fav.ico"])
    }

    @Test func absoluteAndUnquotedHref() {
        #expect(icons(#"<link rel=icon href=https://cdn.test/i.png>"#) == ["https://cdn.test/i.png"])
    }

    @Test func documentOrderAndOtherRelsIgnored() {
        let html = """
        <head>
          <link rel="stylesheet" href="/s.css">
          <link rel="mask-icon" href="/mask.svg">
          <link rel="apple-touch-icon" href="/touch.png?a=1&amp;b=2">
          <link rel="icon" href="/fav.svg">
        </head>
        <body><link rel="icon" href="/body.png"></body>
        """
        #expect(icons(html) == ["https://site.test/touch.png?a=1&b=2", "https://site.test/fav.svg"])
    }

    @Test func appleTouchIconThenLargestSizeFirst() {
        let html = """
        <link rel="icon" href="/plain.ico">
        <link rel="icon" sizes="16x16" href="/16.png">
        <link rel="icon" sizes="32x32 192x192" href="/192.png">
        <link rel="apple-touch-icon" href="/touch.png">
        <link rel="icon" sizes="any" href="/vector.svg">
        """
        #expect(icons(html) == ["https://site.test/touch.png", "https://site.test/vector.svg", "https://site.test/192.png",
                                "https://site.test/16.png", "https://site.test/plain.ico"])
    }

    @Test func pageWithoutIcon() {
        #expect(icons("<html><head><title>Rien</title></head><body></body></html>").isEmpty)
    }
}

struct IconLookupTests {
    func icon(_ feed: String, site: String? = nil, icon: String? = nil) async -> Data? {
        await stubFetcher.fetchIcon(IconRequest(feedURL: feed, siteURL: site, iconURL: icon))
    }

    @Test func iconDeclaredByFeedComesFirst() async {
        #expect(await icon("https://atom.test/feed", site: "https://rss.example/", icon: "https://atom.example/icon.png") == declaredIcon)
    }

    @Test func iconDeclaredByHomePage() async {
        #expect(await icon("https://rss.test/feed", site: "https://rss.example/") == pageIcon)
    }

    @Test func conventionalFaviconAtFeedOrigin() async {
        #expect(await icon("https://ico.test/feed.xml") == conventionalIcon, "no site URL: the feed origin is used")
    }

    @Test func conventionalAppleTouchIconBeforeFavicon() async {
        #expect(await icon("https://touch.test/feed") == pageIcon)
    }

    @Test func nearTransparentIconFallsThrough() async {
        #expect(await icon("https://ghost.test/feed") == pageIcon)
    }

    @Test func unreadableIconFallsThrough() async {
        #expect(await icon("https://bad.test/feed", icon: "https://bad.test/broken.png") == conventionalIcon)
    }

    @Test func oversizedIconIsRejected() async {
        #expect(NSImage(data: oversizedIcon)?.isValid == true, "the size limit, not decoding, must reject it")
        #expect(await icon("https://big.test/feed") == nil)
    }

    @Test func noIconAnywhere() async {
        #expect(await icon("https://none.test/feed") == nil)
    }

    @Test func fetchIconsKeysByFeedAndOmitsMisses() async {
        let found = await stubFetcher.fetchIcons([IconRequest(feedURL: "https://ico.test/f"), IconRequest(feedURL: "https://none.test/f")])
        #expect(found == ["https://ico.test/f": conventionalIcon])
    }
}

@MainActor
struct IconRefreshTests {
    let day: TimeInterval = 86_400

    @Test func iconFromFeedDeclaredSiteIsStored() async throws {
        let context = try makeContext()
        let feed = try await Library.addFeed(urlString: "https://rss.test/feed", context: context, fetcher: stubFetcher, now: fixtureNow)

        try await Library.refreshIcons(context: context, fetcher: stubFetcher, now: fixtureNow)

        #expect(feed.iconData == pageIcon, "site URL declared by the feed (rss.example) is used")
        #expect(feed.iconCheckedAt == fixtureNow)
    }

    @Test func secondRunSameDayMakesNoRequest() async throws {
        let context = try makeContext()
        let feed = Feed(url: "https://count.test/feed", title: "Count")
        context.insert(feed)
        func countRequests() -> Int { StubProtocol.requests.withLock { $0.count { $0.host() == "count.test" } } }

        try await Library.refreshIcons(context: context, fetcher: stubFetcher, now: fixtureNow)
        let afterFirst = countRequests()
        try await Library.refreshIcons(context: context, fetcher: stubFetcher, now: fixtureNow.addingTimeInterval(6 * 3600))

        #expect(feed.iconData == conventionalIcon)
        #expect(afterFirst > 0)
        #expect(countRequests() == afterFirst)
    }

    @Test func failedLookupKeepsStoredIcon() async throws {
        let context = try makeContext()
        let feed = Feed(url: "https://none.test/feed", title: "None")
        feed.iconData = declaredIcon
        feed.iconCheckedAt = fixtureNow.addingTimeInterval(-8 * day)
        context.insert(feed)

        try await Library.refreshIcons(context: context, fetcher: stubFetcher, now: fixtureNow)

        #expect(feed.iconData == declaredIcon)
        #expect(feed.iconCheckedAt == fixtureNow)
    }

    @Test func onlyFeedsCheckedOverSevenDaysAgoAreRechecked() async throws {
        let context = try makeContext()
        let stale = Feed(url: "https://ico.test/stale", title: "Stale")
        stale.iconCheckedAt = fixtureNow.addingTimeInterval(-8 * day)
        let recent = Feed(url: "https://ico.test/recent", title: "Recent")
        recent.iconCheckedAt = fixtureNow.addingTimeInterval(-6 * day)
        context.insert(stale)
        context.insert(recent)

        try await Library.refreshIcons(context: context, fetcher: stubFetcher, now: fixtureNow)

        #expect(stale.iconData == conventionalIcon)
        #expect(stale.iconCheckedAt == fixtureNow)
        #expect(recent.iconData == nil)
        #expect(recent.iconCheckedAt == fixtureNow.addingTimeInterval(-6 * day))
    }
}
