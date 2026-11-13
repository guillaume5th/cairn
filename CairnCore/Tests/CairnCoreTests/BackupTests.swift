@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct BackupTests {
    /// A feed in a folder with full content on, a kept article with note, tag, summary and full text, an unkept one,
    /// and a kept article whose feed is gone.
    private func populated() throws -> ModelContext {
        let context = try makeContext()
        let folder = try Library.createFolder(named: "Tech", context: context)
        let feed = Feed(url: "https://rss.test/feed", title: "Blog RSS")
        context.insert(feed)
        feed.folder = folder
        feed.loadsFullContentSince = fixtureNow
        feed.iconData = Data([1, 2, 3])
        feed.iconCheckedAt = fixtureNow
        let reading = try Library.createCairn(named: "Lectures", context: context)
        let kept = Article(externalID: "a1", link: "https://rss.test/a1", title: "Gardé", publishedAt: fixtureNow,
                           content: "<p>Texte</p>", sourceTitle: "Blog RSS")
        context.insert(kept)
        kept.feed = feed
        kept.isRead = true
        Library.keep(kept, in: reading, now: fixtureNow)
        kept.note = "À relire"
        try Library.addTag(named: "swift", to: kept, context: context)
        kept.summary = "Résumé"
        kept.summaryDate = fixtureNow
        kept.summaryEngine = "Ollama"
        kept.fullContent = "<p>Texte complet</p>"
        kept.fullContentFetchedAt = fixtureNow
        let unkept = Article(externalID: "a2", link: "https://rss.test/a2", title: "Pas gardé", publishedAt: fixtureNow,
                             content: nil, sourceTitle: "Blog RSS")
        context.insert(unkept)
        unkept.feed = feed
        unkept.isRead = true
        let unread = Article(externalID: "a3", link: "https://rss.test/a3", title: "Non lu", publishedAt: fixtureNow,
                             content: "<p>Neuf</p>", sourceTitle: "Blog RSS")
        context.insert(unread)
        unread.feed = feed
        let orphan = Article(externalID: "o1", link: "https://gone.test/o1", title: "Orphelin", publishedAt: fixtureNow,
                             content: nil, sourceTitle: "Disparu")
        context.insert(orphan)
        Library.keep(orphan, in: reading, now: fixtureNow)
        try Library.ensureCairn(context: context)
        try context.save()
        return context
    }

    @Test func roundTrip() throws {
        let source = try populated()
        let settings: [String: Backup.SettingValue] = ["articleTextScale": .double(1.2), "showListIcons": .bool(false),
                                                       "digestTime": .int(480), "ollamaModel": .string("llama3.2")]
        let data = try Library.makeBackup(context: source, settings: settings, now: fixtureNow).encoded()
        let backup = try Backup.decode(data)
        #expect(backup.settings == settings)
        #expect(backup.articles.map(\.externalID).sorted() == ["a1", "a2", "a3", "o1"])

        let target = try makeContext()
        try Library.restore(backup, context: target)
        try target.save()
        let feed = try #require(try target.fetch(FetchDescriptor<Feed>()).first)
        #expect(feed.url == "https://rss.test/feed")
        #expect(feed.folder?.name == "Tech")
        #expect(feed.loadsFullContentSince == fixtureNow)
        #expect(feed.iconData == Data([1, 2, 3]) && feed.iconCheckedAt == fixtureNow)
        #expect(Set(try target.fetch(FetchDescriptor<Cairn>()).map(\.name)) == ["Lectures"])
        let articles = try target.fetch(FetchDescriptor<Article>())
        let kept = try #require(articles.first { $0.externalID == "a1" })
        #expect(kept.isKept && kept.isRead && kept.feed === feed)
        #expect(kept.cairn?.name == "Lectures")
        #expect(kept.note == "À relire")
        #expect(kept.tags?.map(\.name) == ["swift"])
        #expect(kept.summary == "Résumé" && kept.summaryEngine == "Ollama")
        #expect(kept.fullContent == "<p>Texte complet</p>")
        let orphan = try #require(articles.first { $0.externalID == "o1" })
        #expect(orphan.feed == nil && orphan.isKept)
        let read = try #require(articles.first { $0.externalID == "a2" })
        #expect(read.isRead && !read.isKept && read.cairn == nil && read.feed === feed)
        let unread = try #require(articles.first { $0.externalID == "a3" })
        #expect(!unread.isRead && !unread.isKept && unread.content == "<p>Neuf</p>")
    }

    @Test func restoreReplacesExistingData() throws {
        let backup = try Library.makeBackup(context: try populated(), settings: [:])
        let target = try makeContext()
        target.insert(Feed(url: "https://other.test/feed", title: "Autre"))
        try Library.createFolder(named: "Ancien", context: target)
        try Library.createCairn(named: "Vieux", context: target)
        try target.save()
        try Library.restore(backup, context: target)
        try target.save()
        #expect(try target.fetch(FetchDescriptor<Feed>()).map(\.url) == ["https://rss.test/feed"])
        #expect(try target.fetch(FetchDescriptor<Folder>()).map(\.name) == ["Tech"])
        #expect(!(try target.fetch(FetchDescriptor<Cairn>()).map(\.name)).contains("Vieux"))
    }

    @Test func restoreKeepsDigests() throws {
        let backup = try Library.makeBackup(context: try populated(), settings: [:])
        let target = try makeContext()
        target.insert(Digest(createdAt: fixtureNow, text: "Résumé du jour", items: [], engine: "Test"))
        try target.save()
        try Library.restore(backup, context: target)
        #expect(try target.fetchCount(FetchDescriptor<Digest>()) == 1)
    }

    @Test func unreadableFiles() throws {
        #expect(throws: CairnError.invalidBackup) { try Backup.decode(Data("pas du json".utf8)) }
        #expect(throws: CairnError.invalidBackup) { try Backup.decode(Data(#"{"feeds": []}"#.utf8)) }
        var future = try Library.makeBackup(context: try makeContext(), settings: [:])
        future.version = Backup.currentVersion + 1
        #expect(throws: CairnError.unsupportedBackup) { try Backup.decode(try future.encoded()) }
    }

    @Test func restoredArticlesAreNotDuplicatedByRefresh() throws {
        let backup = try Library.makeBackup(context: try populated(), settings: [:])
        let target = try makeContext()
        try Library.restore(backup, context: target)
        let feed = try #require(try target.fetch(FetchDescriptor<Feed>()).first)
        let parsed = ParsedFeed(title: "Blog RSS", items: [
            ParsedItem(externalID: "a1", link: "https://rss.test/a1", title: "Gardé", publishedAt: fixtureNow, content: nil),
            ParsedItem(externalID: "a2", link: "https://rss.test/a2", title: "Pas gardé", publishedAt: fixtureNow, content: nil),
        ])
        #expect(Library.ingest(parsed, into: feed, context: target, now: fixtureNow) == 0)
        #expect(feed.articles?.filter { $0.externalID == "a1" }.count == 1)
        #expect(feed.articles?.filter { $0.externalID == "a2" }.count == 1)
        #expect(feed.articles?.first { $0.externalID == "a1" }?.isKept == true)
        #expect(feed.articles?.first { $0.externalID == "a2" }?.isRead == true)
    }
}
