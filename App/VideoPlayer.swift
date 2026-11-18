import AppKit
import SwiftUI
import WebKit

/// A YouTube video, played by YouTube's embedded player (youtube-nocookie.com) with its own web page: the article's
/// page runs no script. Playback stops when the view goes away, which a change of video does with `.id`.
struct VideoPlayer: View {
    let id: String
    /// No height cap: the video is all the article has.
    var fillsPane = false
    @Environment(\.openURL) private var openURL
    @State private var page = Self.makePage()

    private var watchURL: URL { URL(string: "https://www.youtube.com/watch?v=\(id)")! }

    var body: some View {
        VStack(spacing: 6) {
            WebView(page)
                .aspectRatio(16 / 9, contentMode: .fit)
                .frame(maxWidth: .infinity, maxHeight: fillsPane ? nil : 360)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            // YouTube's refusal to embed a video shows inside the player, where the app cannot read it: this stays.
            Button("Ouvrir sur YouTube", systemImage: "arrow.up.right.square") { openURL(watchURL) }
                .buttonStyle(.link)
                .font(.callout)
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .task {
            // The id comes from `Library.youtubeVideoID`, which only lets 11 URL-safe characters through.
            guard let url = URL(string: "https://www.youtube-nocookie.com/embed/\(id)") else { return }
            // A failed load shows in the player itself; "Ouvrir sur YouTube" stays.
            // Without a referrer YouTube refuses to embed (error 153).
            var request = URLRequest(url: url)
            request.setValue("https://www.youtube-nocookie.com/", forHTTPHeaderField: "Referer")
            do { for try await _ in page.load(request) {} } catch {}
        }
    }

    private static func makePage() -> WebPage {
        var config = WebPage.Configuration()
        config.websiteDataStore = .nonPersistent()
        return WebPage(configuration: config, navigationDecider: YouTubeOnly())
    }
}

/// Lets the player load from YouTube only; a clicked link opens in the browser, anything else is cancelled.
private struct YouTubeOnly: WebPage.NavigationDeciding {
    func decidePolicy(for action: WebPage.NavigationAction,
                      preferences: inout WebPage.NavigationPreferences) async -> WKNavigationActionPolicy {
        guard let url = action.request.url else { return .cancel }
        if action.navigationType == .linkActivated {
            NSWorkspace.shared.open(url)
            return .cancel
        }
        let host = url.host()?.lowercased() ?? ""
        let isYouTube = ["youtube-nocookie.com", "youtube.com"].contains { host == $0 || host.hasSuffix("." + $0) }
        return url.scheme == "https" && isYouTube ? .allow : .cancel
    }
}
