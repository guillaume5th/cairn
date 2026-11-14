@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct CairnExportTests {
    @Test func articlesWithTagsAndNotes() throws {
        let context = try makeContext()
        let cairn = try Library.createCairn(named: "Lectures", context: context)
        let older = Article(externalID: "a1", link: "https://rss.test/a1", title: "Swift [6]", publishedAt: fixtureNow,
                            content: nil, sourceTitle: "Blog")
        let newer = Article(externalID: "a2", link: "https://rss.test/a2", title: "Récent", publishedAt: fixtureNow,
                            content: nil, sourceTitle: "Autre")
        context.insert(older)
        context.insert(newer)
        Library.keep(older, in: cairn, now: fixtureNow)
        Library.keep(newer, in: cairn, now: fixtureNow.addingTimeInterval(3600))
        try Library.addTag(named: "swift", to: older, context: context)
        older.note = "À relire\n\nVraiment"
        let markdown = Library.markdown(for: cairn, now: fixtureNow)
        #expect(markdown.hasPrefix("# Lectures\n\nExporté de Cairn le "))
        #expect(markdown.contains("· 2 articles\n"))
        #expect(markdown.contains("## [Swift \\[6\\]](https://rss.test/a1)\n\nBlog · publié le "))
        #expect(markdown.contains("\n\nTags : swift\n\n> À relire\n>\n> Vraiment\n"))
        let first = try #require(markdown.range(of: "Récent")), second = try #require(markdown.range(of: "Swift"))
        #expect(first.lowerBound < second.lowerBound)
    }

    @Test func emptyCairn() throws {
        let cairn = try Library.createCairn(named: "Vide", context: try makeContext())
        #expect(Library.markdown(for: cairn, now: fixtureNow).hasSuffix("· aucun article\n"))
    }
}
