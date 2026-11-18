import Foundation

/// An image of an article to show in Quick Look, and the name of the local file it is saved as.
public struct QuickLookImage: Equatable, Sendable {
    public let url: URL
    /// `01`, `02`…: the order in the article. The feed's own file names are never used.
    public let baseName: String
    /// From the address or the data URL's type; nil when unknown, then taken from the server's answer.
    public let fileExtension: String?

    public var fileName: String { fileExtension.map { "\(baseName).\($0)" } ?? baseName }
}

extension Library {
    private static let imageExtensions: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "svg", "heic", "avif", "bmp", "tif", "tiff"]

    /// The images of an article that Quick Look may fetch, in page order: `https:` addresses and `data:image/…`, once
    /// each, at most `limit`. The sources come from the feed, so anything else (`http:`, `file:`, `javascript:`) is
    /// left out, and the file names are built here, never taken from the sources.
    public static func quickLookImages(_ sources: [String], limit: Int = 50) -> [QuickLookImage] {
        var seen: Set<String> = [], images: [QuickLookImage] = []
        for source in sources {
            if images.count == limit { break }
            guard let url = URL(string: source), seen.insert(url.absoluteString).inserted else { continue }
            let ext: String?
            switch url.scheme?.lowercased() {
            case "https":
                ext = knownExtension(url.pathExtension)
            case "data":
                guard let type = dataImageSubtype(of: source) else { continue }
                ext = ["jpeg": "jpg", "svg+xml": "svg"][type] ?? knownExtension(type)
            default:
                continue
            }
            images.append(QuickLookImage(url: url, baseName: String(format: "%02d", images.count + 1), fileExtension: ext))
        }
        return images
    }

    private static func knownExtension(_ ext: String) -> String? {
        let ext = ext.lowercased()
        return imageExtensions.contains(ext) ? ext : nil
    }

    /// `png` for `data:image/png;base64,…`; nil when the data URL is not an image.
    private static func dataImageSubtype(of source: String) -> String? {
        let header = source.dropFirst("data:".count).prefix { $0 != "," && $0 != ";" }.lowercased()
        return header.hasPrefix("image/") ? String(header.dropFirst("image/".count)) : nil
    }
}
