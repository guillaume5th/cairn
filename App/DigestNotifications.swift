import CairnCore
import SwiftData
import SwiftUI
import UserNotifications

/// The "digest ready" notification and the way back from it to the digest.
enum DigestNotifications {
    static let digestKey = "digest"

    static func requestAuthorization() async -> Bool {
        (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])) ?? false
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

    /// First line with words, without Markdown marks: the gist for the notification's body.
    static func headline(of text: String) -> String {
        let line = text.split(whereSeparator: \.isNewline).lazy
            .map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "#*-_> ").union(.whitespaces)) }
            .first { !$0.isEmpty } ?? ""
        return line.replacingOccurrences(of: "**", with: "")
    }

    /// Receives the tap on a notification and hands its digest to the app state.
    @MainActor
    final class Handler: NSObject, UNUserNotificationCenterDelegate {
        weak var state: AppState?

        nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
            guard let encoded = response.notification.request.content.userInfo[DigestNotifications.digestKey] as? String,
                  let data = Data(base64Encoded: encoded),
                  let id = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) else { return }
            await open(id)
        }

        /// Not posted while the app is in front; should one arrive then, the list shows the digest already.
        nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
            -> UNNotificationPresentationOptions { [] }

        private func open(_ id: PersistentIdentifier) {
            state?.digestToOpen = id
            #if os(macOS)
            // A closed window comes back like after a click on the Dock icon.
            NSWorkspace.shared.open(Bundle.main.bundleURL)
            #endif
        }
    }
}
