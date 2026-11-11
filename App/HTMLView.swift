import AppKit
import SwiftUI
import WebKit

/// Renders feed-provided HTML: no JavaScript, only remote images allowed, every link opens in the default browser.
struct HTMLView: View {
    let html: String
    let baseURL: URL?
    @State private var page: WebPage?

    var body: some View {
        // Color.clear holds the layout (and runs .task) until the page exists.
        ZStack {
            Color.clear
            if let page { WebView(page) }
        }
        .task(id: html) {
            let page = page ?? Self.makePage()
            self.page = page
            do {
                for try await _ in page.load(html: Self.page(html), baseURL: baseURL ?? URL(string: "about:blank")!) {}
            } catch {
                // A failed load of our own string leaves the view blank; there is nothing to retry.
            }
        }
    }

    private static func makePage() -> WebPage {
        var config = WebPage.Configuration()
        config.defaultNavigationPreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        return WebPage(configuration: config, navigationDecider: LinkOpener())
    }

    static func page(_ body: String) -> String {
        """
        <!doctype html><html><head><meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: data:; style-src 'unsafe-inline'">
        <style>
        :root { color-scheme: light dark; }
        body { font: -apple-system-body; font-size: 15px; line-height: 1.55; max-width: 42em; margin: 16px auto; padding: 0 20px; }
        img, video { max-width: 100%; height: auto; }
        pre { overflow-x: auto; }
        </style></head><body>\(body)</body></html>
        """
    }
}

/// Lets only our own HTML load; a clicked link opens in the browser, anything else is cancelled.
private struct LinkOpener: WebPage.NavigationDeciding {
    func decidePolicy(for action: WebPage.NavigationAction,
                      preferences: inout WebPage.NavigationPreferences) async -> WKNavigationActionPolicy {
        switch action.navigationType {
        case .other:
            return .allow // our own load(html:)
        case .linkActivated:
            if let url = action.request.url { NSWorkspace.shared.open(url) }
            return .cancel
        default:
            return .cancel
        }
    }
}
