import Sparkle
import SwiftUI

/// Sparkle's updater, started in release builds only: Cairn Dev would be replaced by the release app.
@MainActor @Observable
final class Updates {
    @ObservationIgnored private let controller: SPUStandardUpdaterController?
    @ObservationIgnored private var observation: NSKeyValueObservation?
    /// False while a check or a background download is under way.
    private(set) var canCheck = false

    init() {
        #if DEBUG
        controller = nil
        #else
        let controller = SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        self.controller = controller
        // The value is read back on the main actor, where Sparkle keeps it.
        observation = controller.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { [weak self] _, _ in
            Task { @MainActor in self?.canCheck = self?.controller?.updater.canCheckForUpdates ?? false }
        }
        #endif
    }

    var isAvailable: Bool { controller != nil }

    func check() { controller?.checkForUpdates(nil) }
}
