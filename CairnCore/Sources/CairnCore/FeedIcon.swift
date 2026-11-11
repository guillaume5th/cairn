import AppKit
import Foundation

/// Finding a feed's site icon (favicon).
public enum FeedIcon {
    /// Icon URLs declared by `<link rel="…icon…">` in the page head, in document order, resolved against `baseURL`.
    // shortcut: regex instead of an HTML parser, so malformed <link> tags or ones added by JavaScript are missed;
    // switch to a real parser if common sites fail.
    public static func declaredIcons(inHTML html: String, baseURL: URL) -> [URL] {
        let head = html.firstRange(of: /<\/head\s*>/.ignoresCase()).map { String(html[..<$0.lowerBound]) } ?? html
        return head.matches(of: /<link\b[^>]*>/.ignoresCase()).compactMap { match in
            let tag = String(match.output)
            guard let rel = attribute("rel", in: tag), let href = attribute("href", in: tag),
                  rel.lowercased().split(whereSeparator: \.isWhitespace).contains(where: iconRels.contains)
            else { return nil }
            return URL(string: href.replacingOccurrences(of: "&amp;", with: "&"), relativeTo: baseURL)?.absoluteURL
        }
    }

    // `mask-icon` is excluded: it is a monochrome Safari pinned-tab mask, not a favicon.
    private static let iconRels: Set<Substring> = ["icon", "apple-touch-icon", "apple-touch-icon-precomposed"]

    private static func attribute(_ name: String, in tag: String) -> String? {
        // name="…", name='…' or name=… (unquoted)
        let pattern = try! Regex<(Substring, Substring?, Substring?, Substring?)>(
            #"\b\#(name)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^"'>\s]+))"#
        ).ignoresCase()
        guard let m = tag.firstMatch(of: pattern), let value = m.output.1 ?? m.output.2 ?? m.output.3 else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

/// What is known about a feed when looking for its icon.
public struct IconRequest: Sendable, Hashable {
    public var feedURL: String
    public var siteURL: String?
    public var iconURL: String?

    public init(feedURL: String, siteURL: String? = nil, iconURL: String? = nil) {
        self.feedURL = feedURL
        self.siteURL = siteURL
        self.iconURL = iconURL
    }
}

extension FeedFetcher {
    static let maxIconBytes = 512 * 1024
    static let maxPageBytes = 256 * 1024

    /// Icons found, keyed by feed URL; feeds without a usable icon are absent. At most `maxConcurrent` lookups at a time.
    public func fetchIcons(_ requests: [IconRequest], maxConcurrent: Int = 6) async -> [String: Data] {
        let byFeed = Dictionary(requests.map { ($0.feedURL, $0) }, uniquingKeysWith: { first, _ in first })
        let found = await concurrently(Array(byFeed.keys), maxConcurrent: maxConcurrent) { key in
            await self.fetchIcon(byFeed[key]!)
        }
        return found.compactMapValues { $0 }
    }

    /// First readable image among: the icon declared by the feed, the icons declared by the site's home page,
    /// then `/favicon.ico` at the site's origin.
    public func fetchIcon(_ request: IconRequest) async -> Data? {
        guard let feedURL = URL(string: request.feedURL) else { return nil }
        if let declared = request.iconURL.flatMap({ URL(string: $0, relativeTo: feedURL)?.absoluteURL }),
           let data = await image(at: declared) {
            return data
        }
        let site = request.siteURL.flatMap { URL(string: $0, relativeTo: feedURL)?.absoluteURL } ?? Self.origin(of: feedURL)
        if let site, let (page, pageURL) = await download(site, limit: Self.maxPageBytes, truncate: true) {
            let html = String(decoding: page, as: UTF8.self)
            for url in FeedIcon.declaredIcons(inHTML: html, baseURL: pageURL) {
                if let data = await image(at: url) { return data }
            }
        }
        guard let origin = Self.origin(of: site ?? feedURL) else { return nil }
        return await image(at: origin.appending(path: "favicon.ico"))
    }

    private func image(at url: URL) async -> Data? {
        guard let (data, _) = await download(url, limit: Self.maxIconBytes, truncate: false),
              let image = NSImage(data: data), image.isValid else { return nil }
        return data
    }

    /// GET over http(s) only. Returns nil on any failure, or when the body exceeds `limit` and `truncate` is false.
    private func download(_ url: URL, limit: Int, truncate: Bool) async -> (Data, URL)? {
        guard ["http", "https"].contains(url.scheme?.lowercased()) else { return nil }
        do {
            let (bytes, response) = try await session.bytes(for: URLRequest(url: url, timeoutInterval: 20))
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else { return nil }
            var data = Data()
            for try await byte in bytes {
                guard data.count < limit else {
                    if truncate { break } else { return nil }
                }
                data.append(byte)
            }
            return (data, response.url ?? url)
        } catch {
            return nil
        }
    }

    private static func origin(of url: URL) -> URL? {
        var parts = URLComponents()
        parts.scheme = url.scheme
        parts.host = url.host()
        parts.port = url.port
        parts.path = "/"
        return parts.host == nil ? nil : parts.url
    }
}
