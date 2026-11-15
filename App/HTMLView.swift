import AppKit
import SwiftUI
import WebKit

/// Renders feed-provided HTML: no JavaScript, only remote images allowed, every link opens in the default browser.
struct HTMLView: View {
    let html: String
    let baseURL: URL?
    /// Search term to highlight in the content; empty removes the highlights.
    var query = ""
    /// Passages quoted in the article's note, highlighted at their first occurrence.
    var quotes: [String] = []
    /// Owned by the caller, which reads the text selection from it.
    @Binding var page: WebPage?
    @AppStorage(TextScale.key) private var textScale = 1.0
    /// How far the article is scrolled, 0 to 1; nil when it fits in the pane. Owned by the caller, which shows it
    /// under the header, above the summary.
    @Binding var progress: Double?

    private struct Load: Equatable { let html: String, scale: Double }

    var body: some View {
        // Color.clear holds the layout (and runs .task) until the page exists.
        ZStack {
            Color.clear
            if let page {
                WebView(page)
                    .webViewOnScrollGeometryChange(for: Double?.self, of: Self.progress) { _, new in progress = new }
            }
        }
        .task(id: Load(html: html, scale: textScale)) {
            let page = page ?? Self.makePage()
            self.page = page
            do {
                for try await _ in page.load(html: Self.page(html, scale: textScale), baseURL: baseURL ?? URL(string: "about:blank")!) {}
                await Self.highlight(query, quotes: quotes, scrollsToQuery: true, in: page)
            } catch {
                // A failed load of our own string leaves the view blank; there is nothing to retry.
            }
        }
        .onChange(of: query) {
            guard let page else { return }
            Task { await Self.highlight(query, quotes: quotes, scrollsToQuery: true, in: page) }
        }
        .onChange(of: quotes) {
            guard let page else { return }
            Task { await Self.highlight(query, quotes: quotes, scrollsToQuery: false, in: page) }
        }
    }

    /// The scrolled fraction of the content, in steps of 0.5% so that each scrolled pixel does not redraw the bar.
    private static func progress(_ geometry: ScrollGeometry) -> Double? {
        let scrollable = geometry.contentSize.height - geometry.visibleRect.height
        guard scrollable > 1 else { return nil }
        let fraction = min(max(Double(geometry.visibleRect.minY / scrollable), 0), 1)
        return (fraction * 200).rounded() / 200
    }

    /// The text selected in the page, read by the app's own script like the highlight.
    static func selection(in page: WebPage) async -> String {
        (try? await page.callJavaScript("return window.getSelection().toString()", contentWorld: .defaultClient)) as? String ?? ""
    }

    /// Highlights the query, then the quotes. The query's script matches within one text node, so it runs with the
    /// quotes' marks removed: they split the text. The app's own scripts, run in their own world: the feed's scripts
    /// stay disabled.
    private static func highlight(_ query: String, quotes: [String], scrollsToQuery: Bool, in page: WebPage) async {
        _ = try? await page.callJavaScript(quoteScript, arguments: ["quotes": [String]()], contentWorld: .defaultClient)
        _ = try? await page.callJavaScript(highlightScript, arguments: ["query": query, "scrolls": scrollsToQuery],
                                           contentWorld: .defaultClient)
        _ = try? await page.callJavaScript(quoteScript, arguments: ["quotes": quotes], contentWorld: .defaultClient)
    }

    /// Wraps the first occurrence of each quote in `<mark data-cairn-quote>`, one per text node it spans: a passage
    /// crosses links and paragraphs, which a single `<mark>` cannot wrap. Whitespace is ignored on both sides, since
    /// the selection's line breaks between blocks have no counterpart in the text nodes.
    private static let quoteScript = """
        document.querySelectorAll('mark[data-cairn-quote]').forEach(mark => mark.replaceWith(...mark.childNodes));
        document.body.normalize();
        const fold = s => s.normalize('NFD').replace(/[\\u0300-\\u036f]/g, '').toLowerCase();
        const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT, {
            acceptNode: n => ['SCRIPT', 'STYLE', 'NOSCRIPT'].includes(n.parentNode.nodeName)
                ? NodeFilter.FILTER_REJECT : NodeFilter.FILTER_ACCEPT
        });
        const nodes = [];
        while (walker.nextNode()) nodes.push(walker.currentNode);
        // The whole text folded and without whitespace, with, for each character, its node and offset.
        let text = '', origin = [];
        nodes.forEach((node, n) => {
            for (let i = 0; i < node.data.length; i++) {
                for (const c of fold(node.data[i])) if (!/\\s/.test(c)) { text += c; origin.push([n, i]); }
            }
        });
        const segments = [];
        for (const quote of quotes) {
            const needle = fold(quote).replace(/\\s+/g, '');
            const at = needle ? text.indexOf(needle) : -1;
            if (at === -1) continue;
            const [first, start] = origin[at], [last, end] = origin[at + needle.length - 1];
            for (let n = first; n <= last; n++) {
                const s = n === first ? start : 0, e = n === last ? end + 1 : nodes[n].data.length;
                if (nodes[n].data.slice(s, e).trim()) segments.push([n, s, e]);
            }
        }
        // Back to front within a node, so that wrapping keeps earlier offsets valid; overlapping quotes are skipped.
        segments.sort((a, b) => a[0] - b[0] || b[1] - a[1]);
        let previous = null;
        for (const [n, s, e] of segments) {
            if (previous && previous[0] === n && e > previous[1]) continue;
            const range = document.createRange();
            range.setStart(nodes[n], s);
            range.setEnd(nodes[n], e);
            const mark = document.createElement('mark');
            mark.dataset.cairnQuote = '';
            range.surroundContents(mark);
            previous = [n, s];
        }
        """

    /// Wraps every occurrence of the query (ignoring case and accents, like the search) in `<mark>`, scrolling to the
    /// first unless only the quotes changed.
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
        if (first && scrolls) first.scrollIntoView({ block: 'center' });
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
        /* The system's monospaced font and accent color, instead of WebKit's Courier and fixed blue. */
        pre, code, kbd, samp { font-family: ui-monospace; }
        a { color: AccentColor; }
        mark { background: rgba(255, 204, 0, 0.45); color: inherit; border-radius: 2px; }
        mark[data-cairn-quote] { background: rgba(0, 122, 255, 0.18); }
        @media (prefers-color-scheme: dark) { mark[data-cairn-quote] { background: rgba(10, 132, 255, 0.35); } }
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
            if let url = action.request.url {
                NSWorkspace.shared.open(url)
            }
            return .cancel
        default:
            return .cancel
        }
    }
}
