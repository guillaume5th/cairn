import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnApp: App {
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
            ContentView()
                .environment(state)
                .modelContainer(state.container)
                .task { await state.launch() }
        }
        .commands { CairnCommands(state: state) }
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
            Toggle("Icônes dans la liste d'articles", isOn: $showListIcons)
            Divider()
        }
        CommandGroup(after: .textEditing) {
            Button("Rechercher") { state.isSearchRequested = true }
                .keyboardShortcut("f")
        }
    }
}
