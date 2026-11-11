import FeedKit
import Foundation

public struct ParsedItem: Sendable, Equatable {
    public var externalID: String
    public var link: String
    public var title: String
    public var publishedAt: Date?
    public var content: String?
}

public struct ParsedFeed: Sendable, Equatable {
    public var title: String
    public var items: [ParsedItem]
    /// Home page of the site, as declared by the feed.
    public var siteURL: String? = nil
    /// Square icon declared by the feed (Atom `icon`, JSON Feed `icon` then `favicon`).
    public var iconURL: String? = nil
}

public enum FeedParser {
    /// Parses RSS, RDF, Atom or JSON Feed data. Items with neither id nor link are dropped (they cannot be deduplicated).
    public static func parse(_ data: Data) throws -> ParsedFeed {
        let feed: FeedKit.Feed
        do {
            feed = try FeedKit.Feed(data: data)
        } catch {
            throw CairnError.notAFeed
        }

        let title: String?
        let items: [ParsedItem?]
        var siteURL: String?
        var iconURL: String?
        switch feed {
        case let .rss(rss):
            title = rss.channel?.title
            siteURL = rss.channel?.link
            items = (rss.channel?.items ?? []).map { item in
                make(id: item.guid?.text, link: item.link, title: item.title,
                     date: item.pubDate, content: item.content?.encoded ?? item.description)
            }
        case let .rdf(rdf):
            title = rdf.channel?.title
            siteURL = rdf.channel?.link
            items = (rdf.items ?? []).map { item in
                make(id: nil, link: item.link, title: item.title, date: nil, content: item.description)
            }
        case let .atom(atom):
            title = atom.title?.text
            siteURL = atom.links?.first { ($0.attributes?.rel ?? "alternate") == "alternate" }?.attributes?.href
            // Atom `logo` is a wide banner, unreadable at icon size.
            iconURL = atom.icon
            items = (atom.entries ?? []).map { entry in
                let alternate = entry.links?.first { ($0.attributes?.rel ?? "alternate") == "alternate" }
                return make(id: entry.id, link: alternate?.attributes?.href, title: entry.title,
                            date: entry.published ?? entry.updated,
                            content: entry.content?.text ?? entry.summary?.text)
            }
        case let .json(json):
            title = json.title
            siteURL = json.homePageURL
            // JSON Feed `icon` is 512 px, `favicon` 64 px: the larger looks better in a circle.
            iconURL = json.icon ?? json.favicon
            items = (json.items ?? []).map { item in
                make(id: item.id, link: item.url ?? item.externalURL, title: item.title,
                     date: item.datePublished ?? item.dateModified,
                     content: item.contentHtml ?? item.contentText ?? item.summary)
            }
        }
        return ParsedFeed(title: clean(title) ?? "", items: items.compactMap { $0 },
                          siteURL: clean(siteURL), iconURL: clean(iconURL))
    }

    private static func make(id: String?, link: String?, title: String?, date: Date?, content: String?) -> ParsedItem? {
        let link = clean(link)
        guard let externalID = clean(id) ?? link else { return nil }
        return ParsedItem(externalID: externalID, link: link ?? "", title: clean(title) ?? "",
                          publishedAt: date, content: clean(content))
    }

    private static func clean(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}
