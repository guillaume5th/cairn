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

struct CairnCommands: Commands {
    let state: AppState

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Ajouter un flux…") { state.isAddingFeed = true }
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
        }
        CommandGroup(after: .textEditing) {
            Button("Rechercher dans le cairn") { state.isSearchRequested = true }
                .keyboardShortcut("f")
        }
    }
}
