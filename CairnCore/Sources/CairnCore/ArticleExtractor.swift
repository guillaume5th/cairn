import Foundation
import WebKit

/// The main content of an article's web page, as Firefox's Reader View finds it.
public struct ExtractedArticle: Sendable, Equatable {
    public var title: String?
    /// Cleaned HTML: no navigation, ads, comments or scripts. Links and images keep absolute URLs.
    public var content: String
    public var siteName: String?
}

/// Downloads an article's page and extracts its main content with Mozilla's Readability.
public enum ArticleExtractor {
    static let maxBytes = 5 * 1024 * 1024

    /// No cookies, no cache, a browser-like User-Agent (some sites refuse unknown clients).
    public static let session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieAcceptPolicy = .never
        config.httpShouldSetCookies = false
        config.urlCache = nil
        config.timeoutIntervalForRequest = 20
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml",
        ]
        return URLSession(configuration: config)
    }()

    @MainActor
    public static func extract(from url: URL, session: URLSession = session) async throws -> ExtractedArticle {
        guard ["http", "https"].contains(url.scheme?.lowercased()) else { throw CairnError.invalidURL }
        let (bytes, response) = try await session.bytes(for: URLRequest(url: url, timeoutInterval: 20))
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw CairnError.httpStatus(http.statusCode)
        }
        var data = Data()
        for try await byte in bytes {
            guard data.count < maxBytes else { throw CairnError.noArticleContent }
            data.append(byte)
        }
        return try await extract(html: decode(data, encodingName: response.textEncodingName), baseURL: response.url ?? url)
    }

    /// Readability on `html`, parsed by `DOMParser`: it neither runs the page's scripts nor loads anything.
    /// Our script runs in its own JavaScript world of an empty page that has page scripts disabled.
    @MainActor
    public static func extract(html: String, baseURL: URL) async throws -> ExtractedArticle {
        var config = WebPage.Configuration()
        config.defaultNavigationPreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        let page = WebPage(configuration: config)
        for try await _ in page.load(html: "<!doctype html><title></title>", baseURL: URL(string: "about:blank")!) {}
        let result = try await page.callJavaScript(script, arguments: ["html": html, "url": baseURL.absoluteString],
                                                   contentWorld: .defaultClient)
        guard let json = result as? String, let data = json.data(using: .utf8),
              let parsed = try? JSONDecoder().decode(Parsed.self, from: data),
              let content = parsed.content, !(parsed.textContent ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { throw CairnError.noArticleContent }
        return ExtractedArticle(title: parsed.title.flatMap { $0.isEmpty ? nil : $0 }, content: content,
                                siteName: parsed.siteName.flatMap { $0.isEmpty ? nil : $0 })
    }

    private struct Parsed: Decodable {
        var title: String?
        var content: String?
        var textContent: String?
        var siteName: String?
    }

    /// The charset the server declares, else the page's `<meta charset>`, else UTF-8.
    static func decode(_ data: Data, encodingName: String?) -> String {
        let declared = encodingName ?? String(decoding: data.prefix(2048), as: UTF8.self)
            .firstMatch(of: /<meta[^>]+charset=["']?([A-Za-z0-9_-]+)/.ignoresCase()).map { String($0.output.1) }
        if let declared {
            let cf = CFStringConvertIANACharSetNameToEncoding(declared as CFString)
            if cf != kCFStringEncodingInvalidId,
               let text = String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cf))) {
                return text
            }
        }
        return String(decoding: data, as: UTF8.self)
    }

    private static let script: String = {
        let url = Bundle.module.url(forResource: "Readability", withExtension: "js")!
        let library = try! String(contentsOf: url, encoding: .utf8)
        return library + """

            const doc = new DOMParser().parseFromString(html, "text/html");
            // Relative links and images resolve against the article's address.
            const base = doc.createElement("base");
            base.href = url;
            doc.head.prepend(base);
            const article = new Readability(doc).parse();
            if (!article) return null;
            // Readability falls back to the whole page: a short text, or one mostly made of links (a home page,
            // an index), is not an article.
            const body = doc.createElement("div");
            body.innerHTML = article.content;
            const text = body.textContent.trim().length;
            const linked = [...body.querySelectorAll("a")].reduce((n, a) => n + a.textContent.trim().length, 0);
            if (text < 250 || linked > text / 2) return null;
            return JSON.stringify(article);
            """
    }()
}
