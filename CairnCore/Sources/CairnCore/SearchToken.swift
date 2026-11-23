import Foundation
import SwiftData

/// A filter the user adds to the search field of an article list, next to the text.
public enum SearchToken: Hashable, Identifiable, Sendable {
    /// The articles of one subscription; matched by identity, the title is only what the token shows.
    case source(PersistentIdentifier, title: String)
    /// The articles carrying a tag; matched by `Library.tagKey`, the name is only what the token shows.
    case tag(key: String, name: String)
    case unread
    case kept

    public var id: Self { self }

    public var label: String {
        switch self {
        case let .source(_, title): title.isEmpty ? Localization.string("Untitled") : title
        case let .tag(_, name): name
        case .unread: Localization.string("Unread")
        case .kept: Localization.string("Kept")
        }
    }
}

extension Library {
    /// The articles that match every kind of token: tokens of one kind widen (this source or that one), kinds
    /// restrict each other. No token leaves the list as it is.
    public static func filter(_ articles: [Article], tokens: [SearchToken]) -> [Article] {
        guard !tokens.isEmpty else { return articles }
        var sources: Set<PersistentIdentifier> = [], tags: Set<String> = []
        var unread = false, kept = false
        for token in tokens {
            switch token {
            case let .source(id, _): sources.insert(id)
            case let .tag(key, _): tags.insert(key)
            case .unread: unread = true
            case .kept: kept = true
            }
        }
        return articles.filter { article in
            (sources.isEmpty || article.feed.map { sources.contains($0.persistentModelID) } ?? false)
                && (tags.isEmpty || (article.tags ?? []).contains { tags.contains($0.key) })
                && (!unread || !article.isRead)
                && (!kept || article.isKept)
        }
    }

    /// The tokens to offer while `text` is typed, among the sources and tags of `articles` plus « Non lus » and
    /// « Gardés »: those whose name contains the text, ignoring case and accents. A `source:` or `tag:` prefix keeps
    /// that kind only, and then offers every one when nothing follows it. Nothing for an empty text, and not the
    /// tokens already in the field.
    // shortcut: linear scan of the listed articles on each keystroke, like `search`; index them if typing lags.
    public static func suggestedTokens(for text: String, in articles: [Article], excluding present: [SearchToken] = [],
                                       limit: Int = 10) -> [SearchToken] {
        var needle = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return [] }
        var kind: String?
        for prefix in ["source:", "tag:"] where needle.lowercased().hasPrefix(prefix) {
            kind = prefix
            needle = String(needle.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        var feeds: [PersistentIdentifier: String] = [:], tags: [String: String] = [:]
        for article in articles {
            if let feed = article.feed { feeds[feed.persistentModelID] = feed.title }
            for tag in article.tags ?? [] { tags[tag.key] = tag.name }
        }
        var candidates: [SearchToken] = []
        if kind != "tag:" {
            candidates += feeds.map { SearchToken.source($0.key, title: $0.value) }.sorted { $0.label < $1.label }
        }
        if kind != "source:" {
            candidates += tags.map { SearchToken.tag(key: $0.key, name: $0.value) }.sorted { $0.label < $1.label }
        }
        if kind == nil { candidates += [.unread, .kept] }
        return Array(candidates.lazy.filter { token in
            !present.contains(token) && (needle.isEmpty || token.label.localizedStandardContains(needle))
        }.prefix(limit))
    }
}
