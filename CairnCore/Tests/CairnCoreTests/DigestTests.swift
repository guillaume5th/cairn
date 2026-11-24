@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct DigestTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        return calendar
    }()

    func date(_ day: Int, _ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
    }

    @Test func storeRoundTrip() throws {
        let context = try makeContext()
        let items = [DigestItem(title: "T", source: "S", link: "https://a.test/1")]
        context.insert(Digest(createdAt: fixtureNow, text: "# Résumé", items: items, engine: "Apple"))
        try context.save()
        let digest = try #require(try context.fetch(FetchDescriptor<Digest>()).first)
        #expect(digest.text == "# Résumé")
        #expect(digest.items == items)
        #expect(!digest.isRead)
    }

    @Test func dueness() {
        let eight = 8 * 60
        // Before the run time.
        #expect(!Digest.isDue(now: date(12, 7, 59), minutes: eight, lastAttempt: nil, calendar: calendar))
        // After it, never attempted.
        #expect(Digest.isDue(now: date(12, 8), minutes: eight, lastAttempt: nil, calendar: calendar))
        // Already attempted today (success or failure).
        #expect(!Digest.isDue(now: date(12, 15), minutes: eight, lastAttempt: date(12, 8, 1), calendar: calendar))
        // Three days missed: due, then not due once attempted.
        #expect(Digest.isDue(now: date(12, 10), minutes: eight, lastAttempt: date(9, 8), calendar: calendar))
        #expect(!Digest.isDue(now: date(12, 10, 1), minutes: eight, lastAttempt: date(12, 10), calendar: calendar))
        // Run time moved to a moment already past today, last attempt yesterday.
        #expect(Digest.isDue(now: date(12, 10), minutes: 9 * 60, lastAttempt: date(11, 11), calendar: calendar))
    }

    func article(_ title: String, hoursAgo: Double, content: String? = nil, context: ModelContext) -> Article {
        let article = Article(externalID: title, link: "https://a.test/\(title)", title: title,
                              publishedAt: fixtureNow.addingTimeInterval(-hoursAgo * 3_600), content: content, sourceTitle: "Blog")
        context.insert(article)
        return article
    }

    @Test func readingMinutes() throws {
        let context = try makeContext()
        let empty = article("Vide", hoursAgo: 1, content: "<p> </p>", context: context)
        #expect(Library.readingMinutes(empty) == nil)
        let short = article("Court", hoursAgo: 1, content: "<p>Un texte bref.</p>", context: context)
        #expect(Library.readingMinutes(short) == 1)
        let long = article("Long", hoursAgo: 1, content: "<p>" + String(repeating: "mot ", count: 2_300) + "</p>", context: context)
        #expect(Library.readingMinutes(long) == 10)
    }

    @Test func articlesOfTheLast24Hours() throws {
        let context = try makeContext()
        _ = article("une", hoursAgo: 1, context: context)
        _ = article("vingt-trois", hoursAgo: 23, context: context)
        _ = article("vingt-cinq", hoursAgo: 25, context: context)
        _ = article("futur", hoursAgo: -1, context: context)
        let titles = try Library.digestArticles(context: context, now: fixtureNow).map(\.title)
        #expect(titles == ["une", "vingt-trois"])
    }

    @Test func digestListsALinkOnce() throws {
        let context = try makeContext()
        let first = article("une", hoursAgo: 1, context: context)
        let copy = article("copie", hoursAgo: 2, context: context)
        copy.link = "http://www.a.test/une/"
        copy.isRead = true
        let titles = try Library.digestArticles(context: context, now: fixtureNow).map(\.title)
        #expect(titles == [first.title])
    }

    @Test func promptWithinBudget() throws {
        let context = try makeContext()
        let short = article("Court", hoursAgo: 1, content: "<p>Un texte bref.</p>", context: context)
        let prompt = Library.digestPrompt(for: [short], language: "en")
        #expect(prompt.contains("- [Blog] Court — Un texte bref."))
        #expect(prompt.contains("in English."))
        #expect(Library.digestPrompt(for: [short], language: "fr").contains("in French."))

        let many = (0..<500).map { article("Titre \($0)", hoursAgo: 1, content: String(repeating: "mot ", count: 200), context: context) }
        let big = Library.digestPrompt(for: many)
        #expect(big.count <= Library.digestPromptBudget)
        #expect(big.contains("- [Blog] Titre 0 — mot"))
        #expect(big.contains("\n- [Blog] Titre 28\n")) // past the excerpts, titles only
        #expect(!big.contains("Titre 499"))
    }

    @Test func articleSummaryPrompt() throws {
        let context = try makeContext()
        let short = article("Court", hoursAgo: 1, content: "<p>Un <b>texte</b> bref.</p>", context: context)
        let prompt = Library.articleSummaryPrompt(for: short, language: "fr")
        #expect(prompt.contains("Title: Court"))
        #expect(prompt.hasSuffix("Un texte bref."))
        #expect(prompt.contains("in French."))
        #expect(Library.articleSummaryPrompt(for: short, language: "en").contains("in English."))
        #expect(Library.isExcerpt(short))

        let long = article("Long", hoursAgo: 1, content: "<p>" + String(repeating: "mot ", count: 5_000) + "</p>", context: context)
        #expect(Library.articleSummaryPrompt(for: long).count <= Library.digestPromptBudget)
        #expect(!Library.isExcerpt(long))
    }

    @Test func fullTextComesFirstAndFeedContentStaysAvailable() throws {
        let context = try makeContext()
        let item = article("Extrait", hoursAgo: 1, content: "<p>Début de l'article…</p>", context: context)
        item.summaryDate = fixtureNow
        #expect(Library.isExcerpt(item))

        item.fullContent = "<p>Le texte complet de l'article.</p>"
        item.fullContentFetchedAt = fixtureNow.addingTimeInterval(60)
        #expect(Library.articleSummaryPrompt(for: item).hasSuffix("Le texte complet de l'article."))
        #expect(Library.digestPrompt(for: [item]).contains("Le texte complet"))
        #expect(Library.displayedContent(item) == item.fullContent)
        #expect(Library.isExcerpt(item), "résumé fait avant le chargement du texte intégral")

        item.summaryDate = fixtureNow.addingTimeInterval(120)
        #expect(!Library.isExcerpt(item))

        item.showsFeedContent = true
        #expect(Library.displayedContent(item) == item.content)
        #expect(Library.articleSummaryPrompt(for: item).hasSuffix("Le texte complet de l'article."))
    }

    @Test func itemsKeepSourceAndLink() throws {
        let context = try makeContext()
        let items = Library.digestItems(for: [article("A", hoursAgo: 1, context: context)])
        #expect(items == [DigestItem(title: "A", source: "Blog", link: "https://a.test/A")])
    }

    @Test func searchCoversTextAndArticles() {
        let tmux = Digest(createdAt: fixtureNow, text: "## Système\n- Astuce **tmux**", items: [], engine: "")
        let aws = Digest(createdAt: fixtureNow, text: "Rien", items: [DigestItem(title: "AWS Émulateur", source: "AWS News Blog", link: "")], engine: "")
        let digests = [tmux, aws]
        #expect(Library.search("TMUX", in: digests).map(\.text) == [tmux.text])
        #expect(Library.search("emulateur", in: digests).map(\.text) == [aws.text])
        #expect(Library.search("news blog", in: digests).map(\.text) == [aws.text])
        #expect(Library.search("  ", in: digests).count == 2)
        #expect(Library.search("kubernetes", in: digests).isEmpty)
    }

    @Test func snippetAroundFirstMatch() {
        let digest = Digest(createdAt: fixtureNow, text: "## Système\n- Astuce **tmux** après une mise à jour",
                            items: [DigestItem(title: "AWS Émulateur", source: "AWS News Blog", link: "")], engine: "")
        #expect(Library.snippet(for: "TMUX", in: digest) == "Système - Astuce tmux après une mise à jour")
        #expect(Library.snippet(for: "emulateur", in: digest) == "AWS Émulateur")
        #expect(Library.snippet(for: "kubernetes", in: digest) == nil)
        #expect(Library.snippet(for: "", in: digest) == nil)
    }

    @Test func purgeOldDigests() throws {
        let context = try makeContext()
        context.insert(Digest(createdAt: fixtureNow.addingTimeInterval(-8 * 86_400), text: "vieux", items: [], engine: ""))
        context.insert(Digest(createdAt: fixtureNow.addingTimeInterval(-6 * 86_400), text: "récent", items: [], engine: ""))
        try Library.purgeDigests(context: context, olderThan: 7, now: fixtureNow)
        try context.save()
        #expect(try context.fetch(FetchDescriptor<Digest>()).map(\.text) == ["récent"])
    }
}
