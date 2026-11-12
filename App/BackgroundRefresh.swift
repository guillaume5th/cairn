#if os(iOS)
import BackgroundTasks
import CairnCore
import Foundation

/// Asks iOS for background time: a refresh of the feeds about every hour, and a processing task for the daily
/// digest from its time on. The digest needs a processing task: an app refresh lasts about 30 s, and Apple's model
/// is much slower in the background than on screen. iOS decides when (and whether) either runs.
enum BackgroundRefresh {
    static let identifier = "dev.cairn.refresh"
    static let digestIdentifier = "dev.cairn.digest"

    static func schedule(now: Date = .now) {
        let refresh = BGAppRefreshTaskRequest(identifier: identifier)
        refresh.earliestBeginDate = now.addingTimeInterval(3_600)
        try? BGTaskScheduler.shared.submit(refresh)
        let digest = BGProcessingTaskRequest(identifier: digestIdentifier)
        digest.earliestBeginDate = nextDigest(now: now)
        digest.requiresNetworkConnectivity = true
        try? BGTaskScheduler.shared.submit(digest)
    }

    /// Now when today's digest is due, else the next digest time (today's or tomorrow's).
    static func nextDigest(now: Date) -> Date {
        if DigestSettings.isDue { return now }
        let minutes = DigestSettings.time
        let calendar = Calendar.current
        guard let today = calendar.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: now) else { return now }
        return today > now ? today : calendar.date(byAdding: .day, value: 1, to: today) ?? today
    }
}
#endif
