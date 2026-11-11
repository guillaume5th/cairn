import AppKit
import SwiftUI

/// Icon of an article's source: its favicon, or a generic symbol when there is none or it cannot be read.
struct SourceIcon: View {
    let data: Data?

    var body: some View {
        // A hidden symbol sets the frame, so the icon gets the size and baseline a symbol would have in this
        // text style (and follows the sidebar icon size setting), which @ScaledMetric does not do on macOS.
        Image(systemName: "square")
            .hidden()
            .overlay {
                if let data, let image = DecodedIcons.image(data) {
                    Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
                } else {
                    Image(systemName: "dot.radiowaves.up.forward").resizable().scaledToFit().foregroundStyle(.secondary)
                }
            }
            .accessibilityHidden(true)
    }
}

/// Decoding an icon on every redraw of a list is wasteful: decoded images are kept by content.
// shortcut: NSCache evicts on its own heuristics only; revisit if memory matters with hundreds of feeds.
@MainActor
private enum DecodedIcons {
    static let cache = NSCache<NSData, NSImage>()

    static func image(_ data: Data) -> NSImage? {
        let key = data as NSData
        if let image = cache.object(forKey: key) { return image }
        guard let image = NSImage(data: data), image.isValid else { return nil }
        cache.setObject(image, forKey: key)
        return image
    }
}
