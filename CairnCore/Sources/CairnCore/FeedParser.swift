import FeedKit
import Foundation

public struct ParsedItem: Sendable, Equatable {
    public var externalID: String
    public var link: String
    public var title: String
    public var publishedAt: Date?
    public var content: String?
    /// The episode of a podcast: the first audio file attached to the item.
    public var audioURL: String? = nil
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
            // FeedKit decodes RSS <author> as text and rejects the whole feed when a site nests elements in it
            // (Google Cloud blog); Cairn never reads authors, so retry without them.
            guard let stripped = withoutAuthors(data), let retried = try? FeedKit.Feed(data: stripped) else {
                throw CairnError.notAFeed
            }
            feed = retried
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
                     date: item.pubDate, content: item.content?.encoded ?? item.description,
                     audio: [item.enclosure?.attributes].compactMap { $0 }.map { ($0.url, $0.type) })
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
                            content: entry.content?.text ?? entry.summary?.text,
                            audio: (entry.links ?? []).compactMap(\.attributes).filter { $0.rel == "enclosure" }
                                .map { ($0.href, $0.type) })
            }
        case let .json(json):
            title = json.title
            siteURL = json.homePageURL
            // JSON Feed `icon` is 512 px, `favicon` 64 px: the larger looks better in a circle.
            iconURL = json.icon ?? json.favicon
            items = (json.items ?? []).map { item in
                make(id: item.id, link: item.url ?? item.externalURL, title: item.title,
                     date: item.datePublished ?? item.dateModified,
                     content: item.contentHtml ?? item.contentText ?? item.summary,
                     audio: (item.attachments ?? []).map { ($0.url, $0.mimeType) })
            }
        }
        return ParsedFeed(title: clean(title) ?? "", items: items.compactMap { $0 },
                          siteURL: clean(siteURL), iconURL: clean(iconURL))
    }

    private static func make(id: String?, link: String?, title: String?, date: Date?, content: String?,
                             audio: [(url: String?, type: String?)] = []) -> ParsedItem? {
        let link = clean(link)
        let audioURL = audio.first { isAudio($0.url, type: $0.type) }.flatMap { clean($0.url) }
        guard let externalID = clean(id) ?? link ?? audioURL else { return nil }
        return ParsedItem(externalID: externalID, link: link ?? "", title: clean(title) ?? "",
                          publishedAt: date, content: clean(content), audioURL: audioURL)
    }

    /// Audio by its declared type, or by its extension when the feed gives none.
    private static func isAudio(_ url: String?, type: String?) -> Bool {
        if let type = clean(type) { return type.lowercased().hasPrefix("audio/") }
        guard let url = clean(url).flatMap(URL.init(string:)) else { return false }
        return ["mp3", "m4a", "aac", "ogg", "opus", "wav"].contains(url.pathExtension.lowercased())
    }

    /// The UTF-8 feed without its `<author>` elements; nil when there are none or the data is not UTF-8.
    static func withoutAuthors(_ data: Data) -> Data? {
        guard let xml = String(data: data, encoding: .utf8) else { return nil }
        let stripped = xml.replacing(/(?s)<author\b[^>]*>.*?<\/author>/, with: "")
        return stripped == xml ? nil : Data(stripped.utf8)
    }

    private static func clean(_ s: String?) -> String? {
        guard let s = s?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        return s
    }
}
