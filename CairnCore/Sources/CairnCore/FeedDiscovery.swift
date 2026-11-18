import Foundation

/// A feed found at an address the user typed: the address itself, one declared by its page, or a usual path of its site.
public struct DiscoveredFeed: Sendable, Hashable, Identifiable {
    public var url: String
    /// The `<link>`'s title, or the feed's own title when the address was the feed; nil when unknown.
    public var title: String?

    public var id: String { url }

    public init(url: String, title: String? = nil) {
        self.url = url
        self.title = title
    }
}

extension Library {
    /// The http(s) URL the user means: surrounding spaces dropped, `https://` added when there is no scheme.
    public static func normalizedURL(_ input: String) throws -> URL {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let full = trimmed.contains("://") ? trimmed : "https://" + trimmed
        guard let url = URL(string: full), ["http", "https"].contains(url.scheme?.lowercased()),
              let host = url.host(), host.contains(".") || host == "localhost" else {
            throw CairnError.invalidURL
        }
        return url
    }

    /// Feeds at `input`: the address itself when it is a feed, else the feeds its page declares, else the first
    /// usual feed path of its site that answers a feed. Throws `noFeedFound` when there is none.
    public static func discoverFeeds(urlString input: String, fetcher: FeedFetcher) async throws -> [DiscoveredFeed] {
        let url = try normalizedURL(input)
        let (data, finalURL) = try await fetcher.download(url)
        if let parsed = try? FeedParser.parse(data) {
            return [DiscoveredFeed(url: url.absoluteString, title: parsed.title.isEmpty ? nil : parsed.title)]
        }
        let declared = declaredFeeds(inHTML: String(decoding: data, as: UTF8.self), baseURL: finalURL)
        if !declared.isEmpty { return declared }
        if let found = await fetcher.firstFeed(atUsualPathsOf: finalURL) { return [found] }
        throw CairnError.noFeedFound
    }

    /// Plain `application/json` is left out: WordPress declares its REST API with it.
    static let feedTypes: Set<String> = ["application/rss+xml", "application/atom+xml", "application/feed+json"]

    /// `<link rel="alternate">` feeds of the page (not only its head, YouTube puts them in the body), in document order, without duplicates.
    static func declaredFeeds(inHTML html: String, baseURL: URL) -> [DiscoveredFeed] {
        var seen: Set<String> = []
        return HTMLHead.links(in: html, baseURL: baseURL, wholePage: true).compactMap { link in
            guard link.rel.contains("alternate"), let type = link.type, feedTypes.contains(type),
                  ["http", "https"].contains(link.href.scheme?.lowercased()),
                  seen.insert(link.href.absoluteString).inserted else { return nil }
            return DiscoveredFeed(url: link.href.absoluteString, title: link.title)
        }
    }
}

extension FeedFetcher {
    static let usualFeedPaths = ["feed", "rss", "rss.xml", "feed.xml", "atom.xml", "index.xml"]

    /// The first usual path, in `usualFeedPaths` order, at the site's origin that answers a feed. Tried 3 at a time.
    func firstFeed(atUsualPathsOf page: URL) async -> DiscoveredFeed? {
        guard let host = page.host() else { return nil }
        var origin = URLComponents()
        origin.scheme = page.scheme
        origin.host = host
        origin.port = page.port
        guard let base = origin.url else { return nil }
        let candidates = Self.usualFeedPaths.map { base.appending(path: $0).absoluteString }
        let results = await concurrently(candidates, maxConcurrent: 3) { candidate -> String?? in
            guard let url = URL(string: candidate), let parsed = try? await self.fetch(url, timeout: 10) else { return nil }
            return .some(parsed.title.isEmpty ? nil : parsed.title)
        }
        return candidates.lazy.compactMap { candidate in
            results[candidate].flatMap { $0 }.map { DiscoveredFeed(url: candidate, title: $0) }
        }.first
    }
}

extension Library {
    /// The address a `feed:` link points to: what follows `feed:` (`feed:https://x/rss`), or after `feed://` the
    /// address without its scheme (`feed://x/rss` gives `x/rss`, completed in https like a typed address).
    public static func address(fromFeedLink url: URL) -> String? {
        guard url.scheme?.lowercased() == "feed" else { return nil }
        var rest = url.absoluteString.dropFirst("feed:".count)
        if rest.hasPrefix("//") { rest = rest.dropFirst(2) }
        return rest.isEmpty ? nil : String(rest)
    }
}
