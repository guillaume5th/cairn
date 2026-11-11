import Foundation

public struct OPMLFeed: Sendable, Equatable {
    public var title: String
    public var url: String

    public init(title: String, url: String) {
        self.title = title
        self.url = url
    }
}

public enum OPML {
    /// Returns every outline carrying an `xmlUrl`, folders flattened, in document order.
    public static func parse(_ data: Data) throws -> [OPMLFeed] {
        let delegate = Delegate()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse(), delegate.sawRoot else { throw CairnError.invalidOPML }
        return delegate.feeds
    }

    public static func export(_ feeds: [OPMLFeed]) -> Data {
        let outlines = feeds.map { feed in
            let title = escape(feed.title)
            return #"    <outline type="rss" text="\#(title)" title="\#(title)" xmlUrl="\#(escape(feed.url))"/>"#
        }
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

        func parser(_ parser: XMLParser, didStartElement name: String, namespaceURI: String?,
                    qualifiedName: String?, attributes: [String: String] = [:]) {
            if name.lowercased() == "opml" { sawRoot = true }
            guard name == "outline",
                  let url = attributes["xmlUrl"]?.trimmingCharacters(in: .whitespacesAndNewlines), !url.isEmpty
            else { return }
            let title = attributes["title"] ?? attributes["text"] ?? url
            feeds.append(OPMLFeed(title: title, url: url))
        }
    }
}
