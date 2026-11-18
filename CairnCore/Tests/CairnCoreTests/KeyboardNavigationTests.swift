@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct KeyboardNavigationTests {
    private func articles(_ count: Int, context: ModelContext) -> [Article] {
        (0..<count).map { i in
            let article = Article(externalID: "a\(i)", link: "https://x.test/\(i)", title: "A\(i)", publishedAt: .now,
                                  content: nil, sourceTitle: "")
            context.insert(article)
            return article
        }
    }

    @Test func neighborMovesOnePlaceWithoutWrapping() throws {
        let context = try makeContext()
        let list = articles(3, context: context)
        let id = { (i: Int) in list[i].persistentModelID }

        #expect(Library.neighbor(of: id(1), in: list, offset: 1) === list[2])
        #expect(Library.neighbor(of: id(1), in: list, offset: -1) === list[0])
        #expect(Library.neighbor(of: id(2), in: list, offset: 1) == nil)
        #expect(Library.neighbor(of: id(0), in: list, offset: -1) == nil)
    }

    @Test func neighborWithoutCurrentArticle() throws {
        let context = try makeContext()
        let list = articles(3, context: context)
        let elsewhere = articles(1, context: context)[0].persistentModelID // not in the list

        #expect(Library.neighbor(of: nil, in: list, offset: 1) === list[0])
        #expect(Library.neighbor(of: elsewhere, in: list, offset: 1) === list[0])
        #expect(Library.neighbor(of: nil, in: list, offset: -1) === list[0])
        #expect(Library.neighbor(of: nil, in: [], offset: 1) == nil)
    }

    @Test func lastUsedCairnFollowsTheMostRecentlyKeptArticle() throws {
        let context = try makeContext()
        let veille = Cairn(name: "Veille"), lectures = Cairn(name: "Lectures")
        context.insert(veille)
        context.insert(lectures)
        let list = articles(2, context: context)
        let now = Date.now
        Library.keep(list[0], in: lectures, now: now.addingTimeInterval(-60))
        Library.keep(list[1], in: veille, now: now)

        #expect(try Library.lastUsedCairn(context: context) === veille)
        // Unkeeping the newest falls back on the previous one.
        Library.unkeep(list[1])
        #expect(try Library.lastUsedCairn(context: context) === lectures)
    }

    @Test func lastUsedCairnWithoutKeptArticleIsTheFirstByName() throws {
        let context = try makeContext()
        #expect(try Library.lastUsedCairn(context: context) == nil)
        context.insert(Cairn(name: "Veille"))
        context.insert(Cairn(name: "Lectures"))
        #expect(try Library.lastUsedCairn(context: context)?.name == "Lectures")
    }
}
