import Foundation

public struct FeedFetcher: Sendable {
    public typealias Credentials = @Sendable (_ host: String) -> (user: String, password: String)?

    let session: URLSession
    /// Identifier and password of a site, sent as HTTP Basic to every request to it.
    let credentials: Credentials

    public init(session: URLSession = .shared, credentials: @escaping Credentials = { _ in nil }) {
        self.session = session
        self.credentials = credentials
    }

    public func fetch(_ url: URL, timeout: TimeInterval = 20) async throws -> ParsedFeed {
        try FeedParser.parse(try await download(url, timeout: timeout).data)
    }

    /// The body and the final URL (after redirects); an HTTP error status throws.
    func download(_ url: URL, timeout: TimeInterval = 20) async throws -> (data: Data, url: URL) {
        // A refresh must reach the server: heuristic HTTP caching would otherwise hide new items.
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        let delegate = Self.authorize(&request, login: url.host().flatMap(credentials))
        let (data, response) = try await session.data(for: request, delegate: delegate)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw CairnError.httpStatus(http.statusCode)
        }
        return (data, response.url ?? url)
    }

    /// Adds the site's login as HTTP Basic; the returned delegate, to pass with the request, drops it on a
    /// redirection to another site.
    static func authorize(_ request: inout URLRequest, login: (user: String, password: String)?) -> (any URLSessionTaskDelegate)? {
        guard let login else { return nil }
        let token = Data("\(login.user):\(login.password)".utf8).base64EncodedString()
        request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        return KeepsLoginOnHost()
    }

    /// Drops the login when a redirection leaves the site it belongs to.
    private final class KeepsLoginOnHost: NSObject, URLSessionTaskDelegate {
        func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                        newRequest request: URLRequest) async -> URLRequest? {
            var request = request
            if request.url?.host() != task.originalRequest?.url?.host() {
                request.setValue(nil, forHTTPHeaderField: "Authorization")
            }
            return request
        }
    }

    /// Fetches every URL, at most `maxConcurrent` at a time. One failing feed never affects the others.
    public func fetchAll(_ urls: [String], maxConcurrent: Int = 6) async -> [String: Result<ParsedFeed, any Error>] {
        await concurrently(urls, maxConcurrent: maxConcurrent) { await self.result($0) }
    }

    /// Runs `work` for every key, at most `maxConcurrent` at a time.
    func concurrently<T: Sendable>(_ keys: [String], maxConcurrent: Int,
                                   _ work: @escaping @Sendable (String) async -> T) async -> [String: T] {
        var results: [String: T] = [:]
        await withTaskGroup(of: (String, T).self) { group in
            var pending = keys[...]
            for _ in 0..<maxConcurrent {
                guard let key = pending.popFirst() else { break }
                group.addTask { (key, await work(key)) }
            }
            for await (key, value) in group {
                results[key] = value
                if let next = pending.popFirst() {
                    group.addTask { (next, await work(next)) }
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
