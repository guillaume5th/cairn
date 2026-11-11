import CairnCore
import SwiftData
import SwiftUI

enum SidebarItem: Hashable, Codable {
    case all
    case cairn
    case tag(String)
    case feed(PersistentIdentifier)
}

/// Sidebar entry shown and last article of each entry, kept on this Mac only (UserDefaults, not CloudKit).
struct SelectionMemory: Codable, Equatable {
    var item: SidebarItem? = .all
    var articles: [SidebarItem: PersistentIdentifier] = [:]

    private static let key = "selectionMemory"
    static func load() -> SelectionMemory {
        UserDefaults.standard.data(forKey: key).flatMap { try? JSONDecoder().decode(Self.self, from: $0) } ?? .init()
    }
    func save() { UserDefaults.standard.set(try? JSONEncoder().encode(self), forKey: Self.key) }
}

struct ContentView: View {
    @Environment(AppState.self) private var state
    @Query(sort: \Article.publishedAt, order: .reverse) private var articles: [Article]
    @Query private var feeds: [Feed]
    @Environment(\.modelContext) private var context
    @State private var memory = SelectionMemory.load()
    /// Article the user picked themself; only that one is marked read when shown.
    @State private var pickedID: PersistentIdentifier?
    @State private var unreadOnly = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var state = state
        NavigationSplitView {
            SidebarView(selection: Binding(get: { memory.item }, set: show))
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            articleList
                .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            if let article = articles.first(where: { $0.persistentModelID == displayedArticleID }) {
                ArticleDetailView(article: article, marksRead: article.persistentModelID == pickedID)
            } else {
                ContentUnavailableView("Aucun article sélectionné", systemImage: "doc.text")
            }
        }
        .onAppear {
            // A decoded PersistentIdentifier is == to the live one but hashes differently, so it would miss its
            // dictionary key: swap each for the live model's own identifier.
            let live = { (id: PersistentIdentifier) in context.model(for: id).persistentModelID }
            let liveItem = { (item: SidebarItem) -> SidebarItem in if case let .feed(id) = item { .feed(live(id)) } else { item } }
            memory = SelectionMemory(item: memory.item.map(liveItem), articles: Dictionary(
                memory.articles.map { (liveItem($0.key), live($0.value)) }, uniquingKeysWith: { first, _ in first }))
            // An entry saved at the last quit may be gone: deleted feed, tag no longer on a kept article.
            switch memory.item {
            case let .feed(id) where !feeds.contains { $0.persistentModelID == id }: memory.item = .all
            case let .tag(key) where !kept.contains { $0.tags?.contains { $0.key == key } ?? false }: memory.item = .all
            default: break
            }
            settleArticle()
        }
        .onChange(of: memory.item) { searchText = ""; settleArticle() }
        .onChange(of: memory) { memory.save() }
        .onChange(of: state.isSearchRequested) {
            guard state.isSearchRequested else { return }
            state.isSearchRequested = false
            if !isCairn { show(.cairn) }
            // The search field only exists in cairn views: focus it once the switch has rendered.
            Task { isSearchFocused = true }
        }
        .sheet(isPresented: $state.isAddingFeed) { AddFeedSheet() }
        .fileImporter(isPresented: $state.isImporting, allowedContentTypes: [.opml, .xml]) { state.importOPML($0) }
        .fileExporter(isPresented: $state.isExporting, document: state.exportDocument, contentType: .opml,
                      defaultFilename: "Cairn.opml") { result in
            if case let .failure(error) = result { state.message = error.localizedDescription }
        }
        .alert("Cairn", isPresented: Binding(get: { state.message != nil }, set: { if !$0 { state.message = nil } })) {
            Button("OK") {}
        } message: {
            Text(state.message ?? "")
        }
    }

    @ViewBuilder
    private var articleList: some View {
        // The List only calls this setter on a user pick (mouse or keyboard); nil is a deselection, not a pick.
        let selection = Binding(get: { displayedArticleID }, set: { memory.articles[entry] = $0; pickedID = $0 })
        let list = ArticleListView(articles: visibleArticles, selection: selection, unreadOnly: $unreadOnly)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem {
                    // The icon spins instead of being replaced: a ProgressView or a disabled button splits the item out
                    // of the toolbar capsule. A click while refreshing is ignored by refresh().
                    Button("Rafraîchir", systemImage: "arrow.clockwise") { Task { await state.refresh() } }
                        .symbolEffect(.rotate, options: .repeat(.continuous).speed(2.5), isActive: state.isRefreshing)
                        .help(state.isRefreshing ? "Rafraîchissement en cours" : "Rafraîchir tous les abonnements (⌘R)")
                }
            }
        if isCairn {
            list.searchable(text: $searchText, placement: .toolbar, prompt: "Rechercher dans le cairn")
                .searchFocused($isSearchFocused)
        } else {
            list
        }
    }

    private var entry: SidebarItem { memory.item ?? .all }

    /// Remembered article of the entry while it still exists, else the first one listed.
    private var displayedArticleID: PersistentIdentifier? {
        if let id = memory.articles[entry], articles.contains(where: { $0.persistentModelID == id }) { return id }
        return visibleArticles.first?.persistentModelID
    }

    private func show(_ item: SidebarItem?) {
        memory.item = item
        pickedID = nil
    }

    /// On entering an entry, a remembered article no longer listed gives way to the first one. Not done while
    /// reading, or the unread filter would hide the article just read and auto-show the next one.
    private func settleArticle() {
        if let id = memory.articles[entry], visibleArticles.contains(where: { $0.persistentModelID == id }) { return }
        memory.articles[entry] = visibleArticles.first?.persistentModelID
    }

    private var isCairn: Bool {
        switch memory.item {
        case .cairn, .tag: true
        default: false
        }
    }

    private var title: String {
        switch memory.item {
        case .all, nil: "Tous les articles"
        case .cairn: "Cairn"
        case let .tag(key): articles.lazy.flatMap { $0.tags ?? [] }.first { $0.key == key }?.name ?? "Tag"
        case let .feed(id): articles.first { $0.feed?.persistentModelID == id }?.feed?.title ?? "Abonnement"
        }
    }

    private var kept: [Article] {
        articles.filter(\.isKept).sorted { ($0.keptAt ?? .distantPast) > ($1.keptAt ?? .distantPast) }
    }

    private var visibleArticles: [Article] {
        var list: [Article] = switch memory.item {
        case .all, nil: articles
        case let .feed(id): articles.filter { $0.feed?.persistentModelID == id }
        case .cairn: Library.search(searchText, in: kept)
        case let .tag(key): Library.search(searchText, in: kept.filter { $0.tags?.contains { $0.key == key } ?? false })
        }
        if unreadOnly { list = list.filter { !$0.isRead } }
        return list
    }
}

struct ArticleListView: View {
    let articles: [Article]
    @Binding var selection: PersistentIdentifier?
    @Binding var unreadOnly: Bool
    @Environment(\.modelContext) private var context
    @State private var articleToDelete: Article?
    @State private var articleToUnkeep: Article?

    var body: some View {
        List(articles, selection: $selection) { article in
            HStack(spacing: 10) {
                // Hidden rather than removed when read, so every row keeps the same alignment.
                Circle().fill(.blue).frame(width: 8, height: 8)
                    .opacity(article.isRead ? 0 : 1)
                    .accessibilityLabel("Non lu")
                    .accessibilityHidden(article.isRead)
                SourceIcon(data: article.feed?.iconData ?? article.sourceIconData, side: SourceIcon.articleRowSide)
                VStack(alignment: .leading, spacing: 2) {
                    Text(article.title.isEmpty ? "Sans titre" : article.title)
                        .lineLimit(2)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if article.isKept { Image("cairn.fill").foregroundStyle(.tint) }
                        Text(article.sourceTitle).lineLimit(1)
                        Spacer()
                        Text(article.publishedAt, format: .relative(presentation: .named))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .contextMenu {
                KeepButton(article: article, articleToUnkeep: $articleToUnkeep)
                Button(article.isRead ? "Marquer comme non lu" : "Marquer comme lu") { article.isRead.toggle() }
                if article.feed == nil {
                    Divider()
                    Button("Supprimer l'article…", role: .destructive) { articleToDelete = article }
                }
            }
        }
        .onDeleteCommand {
            if let article = articles.first(where: { $0.persistentModelID == selection }), article.feed == nil {
                articleToDelete = article
            }
        }
        .confirmationDialog("Supprimer « \(articleToDelete?.title ?? "") » ?",
                            isPresented: Binding(get: { articleToDelete != nil }, set: { if !$0 { articleToDelete = nil } }),
                            presenting: articleToDelete) { article in
            Button("Supprimer", role: .destructive) {
                if selection == article.persistentModelID { selection = nil }
                Library.delete(article, context: context)
            }
        } message: { article in
            Text(article.isKept ? "Il sera retiré du cairn avec sa note et ses tags." : "Cette action est définitive.")
        }
        .unkeepConfirmation($articleToUnkeep)
        // shortcut: macOS List keeps a stale (clipped) height for rows inserted while it is on screen,
        // so it is rebuilt when articles arrive. Costs a scroll reset on refresh; drop once SwiftUI fixes it.
        .id(articles.count)
        .overlay {
            if articles.isEmpty { ContentUnavailableView("Aucun article", systemImage: "tray") }
        }
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: $unreadOnly) { Label("Non lus seulement", systemImage: "line.3.horizontal.decrease.circle") }
                    .help("N'afficher que les articles non lus")
                Button("Tout marquer comme lu", systemImage: "checkmark.circle") {
                    for article in articles { article.isRead = true }
                }
                .help("Marquer tous les articles de la liste comme lus")
            }
        }
    }
}
