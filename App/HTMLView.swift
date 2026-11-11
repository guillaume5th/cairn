import AppKit
import SwiftUI
import WebKit

/// Renders feed-provided HTML: no JavaScript, only remote images allowed, every link opens in the default browser.
struct HTMLView: View {
    let html: String
    let baseURL: URL?
    /// Search term to highlight in the content; empty removes the highlights.
    var query = ""
    @State private var page: WebPage?
    @AppStorage(TextScale.key) private var textScale = 1.0

    private struct Load: Equatable { let html: String, scale: Double }

    var body: some View {
        // Color.clear holds the layout (and runs .task) until the page exists.
        ZStack {
            Color.clear
            if let page { WebView(page) }
        }
        .task(id: Load(html: html, scale: textScale)) {
            let page = page ?? Self.makePage()
            self.page = page
            do {
                for try await _ in page.load(html: Self.page(html, scale: textScale), baseURL: baseURL ?? URL(string: "about:blank")!) {}
                await Self.highlight(query, in: page)
            } catch {
                // A failed load of our own string leaves the view blank; there is nothing to retry.
            }
        }
        .onChange(of: query) {
            guard let page else { return }
            Task { await Self.highlight(query, in: page) }
        }
    }

    /// Wraps every occurrence of the query (ignoring case and accents, like the search) in `<mark>` and scrolls to
    /// the first. It is the app's own script, run in its own world: the feed's scripts stay disabled.
    private static func highlight(_ query: String, in page: WebPage) async {
        _ = try? await page.callJavaScript(highlightScript, arguments: ["query": query], contentWorld: .defaultClient)
    }

    private static let highlightScript = """
        document.querySelectorAll('mark[data-cairn]').forEach(mark => mark.replaceWith(...mark.childNodes));
        document.body.normalize();
        const fold = s => s.normalize('NFD').replace(/[\\u0300-\\u036f]/g, '').toLowerCase();
        const needle = fold(query.trim());
        if (!needle) return 0;
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
            acceptNode: n => ['SCRIPT', 'STYLE', 'NOSCRIPT'].includes(n.parentNode.nodeName)
                ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT
        });
        const nodes = [];
        while (walker.nextNode()) nodes.push(walker.currentNode);
        let first = null, count = 0;
        for (const node of nodes) {
            // Folded text with, for each folded character, its index in the original text.
            let folded = '', origin = [];
            for (let i = 0; i < node.data.length; i++) {
                for (const c of fold(node.data[i])) { folded += c; origin.push(i); }
            }
            const found = [];
            for (let at = folded.indexOf(needle); at !== -1; at = folded.indexOf(needle, at + needle.length)) {
                found.push([origin[at], origin[at + needle.length - 1] + 1]);
            }
            // Back to front: wrapping splits the node after the match, so earlier offsets stay valid.
            for (let k = found.length - 1; k >= 0; k--) {
                const range = document.createRange();
                range.setStart(node, found[k][0]);
                range.setEnd(node, found[k][1]);
                const mark = document.createElement('mark');
                mark.dataset.cairn = '';
                range.surroundContents(mark);
                count++;
                if (k === 0 && !first) first = mark;
            }
        }
        if (first) first.scrollIntoView({ block: 'center' });
        return count;
        """

    private static func makePage() -> WebPage {
        var config = WebPage.Configuration()
        config.defaultNavigationPreferences.allowsContentJavaScript = false
        config.websiteDataStore = .nonPersistent()
        return WebPage(configuration: config, navigationDecider: LinkOpener())
    }

    static func page(_ body: String, scale: Double = 1) -> String {
        """
        <!doctype html><html><head><meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: data:; style-src 'unsafe-inline'">
        <style>
        :root { color-scheme: light dark; }
        body { font: -apple-system-body; font-size: \(15 * scale)px; line-height: 1.55; max-width: 42em; margin: 16px auto; padding: 0 20px; }
        img, video { max-width: 100%; height: auto; }
        pre { overflow-x: auto; }
        mark { background: rgba(255, 204, 0, 0.45); color: inherit; border-radius: 2px; }
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
