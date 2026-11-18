import Foundation

extension Library {
    /// The id of the video a link points to (`youtube.com/watch?v=ID` or `youtu.be/ID`); nil for anything else:
    /// channels, playlists, Shorts, other sites. The id is checked, since it ends up in the player's address.
    public static func youtubeVideoID(in link: String) -> String? {
        guard let url = URL(string: link), ["http", "https"].contains(url.scheme?.lowercased()),
              let host = url.host()?.lowercased() else { return nil }
        let id: String?
        switch host {
        case "youtube.com", "www.youtube.com", "m.youtube.com":
            id = url.path == "/watch"
                ? URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "v" }?.value : nil
        case "youtu.be":
            id = String(url.path.dropFirst())
        default:
            id = nil
        }
        return id.flatMap { $0.wholeMatch(of: /[A-Za-z0-9_-]{11}/) != nil ? $0 : nil }
    }
}
