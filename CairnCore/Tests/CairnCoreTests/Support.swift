import AppKit
import CairnCore
import Foundation
import Synchronization
import SwiftData
import Testing

func fixture(_ name: String) throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: nil, subdirectory: "Fixtures"))
    return try Data(contentsOf: url)
}

/// Serves fixtures by host: rss.test -> rss.xml, atom.test -> atom.xml, html.test -> HTML page,
/// fresh.test -> rss.xml only for cache-bypassing requests; anything else -> HTTP 500.
/// Icon sites: see `iconRoutes`. Every request is counted in `StubProtocol.requests`.
final class StubProtocol: URLProtocol {
    static let requests = Mutex<[URL]>([])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        Self.requests.withLock { $0.append(url) }
        let (status, body): (Int, Data) = if let route = iconRoutes["\(url.host() ?? "")\(url.path())"] {
            (200, route)
        } else if iconHosts.contains(url.host() ?? "") {
            (404, Data())
        } else {
            switch url.host() {
            case "rss.test": (200, (try? fixture("rss.xml")) ?? Data())
            case "atom.test": (200, (try? fixture("atom.xml")) ?? Data())
            case "html.test": (200, Data("<html><body>Pas un flux</body></html>".utf8))
            case "fresh.test" where request.cachePolicy == .reloadIgnoringLocalCacheData: (200, (try? fixture("rss.xml")) ?? Data())
            default: (500, Data())
            }
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!,
                            cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

/// A valid PNG of `side`×`side` pixels; different sides give different data.
func pngData(side: Int) -> Data {
    let context = CGContext(data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    context.setFillColor(red: 0.2, green: 0.4, blue: 0.9, alpha: 1)
    context.fill(CGRect(x: 0, y: 0, width: side, height: side))
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, context.makeImage()!, nil)
    CGImageDestinationFinalize(destination)
    return data as Data
}

let declaredIcon = pngData(side: 2)
let pageIcon = pngData(side: 3)
let conventionalIcon = pngData(side: 4)
/// Decodable, but over the 512 KB limit.
let oversizedIcon = pngData(side: 5) + Data(count: 600_000)

func page(_ head: String) -> Data { Data("<html><head>\(head)</head><body></body></html>".utf8) }

/// Icon lookup sites, keyed by host + path. Unlisted paths on these hosts answer 404.
/// - atom.example: icon declared by atom.xml
/// - rss.example (site of rss.xml): home page declares an icon
/// - ico.test: no declared icon, only /favicon.ico
/// - bad.test: declared icon unreadable, /favicon.ico fine
/// - big.test: declared icon too large, no /favicon.ico
/// - none.test: nothing at all
/// - count.test: only /favicon.ico; reserved for tests counting requests
let iconRoutes: [String: Data] = [
    "atom.example/icon.png": declaredIcon,
    "rss.example/": page(#"<link rel="shortcut icon" href="/static/icon.png">"#),
    "rss.example/static/icon.png": pageIcon,
    "ico.test/": page("<title>Sans icône</title>"),
    "ico.test/favicon.ico": conventionalIcon,
    "bad.test/": page(#"<link rel="icon" href="/broken.png">"#),
    "bad.test/broken.png": Data("pas une image".utf8),
    "bad.test/favicon.ico": conventionalIcon,
    "big.test/": page(#"<link rel="icon" href="/big.png">"#),
    "big.test/big.png": oversizedIcon,
    "count.test/favicon.ico": conventionalIcon,
]
let iconHosts: Set<String> = ["atom.example", "rss.example", "ico.test", "bad.test", "big.test", "none.test", "count.test"]

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
