import CairnCore
import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var state
    @Query(sort: \Feed.title) private var feeds: [Feed]
    @Query(sort: \Folder.name) private var folders: [Folder]
    @Query(sort: \CairnCore.Tag.name) private var tags: [CairnCore.Tag]
    // Every unread article, kept ones without a feed included, like the "Tous les articles" list.
    @Query(filter: #Predicate<Article> { !$0.isRead }) private var unreadArticles: [Article]
    @State private var feedToDelete: Feed?
    /// Keys of the collapsed folders, one per line, kept on this Mac.
    @AppStorage("collapsedFolders") private var collapsedFolders = ""
    @State private var isNamingFolder = false
    /// Folder being renamed; nil while creating one.
    @State private var folderToRename: Folder?
    @State private var folderName = ""

    var body: some View {
        List(selection: $selection) {
            Label("Tous les articles", systemImage: "tray.full")
                .badge(unreadArticles.count)
                .tag(SidebarItem.all)
            Label("Cairn", image: "cairn").tag(SidebarItem.cairn)
            // Only tags still carried by a kept article.
            ForEach(tags.filter { $0.articles?.contains(where: \.isKept) ?? false }) { tag in
                Label(tag.name, systemImage: "tag")
                    .padding(.leading, 12)
                    .tag(SidebarItem.tag(tag.key))
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
                                Button("Renommer…") { startNaming(folder) }
                                Button("Supprimer le dossier", role: .destructive) {
                                    let wasSelected = selection == .folder(folder.persistentModelID)
                                    Library.delete(folder, context: context)
                                    // After the List has moved its selection to a neighbouring row, which it does
                                    // when the selected row disappears.
                                    if wasSelected { Task { selection = .all } }
                                }
                            }
                            .dropDestination(for: String.self) { urls, _ in move(urls, to: folder) }
                    }
                }
                ForEach(feeds.filter { $0.folder == nil }, content: feedRow)
            } header: {
                HStack {
                    Text("Abonnements")
                    Spacer()
                    Menu {
                        Button("Ajouter un abonnement…") { state.isAddingFeed = true }
                        Button("Nouveau dossier…") { startNaming(nil) }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuStyle(.button)
                    .buttonStyle(.borderless)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .help("Ajouter un abonnement (⌘N) ou un dossier")
                    .accessibilityLabel("Ajouter")
                    // Inset to line up with the unread counters of the rows below.
                    .padding(.trailing, 17)
                }
                // Dropping a feed on the section header takes it out of its folder.
                .dropDestination(for: String.self) { urls, _ in move(urls, to: nil) }
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
            Text("Ses articles non gardés seront supprimés. Les articles gardés restent dans le cairn.")
        }
        .alert(folderToRename == nil ? "Nouveau dossier" : "Renommer le dossier", isPresented: $isNamingFolder) {
            TextField("Nom du dossier", text: $folderName)
            Button("Annuler", role: .cancel) {}
            Button(folderToRename == nil ? "Créer" : "Renommer") { saveFolder() }
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

    private func startNaming(_ folder: Folder?) {
        folderToRename = folder
        folderName = folder?.name ?? ""
        isNamingFolder = true
    }

    private func saveFolder() {
        do {
            if let folder = folderToRename {
                let wasExpanded = isExpanded(folder).wrappedValue
                // The collapsed state is stored by key: move it to the new key (or back, on failure).
                isExpanded(folder).wrappedValue = true
                defer { isExpanded(folder).wrappedValue = wasExpanded }
                try Library.rename(folder, to: folderName, context: context)
            } else {
                try Library.createFolder(named: folderName, context: context)
            }
        } catch {
            state.message = error.localizedDescription
        }
    }
}
