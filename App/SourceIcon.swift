import AppKit
import SwiftUI

/// Icon of an article's source in a Liquid Glass circle: its favicon, or a generic symbol when there is none
/// or it cannot be read.
struct SourceIcon: View {
    let data: Data?
    /// Fixed diameter; nil sizes the circle like a symbol in the current text style.
    var side: CGFloat? = nil

    var body: some View {
        if let side {
            circle.frame(width: side, height: side)
        } else {
            // A hidden symbol sets the frame, so the circle gets the size and baseline a symbol would have in this
            // text style (and follows the sidebar icon size setting), which @ScaledMetric does not do on macOS.
            Image(systemName: "circle").hidden().overlay { circle }
        }
    }

    private var icon: DecodedIcon? { data.flatMap(DecodedIcon.cached) }

    private var circle: some View {
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .glassEffect(.regular, in: .circle)
            .accessibilityHidden(true)
    }

    @ViewBuilder private var content: some View {
        if let icon, icon.fillsCircle {
            // A full square picture is masked round, like an app icon, with a ring of glass around it.
            inset(Image(nsImage: icon.image).resizable().interpolation(.high).scaledToFill(), ratio: 0.8, round: true)
        } else if let icon {
            inset(Image(nsImage: icon.image).resizable().interpolation(.high).scaledToFit(), ratio: 0.62)
        } else {
            inset(Image(systemName: "dot.radiowaves.up.forward").resizable().scaledToFit(), ratio: 0.62)
                .foregroundStyle(.secondary)
        }
    }

    /// Keeps the icon off the circle's edge: centred at `ratio` of the diameter, optionally masked round.
    private func inset(_ image: some View, ratio: CGFloat, round: Bool = false) -> some View {
        GeometryReader { proxy in
            image.frame(width: proxy.size.width * ratio, height: proxy.size.height * ratio)
                .clipShape(round ? AnyShape(.circle) : AnyShape(.rect))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Height of an article row whose title takes its two allowed lines: body ×2 + caption + the row's 2 pt spacing.
    static let articleRowSide: CGFloat = {
        let layout = NSLayoutManager()
        let body = layout.defaultLineHeight(for: .preferredFont(forTextStyle: .body))
        let caption = layout.defaultLineHeight(for: .preferredFont(forTextStyle: .caption1))
        return (2 * body + caption + 2).rounded(.up)
    }()
}

/// A favicon decoded once, with what the circle needs to know about it.
@MainActor
final class DecodedIcon {
    let image: NSImage
    /// All four corners opaque: a full square picture, masked round. Otherwise a cut-out logo, shown as is.
    let fillsCircle: Bool

    // shortcut: NSCache evicts on its own heuristics only; revisit if memory matters with hundreds of feeds.
    private static let cache = NSCache<NSData, DecodedIcon>()

    static func cached(_ data: Data) -> DecodedIcon? {
        let key = data as NSData
        if let icon = cache.object(forKey: key) { return icon }
        guard let icon = DecodedIcon(data) else { return nil }
        cache.setObject(icon, forKey: key)
        return icon
    }

    private init?(_ data: Data) {
        guard let image = NSImage(data: data), image.isValid else { return nil }
        let widest = image.representations.max { $0.pixelsWide < $1.pixelsWide }
        let pixels = widest.map { CGSize(width: $0.pixelsWide, height: $0.pixelsHigh) } ?? .zero
        var rect = CGRect(origin: .zero, size: pixels.width > 0 ? pixels : CGSize(width: 64, height: 64))
        guard let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil) else { return nil }
        self.image = image
        fillsCircle = Self.cornersAreOpaque(cg)
    }

    private static func cornersAreOpaque(_ cg: CGImage) -> Bool {
        let (w, h) = (cg.width, cg.height)
        guard let context = rgba(width: w, height: h) else { return false }
        context.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        guard let pixels = context.data?.assumingMemoryBound(to: UInt8.self) else { return false }
        return [(0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)].allSatisfy { x, y in pixels[(y * w + x) * 4 + 3] > 230 }
    }

    private static func rgba(width: Int, height: Int) -> CGContext? {
        CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                  space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    }
}
