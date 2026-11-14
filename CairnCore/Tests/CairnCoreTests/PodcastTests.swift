@testable import CairnCore
import Foundation
import SwiftData
import Testing

struct PodcastParsingTests {
    private func items(_ xml: String) throws -> [ParsedItem] { try FeedParser.parse(Data(xml.utf8)).items }

    @Test func rssEnclosures() throws {
        let parsed = try items("""
        <?xml version="1.0"?><rss version="2.0"><channel><title>Podcast</title>
        <item><guid>e1</guid><title>Typé</title><enclosure url="https://p.test/e1.mp3" type="audio/mpeg" length="1"/></item>
        <item><guid>e2</guid><title>Sans type</title><enclosure url="https://p.test/e2.M4A?x=1"/></item>
        <item><guid>e3</guid><title>Vidéo</title><enclosure url="https://p.test/e3.mp4" type="video/mp4"/></item>
        <item><title>Sans id ni lien</title><enclosure url="https://p.test/e4.mp3" type="audio/mpeg"/></item>
        </channel></rss>
        """)
        #expect(parsed.map(\.audioURL) == ["https://p.test/e1.mp3", "https://p.test/e2.M4A?x=1", nil, "https://p.test/e4.mp3"])
        #expect(parsed[3].externalID == "https://p.test/e4.mp3")
    }

    @Test func atomEnclosure() throws {
        let parsed = try items("""
        <?xml version="1.0"?><feed xmlns="http://www.w3.org/2005/Atom"><title>Podcast</title>
        <entry><id>a1</id><title>Épisode</title><link href="https://p.test/a1"/>
        <link rel="enclosure" href="https://p.test/a1.ogg" type="audio/ogg"/></entry>
        </feed>
        """)
        #expect(parsed.first?.audioURL == "https://p.test/a1.ogg")
        #expect(parsed.first?.link == "https://p.test/a1")
    }

    @Test func jsonAttachment() throws {
        let parsed = try items("""
        {"version": "https://jsonfeed.org/version/1.1", "title": "Podcast", "items": [
          {"id": "j1", "title": "Épisode", "attachments": [{"url": "https://p.test/j1.mp3", "mime_type": "audio/mpeg"}]}]}
        """)
        #expect(parsed.first?.audioURL == "https://p.test/j1.mp3")
    }
}

@MainActor
struct PodcastLibraryTests {
    @Test func ingestKeepsTheAudio() throws {
        let context = try makeContext()
        let feed = Feed(url: "https://p.test/feed", title: "Podcast")
        context.insert(feed)
        let item = ParsedItem(externalID: "e1", link: "", title: "Épisode", publishedAt: fixtureNow, content: nil,
                              audioURL: "https://p.test/e1.mp3")
        Library.ingest(ParsedFeed(title: "Podcast", items: [item]), into: feed, context: context, now: fixtureNow)
        #expect(feed.articles?.first?.audioURL == "https://p.test/e1.mp3")

        let backup = try Backup.decode(try Library.makeBackup(context: context, settings: [:]).encoded())
        let target = try makeContext()
        try Library.restore(backup, context: target)
        #expect(try target.fetch(FetchDescriptor<Article>()).first?.audioURL == "https://p.test/e1.mp3")
    }
}
