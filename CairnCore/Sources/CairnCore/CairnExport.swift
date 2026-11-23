import Foundation

extension Library {
    /// The cairn as Markdown: its name, then each article, most recently kept first, with what the user added to it.
    public static func markdown(for cairn: Cairn, now: Date = .now, language: String? = nil) -> String {
        let language = language ?? Localization.current
        func l(_ key: String.LocalizationValue) -> String { Localization.string(key, language) }
        let day = Date.FormatStyle(date: .long, time: .omitted, locale: Locale(identifier: language))
        let articles = (cairn.articles ?? []).filter(\.isKept)
            .sorted { ($0.keptAt ?? .distantPast) > ($1.keptAt ?? .distantPast) }
        let count = articles.isEmpty ? l("no articles") : l("\(articles.count) articles")
        var lines = ["# \(cairn.name)", "", l("Exported from Cairn on \(now.formatted(day)) · \(count)")]
        for article in articles {
            let title = article.title.replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]")
            lines += ["", "## [\(title)](\(article.link))", ""]
            var info = [article.sourceTitle, l("published on \(article.publishedAt.formatted(day))")].filter { !$0.isEmpty }
            if let keptAt = article.keptAt { info.append(l("kept on \(keptAt.formatted(day))")) }
            lines.append(info.joined(separator: " · "))
            let tags = (article.tags ?? []).map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            if !tags.isEmpty { lines += ["", l("Tags: \(tags.joined(separator: ", "))")] }
            let note = article.note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !note.isEmpty { lines += [""] + note.components(separatedBy: .newlines).map { $0.isEmpty ? ">" : "> \($0)" } }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
