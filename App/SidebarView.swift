import CairnCore
import SwiftData
import SwiftUI

struct SidebarView: View {
    /// Several feeds, or a single entry of any kind (see `SelectionRule`).
    @Binding var selection: Set<SidebarItem>
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var state
    @Query(sort: \Feed.title) private var feeds: [Feed]
    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query(sort: \Cairn.name) private var cairns: [Cairn]
    @Query(sort: \CairnCore.Tag.name) private var tags: [CairnCore.Tag]
    // Every unread article, kept ones without a feed included, like the "Tous les articles" list.
    @Query(filter: #Predicate<Article> { !$0.isRead }) private var unreadArticles: [Article]
    @State private var feedsToDelete: [Feed] = []
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
                // Reading and marking change it while the window is open; refresh() covers the closed window.
                .onChange(of: unreadArticles.count) { state.updateBadge(unread: unreadArticles.count) }
            Label("Résumés quotidiens", systemImage: "text.append")
                .tag(SidebarItem.digests)

            Section {
                ForEach(cairns) { cairn in
                    Label(cairn.name, image: "cairn")
                        .tag(SidebarItem.cairn(cairn.persistentModelID))
                    ForEach(tags(in: cairn)) { tag in
                        Label(tag.name, systemImage: "tag")
                            .padding(.leading, 12)
                            .tag(SidebarItem.tag(cairn.persistentModelID, tag.key))
                    }
                }
            } header: {
                Text("Cairns")
            }

            subscriptionsSection
        }
        // One menu for the whole list: it gets the selection when the clicked row is part of it, else that row alone.
        .contextMenu(forSelectionType: SidebarItem.self, menu: menu)
        .toolbar { sidebarCommands }
        // Dragging a selected feed drags the whole selection of feeds.
        .dragContainer(for: String.self, itemID: \.self) { urls in urls }
        .dragContainerSelection(selectedFeeds.map(\.url))
        .confirmationDialog(feedsToDelete.count == 1 ? "Supprimer « \(feedsToDelete[0].title) » ?"
                                                     : "Supprimer \(feedsToDelete.count) abonnements ?",
                            isPresented: Binding(get: { !feedsToDelete.isEmpty }, set: { if !$0 { feedsToDelete = [] } }),
                            presenting: feedsToDelete) { feeds in
            Button("Supprimer", role: .destructive) {
                let wasSelected = feeds.contains { selection.contains(.feed($0.persistentModelID)) }
                if wasSelected { selection = [.all] }
                for feed in feeds { Library.delete(feed, context: context) }
            }
        } message: { feeds in
            Text(feeds.count == 1 ? "Ses articles non gardés seront supprimés. Les articles gardés restent dans leur cairn."
                                  : "Leurs articles non gardés seront supprimés. Les articles gardés restent dans leur cairn.")
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

    /// What can be created, in one "+".
    @ToolbarContentBuilder private var sidebarCommands: some ToolbarContent {
        ToolbarItemGroup {
            Menu("Ajouter", systemImage: "plus") {
                Button("Ajouter un abonnement…", systemImage: "dot.radiowaves.up.forward") { state.isAddingFeed = true }
                Button("Nouveau dossier…", systemImage: "folder.badge.plus") { startNaming(.newFolder) }
                Button("Nouveau cairn…", image: ImageResource(name: "cairn", bundle: .main)) { startNaming(.newCairn) }
            }
            .help("Ajouter un abonnement (⌘N), un dossier ou un cairn")
        }
    }

    /// Folders and feeds, split out of `body`, which is otherwise too big for the type checker.
    private var subscriptionsSection: some View {
        Section {
            ForEach(folders) { folder in
                DisclosureGroup(isExpanded: isExpanded(folder)) {
                    ForEach(feeds.filter { $0.folder?.persistentModelID == folder.persistentModelID }, content: feedRow)
                } label: {
                    Label(folder.name, systemImage: "folder")
                        .badge(folder.unreadCount)
                        .tag(SidebarItem.folder(folder.persistentModelID))
                        .dropDestination(for: String.self) { urls, _ in return move(urls, to: folder) }
                }
            }
            ForEach(feeds.filter { $0.folder == nil }, content: feedRow)
        } header: {
            Text("Abonnements")
                // Dropping a feed on the section header takes it out of its folder.
                .dropDestination(for: String.self) { urls, _ in return move(urls, to: nil) }
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
        .draggable(containerItemID: feed.url)
        // Last: a selection tag under the drag modifier would no longer reach the List row.
        .tag(SidebarItem.feed(feed.persistentModelID))
    }

    private var selectedFeeds: [Feed] { feeds.filter { selection.contains(.feed($0.persistentModelID)) } }

    /// Menu of the clicked entry or of the selection holding it: a cairn or a folder alone, or one or more feeds.
    private func menu(for items: Set<SidebarItem>) -> some View {
        // Menus show only titles by default on macOS; icons as in Apple's apps since macOS 26.
        menuItems(for: items).labelStyle(.titleAndIcon)
    }

    @ViewBuilder
    private func menuItems(for items: Set<SidebarItem>) -> some View {
        let lot = feeds.filter { items.contains(.feed($0.persistentModelID)) }
        if let cairn = single(items, cairns, as: SidebarItem.cairn) {
            Button("Renommer…", systemImage: "pencil") { startNaming(.cairn(cairn)) }
            Button("Supprimer le cairn…", systemImage: "trash", role: .destructive) { cairnToDelete = cairn }
                .disabled(cairns.count == 1)
        } else if let folder = single(items, folders, as: SidebarItem.folder) {
            Button("Marquer tout comme lu", systemImage: "checkmark.circle") { markRead(folder.feeds ?? []) }
                .disabled(folder.unreadCount == 0)
            Divider()
            Button("Renommer…", systemImage: "pencil") { startNaming(.folder(folder)) }
            Button("Supprimer le dossier", systemImage: "trash", role: .destructive) {
                let wasSelected = selection.contains(.folder(folder.persistentModelID))
                Library.delete(folder, context: context)
                // After the List has moved its selection to a neighbouring row, which it does
                // when the selected row disappears.
                if wasSelected { Task { selection = [.all] } }
            }
        } else if !lot.isEmpty, lot.count == items.count {
            Button("Marquer tout comme lu", systemImage: "checkmark.circle") { markRead(lot) }
                .disabled(lot.allSatisfy { $0.unreadCount == 0 })
            Divider()
            Menu("Déplacer vers", systemImage: "folder") {
                ForEach(folders) { folder in
                    Button(folder.name) { for feed in lot { Library.move(feed, to: folder) } }
                        .disabled(lot.allSatisfy { $0.folder?.persistentModelID == folder.persistentModelID })
                }
                if !folders.isEmpty { Divider() }
                Button("Aucun dossier") { for feed in lot { Library.move(feed, to: nil) } }
                    .disabled(lot.allSatisfy { $0.folder == nil })
            }
            // Articles published from now on get their full text after each refresh; those already listed do not.
            Toggle("Toujours charger les articles complets", systemImage: "doc.text.magnifyingglass", isOn: Binding {
                lot.allSatisfy { $0.loadsFullContentSince != nil }
            } set: { isOn in
                for feed in lot { feed.loadsFullContentSince = isOn ? (feed.loadsFullContentSince ?? .now) : nil }
            })
            Divider()
            Button(lot.count == 1 ? "Supprimer l'abonnement…" : "Supprimer \(lot.count) abonnements…", systemImage: "trash", role: .destructive) {
                feedsToDelete = lot
            }
        }
    }

    /// The model of `items` when it is its only entry and of the given kind.
    private func markRead(_ feeds: [Feed]) {
        for feed in feeds { for article in feed.articles ?? [] where !article.isRead { article.isRead = true } }
    }

    private func single<M: PersistentModel>(_ items: Set<SidebarItem>, _ models: [M],
                                            as item: (PersistentIdentifier) -> SidebarItem) -> M? {
        guard items.count == 1 else { return nil }
        return models.first { items.contains(item($0.persistentModelID)) }
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
        let wasSelected = selection.contains { item in
            switch item {
            case .cairn(id), .tag(id, _): true
            default: false
            }
        }
        do {
            try Library.delete(cairn, context: context)
        } catch {
            state.message = error.localizedDescription
            return
        }
        // After the List has moved its selection to a neighbouring row (see the folder deletion).
        if wasSelected { Task { selection = [.all] } }
    }
}
