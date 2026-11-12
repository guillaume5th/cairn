@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct ArticleExtractorTests {
    let base = URL(string: "https://blog.example/2026/cairns")!

    func extract(_ name: String) async throws -> ExtractedArticle {
        try await ArticleExtractor.extract(html: String(decoding: try fixture(name), as: UTF8.self), baseURL: base)
    }

    @Test func keepsTheArticleAndDropsTheRest() async throws {
        let article = try await extract("article.html")
        #expect(article.content.contains("Paragraphe 1 de l'article complet"))
        #expect(article.content.contains("Paragraphe 7"))
        for noise in ["Publicité", "Archives", "Super article", "© Le Blog"] {
            #expect(!article.content.contains(noise), "\(noise) ne devrait pas être gardé")
        }
        #expect(article.title?.contains("Les cairns de montagne") == true)
        #expect(article.siteName == "Le Blog des Sentiers")
    }

    @Test func dropsScriptsAndIframes() async throws {
        let content = try await extract("article.html").content.lowercased()
        #expect(!content.contains("<script"))
        #expect(!content.contains("<iframe"))
    }

    @Test func resolvesRelativeLinksAndImages() async throws {
        let content = try await extract("article.html").content
        #expect(content.contains("https://blog.example/images/cairn.jpg"))
        #expect(content.contains("https://blog.example/autre-article"))
    }

    @Test func pageWithoutArticle() async {
        await #expect(throws: CairnError.noArticleContent) { try await extract("home.html") }
    }

    @Test func downloadedPageWithoutArticle() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        await #expect(throws: CairnError.noArticleContent) {
            try await ArticleExtractor.extract(from: URL(string: "https://html.test/")!, session: URLSession(configuration: config))
        }
    }

    @Test func httpErrorIsReported() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubProtocol.self]
        await #expect(throws: CairnError.httpStatus(500)) {
            try await ArticleExtractor.extract(from: URL(string: "https://broken.test/a")!, session: URLSession(configuration: config))
        }
    }

    @Test func declaredCharsetIsHonoured() {
        let latin1 = "<p>Été à Noël</p>".data(using: .isoLatin1)!
        #expect(ArticleExtractor.decode(latin1, encodingName: "iso-8859-1") == "<p>Été à Noël</p>")
        let meta = Data(#"<meta charset="windows-1252"><p>"#.utf8) + "café".data(using: .windowsCP1252)!
        #expect(ArticleExtractor.decode(meta, encodingName: nil).hasSuffix("café"))
    }
}

@MainActor
struct AutomaticFullContentTests {
    func make(_ title: String, publishedAt: Date, in feed: Feed, context: ModelContext) -> Article {
        let item = Article(externalID: title, link: "https://site.test/\(title)", title: title, publishedAt: publishedAt,
                           content: "<p>Extrait</p>", sourceTitle: feed.title)
        context.insert(item)
        item.feed = feed
        return item
    }

    @Test func onlyArticlesSinceActivationNeverTried() throws {
        let context = try makeContext()
        let auto = Feed(url: "https://auto.test/feed", title: "Auto")
        let manual = Feed(url: "https://manual.test/feed", title: "Manuel")
        context.insert(auto)
        context.insert(manual)
        auto.loadsFullContentSince = fixtureNow
        let before = make("avant", publishedAt: fixtureNow.addingTimeInterval(-60), in: auto, context: context)
        let new = make("nouveau", publishedAt: fixtureNow.addingTimeInterval(60), in: auto, context: context)
        let tried = make("tenté", publishedAt: fixtureNow.addingTimeInterval(120), in: auto, context: context)
        tried.fullContentFetchedAt = fixtureNow
        _ = make("manuel", publishedAt: fixtureNow.addingTimeInterval(60), in: manual, context: context)

        let pending = try Library.articlesAwaitingFullContent(context: context)
        #expect(pending.map(\.title) == ["nouveau"])
        #expect(!pending.contains { $0 === before })
        _ = new
    }

    @Test func failureKeepsFeedContentAndIsNotRetried() throws {
        let context = try makeContext()
        let feed = Feed(url: "https://auto.test/feed", title: "Auto")
        context.insert(feed)
        feed.loadsFullContentSince = fixtureNow
        let item = make("a", publishedAt: fixtureNow.addingTimeInterval(60), in: feed, context: context)

        Library.recordFullContent(.failure(CairnError.noArticleContent), for: item, now: fixtureNow)
        #expect(item.fullContent == nil)
        #expect(item.content == "<p>Extrait</p>")
        #expect(try Library.articlesAwaitingFullContent(context: context).isEmpty)

        Library.recordFullContent(.success(ExtractedArticle(title: nil, content: "<p>Complet</p>", siteName: nil)), for: item)
        #expect(Library.displayedContent(item) == "<p>Complet</p>")
    }
}
