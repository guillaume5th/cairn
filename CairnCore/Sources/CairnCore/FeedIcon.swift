import Foundation
import ImageIO

/// Finding a feed's site icon (favicon).
public enum FeedIcon {
    /// Icon URLs declared by `<link rel="…icon…">` in the page head, resolved against `baseURL`, best first:
    /// `apple-touch-icon` (large and opaque, made to be masked), then by declared `sizes`, largest first;
    /// ties keep document order.
    public static func declaredIcons(inHTML html: String, baseURL: URL) -> [URL] {
        let icons = HTMLHead.links(in: html, baseURL: baseURL).compactMap { link -> (url: URL, touch: Bool, size: Int)? in
            guard link.rel.contains(where: iconRels.contains) else { return nil }
            return (link.href, link.rel.contains { $0.hasPrefix("apple-touch-icon") }, largestSize(link.sizes))
        }
        // sorted(by:) is not stable: the index breaks ties to keep document order.
        return icons.enumerated()
            .sorted { ($0.element.touch ? 1 : 0, $0.element.size, -$0.offset) > ($1.element.touch ? 1 : 0, $1.element.size, -$1.offset) }
            .map(\.element.url)
    }

    /// Largest width in a `sizes` attribute ("16x16 32x32"); "any" (vector) beats every size; absent is 0.
    private static func largestSize(_ sizes: String?) -> Int {
        guard let sizes = sizes?.lowercased() else { return 0 }
        if sizes.split(separator: " ").contains("any") { return .max }
        return sizes.split(separator: " ").compactMap { $0.split(separator: "x").first.flatMap { Int($0) } }.max() ?? 0
    }

    // `mask-icon` is excluded: it is a monochrome Safari pinned-tab mask, not a favicon.
    private static let iconRels: Set<Substring> = ["icon", "apple-touch-icon", "apple-touch-icon-precomposed"]

    /// The largest image in `data` (an .ico holds several sizes), or nil when it cannot be decoded.
    public static func decode(_ data: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }
        let images = (0..<CGImageSourceGetCount(source)).compactMap { CGImageSourceCreateImageAtIndex(source, $0, nil) }
        return images.max { $0.width < $1.width }
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
    /// then `/apple-touch-icon.png` and `/favicon.ico` at the site's origin.
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
        for path in ["apple-touch-icon.png", "favicon.ico"] {
            if let data = await image(at: origin.appending(path: path)) { return data }
        }
        return nil
    }

    private func image(at url: URL) async -> Data? {
        guard let (data, _) = await download(url, limit: Self.maxIconBytes, truncate: false),
              let image = FeedIcon.decode(data), Self.isVisible(image) else { return nil }
        return data
    }

    /// Some sites serve a near-transparent "ghost" icon; one that has no pixel at least half opaque is unreadable.
    static func isVisible(_ image: CGImage) -> Bool {
        let side = 64
        let rect = CGRect(x: 0, y: 0, width: side, height: side)
        guard let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: side * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
        context.draw(image, in: rect)
        guard let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else { return false }
        return (0..<side * side).contains { pixels[$0 * 4 + 3] >= 128 }
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
