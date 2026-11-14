import CoreSpotlight
import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnApp: App {
    @NSApplicationDelegateAdaptor private var delegate: AppDelegate
    @State private var state: AppState

    init() {
        do {
            _state = State(initialValue: AppState(container: try CairnStore.container()))
        } catch {
            fatalError("Impossible d'ouvrir la base de données Cairn : \(error)")
        }
    }

    var body: some Scene {
        Window("Cairn", id: "main") {
            content
                // Autosave can lag behind the last edit: without this, a change made just before quitting is lost.
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in state.save() }
        }
        .commands { CairnCommands(state: state) }
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
    @AppStorage(TextScale.key) private var textScale = 1.0
    @AppStorage("showListIcons") private var showListIcons = true
    @AppStorage(KeptEditor.shownKey) private var inspectorShown = true
    @AppStorage(ContentView.oldestFirstKey) private var oldestFirst = false

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Ajouter un abonnement…") { state.isAddingFeed = true }
                .keyboardShortcut("n")
            Divider()
            Button("Importer OPML…") { state.isImporting = true }
            Button("Exporter OPML…") { state.prepareExport() }
        }
        CommandGroup(before: .toolbar) {
            Button("Rafraîchir") { Task { await state.refresh() } }
                .keyboardShortcut("r")
                .disabled(state.isRefreshing)
            Button("Générer le résumé maintenant") { Task { await state.makeDigest(manual: true) } }
                .disabled(state.isDigesting)
            Divider()
            Button("Agrandir le texte") { textScale = TextScale.stepped(textScale, by: 0.1) }
                .keyboardShortcut("+")
                .disabled(textScale >= TextScale.range.upperBound)
            Button("Réduire le texte") { textScale = TextScale.stepped(textScale, by: -0.1) }
                .keyboardShortcut("-")
                .disabled(textScale <= TextScale.range.lowerBound)
            Button("Taille normale") { textScale = 1 }
                .keyboardShortcut("0")
                .disabled(textScale == 1)
            Divider()
            Picker("Ordre des articles", selection: $oldestFirst) {
                Text("Plus récents d'abord").tag(false)
                Text("Plus anciens d'abord").tag(true)
            }
            Toggle("Icônes dans la liste d'articles", isOn: $showListIcons)
            // Not InspectorCommands: its title is only half translated ("Inspecteur Show"). Same shortcut.
            Button(inspectorShown ? "Masquer l'inspecteur" : "Afficher l'inspecteur") { inspectorShown.toggle() }
                .keyboardShortcut("i", modifiers: [.control, .command])
            Divider()
        }
        CommandMenu("Article") { ArticleCommands(context: state.context) }
        CommandGroup(after: .textEditing) {
            Button("Rechercher") { state.isSearchRequested = true }
                .keyboardShortcut("f")
        }
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
