import CairnCore
import SwiftData
import SwiftUI
import UserNotifications

/// The "digest ready" and "new articles" notifications, and the way back from them to the digest or the feed.
enum DigestNotifications {
    static let digestKey = "digest"
    static let feedKey = "feed"

    /// One request for everything Cairn may use: the system asks only once, so options added later would never be shown.
    /// The Dock badge needs `.badge`: without it macOS hides `dockTile.badgeLabel`.
    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// The user turned off Cairn's badges (or all its notifications) in System Settings.
    static func badgesDenied() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().badgeSetting == .disabled
    }

    /// Posted for an automatic digest when the setting is on; the digest's identifier rides along to open it.
    @MainActor
    static func post(for digest: Digest) async {
        guard DigestSettings.notifies else { return }
        let content = UNMutableNotificationContent()
        content.title = "Ton résumé du jour est prêt"
        content.body = headline(of: digest.text)
        content.sound = .default
        if let id = try? JSONEncoder().encode(digest.persistentModelID) {
            content.userInfo = [digestKey: id.base64EncodedString()]
        }
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    /// Posted after a refresh that added articles to a feed set to notify; the feed's identifier rides along to open it.
    @MainActor
    static func post(newArticles count: Int, in feed: Feed) async {
        let content = UNMutableNotificationContent()
        content.title = feed.title
        let newest = feed.articles?.max { $0.publishedAt < $1.publishedAt }?.title ?? ""
        content.body = count == 1 ? newest : "\(count) nouveaux articles · \(newest)"
        content.sound = .default
        if let id = try? JSONEncoder().encode(feed.persistentModelID) {
            content.userInfo = [feedKey: id.base64EncodedString()]
        }
        try? await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }

    /// First line with words, without Markdown marks: the gist for the notification's body.
    static func headline(of text: String) -> String {
        let line = text.split(whereSeparator: \.isNewline).lazy
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "#*-_> ").union(.whitespaces)) }
            .first { !$0.isEmpty } ?? ""
        return line.replacingOccurrences(of: "**", with: "")
    }

    /// Receives the tap on a notification and hands its digest or feed to the app state.
    @MainActor
    final class Handler: NSObject, UNUserNotificationCenterDelegate {
        weak var state: AppState?

        nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
            let info = response.notification.request.content.userInfo
            func id(_ key: String) -> PersistentIdentifier? {
                (info[key] as? String).flatMap { Data(base64Encoded: $0) }
                    .flatMap { try? JSONDecoder().decode(PersistentIdentifier.self, from: $0) }
            }
            if let digest = id(DigestNotifications.digestKey) { await open(digest: digest) }
            else if let feed = id(DigestNotifications.feedKey) { await open(feed: feed) }
        }

        /// Not posted while the app is in front; should one arrive then, the list shows the digest already.
        nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
            -> UNNotificationPresentationOptions { [] }

        private func open(digest id: PersistentIdentifier) {
            state?.digestToOpen = id
            // A closed window comes back like after a click on the Dock icon.
            NSWorkspace.shared.open(Bundle.main.bundleURL)
        }

        private func open(feed id: PersistentIdentifier) {
            state?.feedToOpen = id
            // A closed window comes back like after a click on the Dock icon.
            NSWorkspace.shared.open(Bundle.main.bundleURL)
        }
    }
}
