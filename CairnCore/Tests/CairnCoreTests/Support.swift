import CairnCore
import Foundation
import SwiftData
import Testing

func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

/// Serves fixtures by host: rss.test -> rss.xml, atom.test -> atom.xml, html.test -> HTML page,
/// fresh.test -> rss.xml only for cache-bypassing requests; anything else -> HTTP 500.
final class StubProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        let (status, body): (Int, Data) = switch url.host() {
        case "rss.test": (200, (try? fixture("rss.xml")) ?? Data())
        case "atom.test": (200, (try? fixture("atom.xml")) ?? Data())
        case "html.test": (200, Data("<html><body>Pas un flux</body></html>".utf8))
        case "fresh.test" where request.cachePolicy == .reloadIgnoringLocalCacheData: (200, (try? fixture("rss.xml")) ?? Data())
        default: (500, Data())
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

let stubFetcher: FeedFetcher = {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubProtocol.self]
    return FeedFetcher(session: URLSession(configuration: config))
}()

/// Fixtures are dated 2026-11-09, so tests use a "now" two days later.
let fixtureNow = ISO8601DateFormatter().date(from: "2026-11-11T10:00:00Z")!

/// A ModelContext does not retain its container, so test containers are kept alive here.
@MainActor private var liveContainers: [ModelContainer] = []

@MainActor
func makeContext() throws -> ModelContext {
    let container = try CairnStore.container(inMemory: true)
    liveContainers.append(container)
    return container.mainContext
}
