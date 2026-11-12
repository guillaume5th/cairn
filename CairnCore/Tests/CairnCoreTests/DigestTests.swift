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

    @Test func articlesOfTheLast24Hours() throws {
        let context = try makeContext()
        _ = article("une", hoursAgo: 1, context: context)
        _ = article("vingt-trois", hoursAgo: 23, context: context)
        _ = article("vingt-cinq", hoursAgo: 25, context: context)
        _ = article("futur", hoursAgo: -1, context: context)
        let titles = try Library.digestArticles(context: context, now: fixtureNow).map(\.title)
        #expect(titles == ["une", "vingt-trois"])
    }

    @Test func promptWithinBudget() throws {
        let context = try makeContext()
        let short = article("Court", hoursAgo: 1, content: "<p>Un texte bref.</p>", context: context)
        let prompt = Library.digestPrompt(for: [short])
        #expect(prompt.contains("- [Blog] Court — Un texte bref."))
        #expect(prompt.contains("français"))

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
        let prompt = Library.articleSummaryPrompt(for: short)
        #expect(prompt.contains("Titre : Court"))
        #expect(prompt.hasSuffix("Un texte bref."))
        #expect(prompt.contains("français"))
        #expect(Library.isExcerpt(short))

        let long = article("Long", hoursAgo: 1, content: "<p>" + String(repeating: "mot ", count: 5_000) + "</p>", context: context)
        #expect(Library.articleSummaryPrompt(for: long).count <= Library.digestPromptBudget)
        #expect(!Library.isExcerpt(long))
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
