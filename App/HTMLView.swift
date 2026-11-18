import AppKit
import CairnCore
import Observation
import QuickLook
import SwiftUI
import UniformTypeIdentifiers
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
    /// The article's images in Quick Look, opened by a click on one of them.
    @State private var quickLook = ImageQuickLook()

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
        .quickLookPreview($quickLook.selected, in: quickLook.urls)
        .onDisappear { quickLook.close() }
        .task(id: Load(html: html, scale: textScale)) {
            quickLook.close() // another article: its images are not these
            let quickLook = quickLook
            let page = page ?? Self.makePage { index, sources in quickLook.open(index: index, of: sources) }
            self.page = page
            do {
                for try await _ in page.load(html: Self.page(html, scale: textScale), baseURL: baseURL ?? URL(string: "about:blank")!) {}
                // Injected here, not as a user script: those do not run while the page's own JavaScript is off.
                _ = try? await page.callJavaScript(Self.imageClickScript, contentWorld: .defaultClient)
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

    /// A click on an image that is not a link, sent to the app by its own script (run in the app's world, so the
    /// article's scripts stay off and cannot see it): the image's place among the page's images, and their sources.
    private static let imageClickScript = """
        document.addEventListener('click', event => {
            const image = event.target.closest('img');
            if (!image || image.closest('a')) return;
            const images = Array.from(document.images);
            window.webkit.messageHandlers.cairnImage.postMessage({
                index: images.indexOf(image), sources: images.map(i => i.currentSrc || i.src)
            });
        });
        """

    private static func makePage(onImageClick: @escaping @MainActor (Int, [String]) -> Void) -> WebPage {
        var config = WebPage.Configuration()
        config.userContentController.add(ImageClickHandler(onClick: onImageClick), contentWorld: .defaultClient, name: "cairnImage")
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
        img { cursor: zoom-in; }
        a img { cursor: pointer; }
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

/// Receives the image clicks of the app's own script; the message comes from a page of a feed, so it is checked.
@MainActor
private final class ImageClickHandler: NSObject, WKScriptMessageHandler {
    let onClick: @MainActor (Int, [String]) -> Void

    init(onClick: @escaping @MainActor (Int, [String]) -> Void) { self.onClick = onClick }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? [String: Any], let index = body["index"] as? Int,
              let sources = body["sources"] as? [String], sources.indices.contains(index) else { return }
        onClick(index, sources)
    }
}

/// Downloads the images of an article to a temporary folder and shows them in Quick Look, the clicked one first.
@MainActor @Observable
final class ImageQuickLook {
    /// The image Quick Look shows; setting it nil (or Quick Look closing) ends the preview.
    var selected: URL?
    @ObservationIgnored private(set) var urls: [URL] = []
    @ObservationIgnored private var folder: URL?
    @ObservationIgnored private var task: Task<Void, Never>?

    private static let session = URLSession(configuration: .ephemeral)
    /// Per image: a page's images are not huge, and Quick Look would load a giant one at full size.
    private static let maxBytes = 20 * 1024 * 1024

    func open(index: Int, of sources: [String]) {
        close()
        let images = Library.quickLookImages(sources)
        guard let clicked = images.first(where: { $0.url.absoluteString == URL(string: sources[index])?.absoluteString }) else {
            NSSound.beep() // an address Quick Look is not allowed to fetch (http:, a script…)
            return
        }
        let folder = FileManager.default.temporaryDirectory.appending(path: "Cairn-QuickLook/\(UUID().uuidString)")
        self.folder = folder
        task = Task {
            guard (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)) != nil,
                  let first = await Self.save(clicked, in: folder), !Task.isCancelled else { return }
            urls = [first]
            selected = first
            // The others come after, in page order, so that Quick Look opens without waiting for all of them.
            var all: [URL] = []
            for image in images {
                if image == clicked { all.append(first) } else if let file = await Self.save(image, in: folder) { all.append(file) }
            }
            guard !Task.isCancelled else { return }
            urls = all
        }
    }

    /// Ends the preview and deletes what was downloaded.
    func close() {
        task?.cancel()
        task = nil
        selected = nil
        urls = []
        if let folder { try? FileManager.default.removeItem(at: folder) }
        folder = nil
    }

    /// The image saved in `folder`, or nil when it cannot be fetched, is too big or is not an image.
    private static func save(_ image: QuickLookImage, in folder: URL) async -> URL? {
        guard let (data, response) = try? await session.data(from: image.url), data.count <= maxBytes else { return nil }
        let type = response.mimeType ?? ""
        guard type.hasPrefix("image/") || image.url.scheme == "data" else { return nil }
        let ext = image.fileExtension ?? UTType(mimeType: type)?.preferredFilenameExtension
        let file = folder.appending(path: ext.map { "\(image.baseName).\($0)" } ?? image.baseName)
        return (try? data.write(to: file)) == nil ? nil : file
    }
}
