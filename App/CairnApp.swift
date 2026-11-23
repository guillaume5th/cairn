import CoreSpotlight
import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    @State private var state: AppState
    @State private var updates = Updates()

    init() {
        do {
            let bundleID = Bundle.main.bundleIdentifier ?? "dev.cairn.Cairn"
            let store = CairnStore.defaultURL(bundleID: bundleID)
            // First launch outside the sandbox: take over the sandboxed version's data, which stays where it is.
            let legacy = LegacyImport.container(bundleID: bundleID)
            LegacyImport.importSettings(from: legacy.appending(path: "Library/Preferences/\(bundleID).plist"), into: .standard)
            try LegacyImport.importStore(from: legacy.appending(path: "Library/Application Support"), to: store)
            try FileManager.default.createDirectory(at: store.deletingLastPathComponent(), withIntermediateDirectories: true)
            _state = State(initialValue: AppState(container: try CairnStore.container(at: store)))
        } catch {
            fatalError(String(localized: "Cannot open the Cairn database: \(error)"))
        }
    }

    var body: some Scene {
        Window("Cairn", id: "main") {
            content
                // Autosave can lag behind the last edit: without this, a change made just before quitting is lost.
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in state.save() }
        }
        .commands { CairnCommands(state: state, updates: updates) }
        Settings { SettingsView().environment(state) }
    }

    private var content: some View {
        Group {
            // Torn down during a restore: its views would read models the restore deletes. Rebuilt fresh after.
            if state.isRestoring { ProgressView() } else { ContentView() }
        }
            .environment(state)
            .modelContainer(state.container)
            .task { delegate.state = state; await state.launch() }
    }
}

/// Reading-pane text scale, kept on this Mac (UserDefaults): 0.8× to 2× by steps of 0.1.
enum TextScale {
    static let key = "articleTextScale"
    static let range = 0.8...2.0
    /// Rounded to the tenth so repeated steps land exactly on the bounds and back on 1.
    static func stepped(_ scale: Double, by step: Double) -> Double {
        min(max(((scale + step) * 10).rounded() / 10, range.lowerBound), range.upperBound)
    }
}

struct CairnCommands: Commands {
    let state: AppState
    let updates: Updates
    @AppStorage(TextScale.key) private var textScale = 1.0
    @AppStorage("showListIcons") private var showListIcons = true
    @AppStorage(KeptEditor.shownKey) private var inspectorShown = true
    @AppStorage(ContentView.oldestFirstKey) private var oldestFirst = false

    var body: some Commands {
        CommandGroup(after: .appInfo) {
            if updates.isAvailable {
                Button("Check for Updates…") { updates.check() }
                    .disabled(!updates.canCheck)
            }
        }
        CommandGroup(replacing: .newItem) {
            Button("Add Subscription…") { state.isAddingFeed = true }
                .keyboardShortcut("n")
            Divider()
            Button("Import OPML…") { state.isImporting = true }
            Button("Export OPML…") { state.prepareExport() }
        }
        CommandGroup(before: .toolbar) {
            Button("Refresh") { Task { await state.refresh() } }
                .keyboardShortcut("r")
                .disabled(state.isRefreshing)
            Button("Generate Digest Now") { Task { await state.makeDigest(manual: true) } }
                .disabled(state.isDigesting)
            Divider()
            Button("Increase Text Size") { textScale = TextScale.stepped(textScale, by: 0.1) }
                .keyboardShortcut("+")
                .disabled(textScale >= TextScale.range.upperBound)
            Button("Decrease Text Size") { textScale = TextScale.stepped(textScale, by: -0.1) }
                .keyboardShortcut("-")
                .disabled(textScale <= TextScale.range.lowerBound)
            Button("Actual Size") { textScale = 1 }
                .keyboardShortcut("0")
                .disabled(textScale == 1)
            Divider()
            Picker("Article Order", selection: $oldestFirst) {
                Text("Newest First").tag(false)
                Text("Oldest First").tag(true)
            }
            Toggle("Icons in the Article List", isOn: $showListIcons)
            // Not InspectorCommands: its title is only half translated ("Inspecteur Show"). Same shortcut.
            Button(inspectorShown ? "Hide inspector" : "Show inspector") { inspectorShown.toggle() }
                .keyboardShortcut("i", modifiers: [.control, .command])
            Divider()
        }
        CommandMenu("Article") { ArticleCommands(context: state.context) }
        CommandGroup(after: .textEditing) {
            Button("Search") { state.isSearchRequested = true }
                .keyboardShortcut("f")
            QuoteCommand(context: state.context)
        }
    }
}

/// « Surligner » in the Edit menu, for the article in the reader.
struct QuoteCommand: View {
    let context: ModelContext
    @FocusedValue(\.quoteAction) private var action

    var body: some View {
        QuoteButtons(action: action)
            .modelContext(context) // for the cairns: menus are outside the window's container
    }
}

/// Closing the window keeps the app (and its daily digest) running, like Mail; the Dock icon reopens it.
final class AppDelegate: NSObject, NSApplicationDelegate {
    weak var state: AppState?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// A kept article chosen in Spotlight (SwiftUI's onContinueUserActivity is not called for a Window scene).
    func application(_ application: NSApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([any NSUserActivityRestoring]) -> Void) -> Bool {
        guard userActivity.activityType == CSSearchableItemActionType,
              let link = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String else { return false }
        state?.keptArticleToOpen = link
        return true
    }
}
