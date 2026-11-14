import Foundation

extension Library {
    /// The cairn as Markdown: its name, then each article, most recently kept first, with what the user added to it.
    public static func markdown(for cairn: Cairn, now: Date = .now) -> String {
        let day = Date.FormatStyle(date: .long, time: .omitted, locale: Locale(identifier: "fr_FR"))
        let articles = (cairn.articles ?? []).filter(\.isKept)
            .sorted { ($0.keptAt ?? .distantPast) > ($1.keptAt ?? .distantPast) }
        let count = switch articles.count {
        case 0: "aucun article"
        case 1: "1 article"
        case let count: "\(count) articles"
        }
        var lines = ["# \(cairn.name)", "", "Exporté de Cairn le \(now.formatted(day)) · \(count)"]
        for article in articles {
            let title = article.title.replacingOccurrences(of: "[", with: "\\[").replacingOccurrences(of: "]", with: "\\]")
            lines += ["", "## [\(title)](\(article.link))", ""]
            var info = [article.sourceTitle, "publié le \(article.publishedAt.formatted(day))"].filter { !$0.isEmpty }
            if let keptAt = article.keptAt { info.append("gardé le \(keptAt.formatted(day))") }
            lines.append(info.joined(separator: " · "))
            let tags = (article.tags ?? []).map(\.name).sorted { $0.localizedStandardCompare($1) == .orderedAscending }
            if !tags.isEmpty { lines += ["", "Tags : " + tags.joined(separator: ", ")] }
            let note = article.note.trimmingCharacters(in: .whitespacesAndNewlines)
            if !note.isEmpty { lines += [""] + note.components(separatedBy: .newlines).map { $0.isEmpty ? ">" : "> \($0)" } }
        }
        return lines.joined(separator: "\n") + "\n"
    }
}
