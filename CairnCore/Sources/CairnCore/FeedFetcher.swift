import Foundation

public struct FeedFetcher: Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch(_ url: URL) async throws -> ParsedFeed {
        // A refresh must reach the server: heuristic HTTP caching would otherwise hide new items.
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        let (data, response) = try await session.data(for: request)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw CairnError.httpStatus(http.statusCode)
        }
        return try FeedParser.parse(data)
    }

    /// Fetches every URL, at most `maxConcurrent` at a time. One failing feed never affects the others.
    public func fetchAll(_ urls: [String], maxConcurrent: Int = 6) async -> [String: Result<ParsedFeed, any Error>] {
        var results: [String: Result<ParsedFeed, any Error>] = [:]
        await withTaskGroup(of: (String, Result<ParsedFeed, any Error>).self) { group in
            var pending = urls[...]
            for _ in 0..<maxConcurrent {
                guard let url = pending.popFirst() else { break }
                group.addTask { (url, await result(url)) }
            }
            for await (url, result) in group {
                results[url] = result
                if let next = pending.popFirst() {
                    group.addTask { (next, await self.result(next)) }
                }
            }
        }
        return results
    }

    private func result(_ urlString: String) async -> Result<ParsedFeed, any Error> {
        do {
            guard let url = URL(string: urlString) else { throw CairnError.invalidURL }
            return .success(try await fetch(url))
        } catch {
            return .failure(error)
        }
    }
}
