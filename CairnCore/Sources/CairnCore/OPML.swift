import Foundation

public struct OPMLFeed: Sendable, Equatable {
    public var title: String
    public var url: String
    /// Top-level folder holding the feed, nil at the root.
    public var folder: String?

    public init(title: String, url: String, folder: String? = nil) {
        self.title = title
        self.url = url
        self.folder = folder
    }
}

public enum OPML {
    /// Returns every outline carrying an `xmlUrl` in document order, each with its top-level folder:
    /// sub-folders merge into it.
    public static func parse(_ data: Data) throws -> [OPMLFeed] {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse(), delegate.sawRoot else { throw CairnError.invalidOPML }
        return delegate.feeds
    }

    /// Feeds with a folder are grouped under it, folders in order of first appearance, then root feeds.
    public static func export(_ feeds: [OPMLFeed]) -> Data {
        func outline(_ feed: OPMLFeed, indent: String) -> String {
            let title = escape(feed.title)
            return #"\#(indent)<outline type="rss" text="\#(title)" title="\#(title)" xmlUrl="\#(escape(feed.url))"/>"#
        }
        var folders: [String] = []
        for case let folder? in feeds.map(\.folder) where !folders.contains(folder) { folders.append(folder) }
        let outlines = folders.map { folder in
            let name = escape(folder)
            let children = feeds.filter { $0.folder == folder }.map { outline($0, indent: "      ") }
            return (["    <outline text=\"\(name)\" title=\"\(name)\">"] + children + ["    </outline>"]).joined(separator: "\n")
        } + feeds.filter { $0.folder == nil }.map { outline($0, indent: "    ") }
        let xml = """
        <?xml version="1.0" encoding="UTF-8"?>
        <opml version="2.0">
          <head>
            <title>Abonnements Cairn</title>
          </head>
          <body>
        \(outlines.joined(separator: "\n"))
          </body>
        </opml>

        """
        return Data(xml.utf8)
    }

    private static func escape(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private final class Delegate: NSObject, XMLParserDelegate {
        var feeds: [OPMLFeed] = []
        var sawRoot = false
        /// Title of each open outline; nil for a feed outline (feeds are never folders).
        var open: [String?] = []

        func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                    qualifiedName: String?, attributes: [String: String] = [:]) {
            if name.lowercased() == "opml" { sawRoot = true }
            guard name == "outline" else { return }
            let title = attributes["title"] ?? attributes["text"]
            guard let url = attributes["xmlUrl"]?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty else {
                open.append(title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
                return
            }
            open.append(nil)
            let folder = open.first.flatMap { $0 }.flatMap { $0.isEmpty ? nil : $0 }
            feeds.append(OPMLFeed(title: title ?? url, url: url, folder: folder))
        }

        func parser(_ parser: XMLParser, didEndElement name: String, namespaceURI: String?, qualifiedName: String?) {
            if name == "outline" { open.removeLast() }
        }
    }
}
