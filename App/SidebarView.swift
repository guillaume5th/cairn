import AppKit
import CairnCore
import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var state
    @Query(sort: \Feed.title) private var feeds: [Feed]
    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query(sort: \Cairn.name) private var cairns: [Cairn]
    @Query(sort: \CairnCore.Tag.name) private var tags: [CairnCore.Tag]
    // Every unread article, kept ones without a feed included, like the "Tous les articles" list.
    @Query(filter: #Predicate<Article> { !$0.isRead }) private var unreadArticles: [Article]
    @State private var feedToDelete: Feed?
    /// Keys of the collapsed folders, one per line, kept on this Mac.
    @AppStorage("collapsedFolders") private var collapsedFolders = ""
    /// What the name alert creates or renames; nil when it is closed.
    @State private var naming: Naming?
    @State private var name = ""
    @State private var cairnToDelete: Cairn?

    private enum Naming {
        case newFolder, folder(Folder), newCairn, cairn(Cairn)

        var title: String {
            switch self {
            case .newFolder: "Nouveau dossier"
            case .folder: "Renommer le dossier"
            case .newCairn: "Nouveau cairn"
            case .cairn: "Renommer le cairn"
            }
        }

        var isNew: Bool {
            switch self {
            case .newFolder, .newCairn: true
            case .folder, .cairn: false
            }
        }
    }

    var body: some View {
        List(selection: $selection) {
            Label("Tous les articles", systemImage: "tray.full")
                .badge(unreadArticles.count)
                .tag(SidebarItem.all)
            Label("Résumés", systemImage: "text.append")
                .tag(SidebarItem.digests)

            Section {
                ForEach(cairns) { cairn in
                    Label(cairn.name, image: "cairn")
                        .tag(SidebarItem.cairn(cairn.persistentModelID))
                        .contextMenu {
                            Button("Renommer…") { startNaming(.cairn(cairn)) }
                            Button("Supprimer le cairn…", role: .destructive) { cairnToDelete = cairn }
                                .disabled(cairns.count == 1)
                        }
                    ForEach(tags(in: cairn)) { tag in
                        Label(tag.name, systemImage: "tag")
                            .padding(.leading, 12)
                            .tag(SidebarItem.tag(cairn.persistentModelID, tag.key))
                    }
                }
            } header: {
                HStack {
                    Text("Cairns")
                    Spacer()
                    Button("Nouveau cairn", systemImage: "plus") { startNaming(.newCairn) }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .help("Nouveau cairn")
                        // Inset to line up with the unread counters of the rows below.
                        .padding(.trailing, 21)
                }
            }

            Section {
                ForEach(folders) { folder in
                    DisclosureGroup(isExpanded: isExpanded(folder)) {
                        ForEach(feeds.filter { $0.folder?.persistentModelID == folder.persistentModelID }, content: feedRow)
                    } label: {
                        Label(folder.name, systemImage: "folder")
                            .badge(folder.unreadCount)
                            .tag(SidebarItem.folder(folder.persistentModelID))
                            .contextMenu {
                                Button("Renommer…") { startNaming(.folder(folder)) }
                                Button("Supprimer le dossier", role: .destructive) {
                                    let wasSelected = selection == .folder(folder.persistentModelID)
                                    Library.delete(folder, context: context)
                                    // After the List has moved its selection to a neighbouring row, which it does
                                    // when the selected row disappears.
                                    if wasSelected { Task { selection = .all } }
                                }
                            }
                            .dropDestination(for: String.self) { urls, _ in return move(urls, to: folder) }
                    }
                }
                ForEach(feeds.filter { $0.folder == nil }, content: feedRow)
            } header: {
                HStack {
                    Text("Abonnements")
                    Spacer()
                    // A Button popping an NSMenu rather than a SwiftUI Menu, whose label renders brighter and
                    // larger than the "Nouveau cairn" button above whatever its style.
                    Button("Ajouter", systemImage: "plus") {
                        ActionMenu.popUp([
                            ("Ajouter un abonnement…", { state.isAddingFeed = true }),
                            ("Nouveau dossier…", { startNaming(.newFolder) }),
                        ])
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .help("Ajouter un abonnement (⌘N) ou un dossier")
                    .padding(.trailing, 21)
                }
                // Dropping a feed on the section header takes it out of its folder.
                .dropDestination(for: String.self) { urls, _ in return move(urls, to: nil) }
            }
        }
        .confirmationDialog("Supprimer « \(feedToDelete?.title ?? "") » ?",
                            isPresented: Binding(get: { feedToDelete != nil }, set: { if !$0 { feedToDelete = nil } }),
                            presenting: feedToDelete) { feed in
            Button("Supprimer", role: .destructive) {
                if selection == .feed(feed.persistentModelID) { selection = .all }
                Library.delete(feed, context: context)
            }
        } message: { _ in
            Text("Ses articles non gardés seront supprimés. Les articles gardés restent dans leur cairn.")
        }
        .alert(naming?.title ?? "", isPresented: Binding(get: { naming != nil }, set: { if !$0 { naming = nil } }),
               presenting: naming) { naming in
            TextField("Nom", text: $name)
            Button("Annuler", role: .cancel) {}
            Button(naming.isNew ? "Créer" : "Renommer") { save(naming) }
        }
        .confirmationDialog("Supprimer le cairn « \(cairnToDelete?.name ?? "") » ?",
                            isPresented: Binding(get: { cairnToDelete != nil }, set: { if !$0 { cairnToDelete = nil } }),
                            presenting: cairnToDelete) { cairn in
            Button("Supprimer", role: .destructive) { delete(cairn) }
        } message: { cairn in
            switch cairn.articles?.count ?? 0 {
            case 0: Text("Il ne contient aucun article.")
            case 1: Text("Son article ne sera plus gardé et perdra sa note et ses tags.")
            case let count: Text("Ses \(count) articles ne seront plus gardés et perdront leur note et leurs tags.")
            }
        }
    }

    private func feedRow(_ feed: Feed) -> some View {
        Label {
            HStack {
                Text(feed.title).lineLimit(1)
                if let error = feed.lastError {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                        .help(error)
                        .accessibilityLabel("Erreur : \(error)")
                }
            }
        } icon: {
            SourceIcon(data: feed.iconData)
        }
        .badge(feed.unreadCount)
        .tag(SidebarItem.feed(feed.persistentModelID))
        .draggable(feed.url)
        .contextMenu {
            Menu("Déplacer vers") {
                ForEach(folders) { folder in
                    Button(folder.name) { Library.move(feed, to: folder) }
                        .disabled(feed.folder?.persistentModelID == folder.persistentModelID)
                }
                if !folders.isEmpty { Divider() }
                Button("Aucun dossier") { Library.move(feed, to: nil) }
                    .disabled(feed.folder == nil)
            }
            Divider()
            Button("Supprimer l'abonnement…", role: .destructive) { feedToDelete = feed }
        }
    }

    private func isExpanded(_ folder: Folder) -> Binding<Bool> {
        Binding {
            !collapsedFolders.split(separator: "\n").contains(Substring(folder.key))
        } set: { expanded in
            var keys = Set(collapsedFolders.split(separator: "\n").map(String.init))
            if expanded { keys.remove(folder.key) } else { keys.insert(folder.key) }
            collapsedFolders = keys.sorted().joined(separator: "\n")
        }
    }

    /// Dragged feeds are identified by their URL, unique in the library.
    private func move(_ urls: [String], to folder: Folder?) -> Bool {
        let moved = feeds.filter { urls.contains($0.url) }
        for feed in moved { Library.move(feed, to: folder) }
        return !moved.isEmpty
    }

    /// Tags carried by at least one article of this cairn.
    private func tags(in cairn: Cairn) -> [CairnCore.Tag] {
        tags.filter { $0.articles?.contains { $0.isKept && $0.cairn?.persistentModelID == cairn.persistentModelID } ?? false }
    }

    private func startNaming(_ naming: Naming) {
        switch naming {
        case let .folder(folder): name = folder.name
        case let .cairn(cairn): name = cairn.name
        case .newFolder, .newCairn: name = ""
        }
        self.naming = naming
    }

    private func save(_ naming: Naming) {
        do {
            switch naming {
            case .newFolder:
                try Library.createFolder(named: name, context: context)
            case let .folder(folder):
                let wasExpanded = isExpanded(folder).wrappedValue
                // The collapsed state is stored by key: move it to the new key (or back, on failure).
                isExpanded(folder).wrappedValue = true
                defer { isExpanded(folder).wrappedValue = wasExpanded }
                try Library.rename(folder, to: name, context: context)
            case .newCairn:
                try Library.createCairn(named: name, context: context)
            case let .cairn(cairn):
                try Library.rename(cairn, to: name, context: context)
            }
            // A new model only gets its permanent identifier, which the sidebar selection uses, once saved.
            state.save()
        } catch {
            state.message = error.localizedDescription
        }
    }

    private func delete(_ cairn: Cairn) {
        let id = cairn.persistentModelID
        let wasSelected = switch selection {
        case .cairn(id), .tag(id, _): true
        default: false
        }
        do {
            try Library.delete(cairn, context: context)
        } catch {
            state.message = error.localizedDescription
            return
        }
        // After the List has moved its selection to a neighbouring row (see the folder deletion).
        if wasSelected { Task { selection = .all } }
    }
}

/// Pops a native menu under the mouse, for a button that must look like a plain Button.
private enum ActionMenu {
    private final class Item: NSMenuItem {
        let handler: () -> Void
        init(_ title: String, _ handler: @escaping () -> Void) {
            self.handler = handler
            super.init(title: title, action: #selector(run), keyEquivalent: "")
            target = self
        }
        required init(coder: NSCoder) { fatalError() }
        @objc func run() { handler() }
    }

    static func popUp(_ items: [(String, () -> Void)]) {
        let menu = NSMenu()
        items.forEach { menu.addItem(Item($0.0, $0.1)) }
        menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
    }
}
