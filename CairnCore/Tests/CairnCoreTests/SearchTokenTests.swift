@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct SearchTokenTests {
    private func feed(_ title: String, _ context: ModelContext) -> Feed {
        let feed = Feed(url: "https://\(title.lowercased()).test/feed", title: title)
        context.insert(feed)
        return feed
    }

    private func article(_ id: String, in feed: Feed? = nil, read: Bool = false, kept: Bool = false, tags: [String] = [],
                         context: ModelContext) throws -> Article {
        let article = Article(externalID: id, link: "https://x.test/\(id)", title: id, publishedAt: .now, content: nil,
                              sourceTitle: feed?.title ?? "")
        article.isRead = read
        article.isKept = kept
        context.insert(article)
        article.feed = feed
        for name in tags { try Library.addTag(named: name, to: article, context: context) }
        return article
    }

    @Test func sourceTokensWidenAndOtherKindsRestrict() throws {
        let context = try makeContext()
        let korben = feed("Korben", context), xavki = feed("Xavki", context), other = feed("Autre", context)
        let a = try article("a", in: korben, tags: ["Swift"], context: context)
        let b = try article("b", in: xavki, read: true, tags: ["swift"], context: context)
        let c = try article("c", in: other, context: context)
        let d = try article("d", context: context) // its subscription was deleted
        let all = [a, b, c, d]
        let k = SearchToken.source(korben.persistentModelID, title: "Korben")
        let x = SearchToken.source(xavki.persistentModelID, title: "Xavki")

        #expect(Library.filter(all, tokens: []) == all)
        #expect(Library.filter(all, tokens: [k]) == [a])
        #expect(Library.filter(all, tokens: [k, x]) == [a, b])
        #expect(Library.filter(all, tokens: [k, x, .unread]) == [a])
        #expect(Library.filter(all, tokens: [.tag(key: Library.tagKey("SWIFT"), name: "Swift"), .unread]) == [a])
    }

    @Test func tagTokenIgnoresCaseAndAccentsAndKeptTokenKeeps() throws {
        let context = try makeContext()
        let a = try article("a", kept: true, tags: ["Sécurité"], context: context)
        let b = try article("b", kept: true, tags: ["securite"], context: context)
        let c = try article("c", tags: ["Sécurité"], context: context)
        let token = SearchToken.tag(key: Library.tagKey("Sécurité"), name: "Sécurité")

        #expect(Library.filter([a, b, c], tokens: [token]) == [a, b, c])
        #expect(Library.filter([a, b, c], tokens: [token, .kept]) == [a, b])
    }

    @Test func suggestionsFollowTheTypedText() throws {
        let context = try makeContext()
        let korben = feed("Korben", context), xavki = feed("Xavki", context)
        let a = try article("a", in: korben, tags: ["Kubernetes", "Swift"], context: context)
        let b = try article("b", in: xavki, tags: ["swift"], context: context)
        let all = [a, b]
        let k = SearchToken.source(korben.persistentModelID, title: "Korben")
        let swift = SearchToken.tag(key: "swift", name: "Swift")

        #expect(Library.suggestedTokens(for: "  ", in: all).isEmpty)
        #expect(Library.suggestedTokens(for: "kor", in: all) == [k])
        #expect(Library.suggestedTokens(for: "K", in: all).contains(.tag(key: "kubernetes", name: "Kubernetes")))
        #expect(Library.suggestedTokens(for: "gard", in: all) == [.kept])
        #expect(Library.suggestedTokens(for: "NON", in: all) == [.unread])
        #expect(Library.suggestedTokens(for: "kor", in: all, excluding: [k]).isEmpty)
        // Prefixes keep one kind; nothing after them offers them all.
        #expect(Library.suggestedTokens(for: "tag:", in: all).map(\.label) == ["Kubernetes", "Swift"])
        #expect(Library.suggestedTokens(for: "tag:sw", in: all) == [swift])
        #expect(Library.suggestedTokens(for: "Source: x", in: all) == [.source(xavki.persistentModelID, title: "Xavki")])
        #expect(Library.suggestedTokens(for: "source:", in: all).map(\.label) == ["Korben", "Xavki"])
    }

    @Test func suggestionsAreLimited() throws {
        let context = try makeContext()
        let all = try (0..<15).map { try article("a\($0)", tags: ["tag\($0)"], context: context) }
        #expect(Library.suggestedTokens(for: "tag:", in: all).count == 10)
        #expect(Library.suggestedTokens(for: "tag:", in: all, limit: 3).count == 3)
    }
}
