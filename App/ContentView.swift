import CairnCore
import SwiftData
import SwiftUI

enum SidebarItem: Hashable, Codable {
    case all
    case digests
    case cairn(PersistentIdentifier)
    /// A tag shown under a cairn: the cairn, then the tag key.
    case tag(PersistentIdentifier, String)
    case feed(PersistentIdentifier)
    case folder(PersistentIdentifier)
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
    @Query private var folders: [Folder]
    @Query private var cairns: [Cairn]
    @Query(sort: \Digest.createdAt, order: .reverse) private var digests: [Digest]
    @Environment(\.modelContext) private var context
    @State private var memory = SelectionMemory.load()
    /// Article the user picked themself; only that one is marked read when shown.
    @State private var pickedID: PersistentIdentifier?
    // Multiple selections are never remembered: they live here, while `memory` keeps the last single ones.
    /// Feeds selected together in the sidebar (two or more), shown as one list.
    @State private var multiFeeds: Set<PersistentIdentifier> = []
    /// Articles selected together (two or more).
    @State private var multiArticles: Set<PersistentIdentifier> = []
    /// Digests selected together (two or more).
    @State private var multiDigests: Set<PersistentIdentifier> = []
    /// Article shown in a multi-feed list, which has no memory.
    @State private var multiFeedArticle: PersistentIdentifier?
    @State private var unreadOnly = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var state = state
        NavigationSplitView {
            SidebarView(selection: Binding(get: { sidebarSelection }, set: showSidebar))
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            Group {
                if entry == .digests {
                    DigestListView(digests: visibleDigests, query: searchText, selection: digestSelection)
                        .navigationTitle(title)
                        .searchable(text: $searchText, placement: .toolbar, prompt: "Rechercher")
                        .searchFocused($isSearchFocused)
                } else {
                    articleList
                }
            }
            .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            if entry == .digests {
                DigestDetail(digests: selectedDigests.count > 1 ? selectedDigests : displayedDigest.map { [$0] } ?? [],
                             query: searchText, hasDigests: !digests.isEmpty)
            } else if selectedArticles.count > 1 {
                ArticleSelectionView(articles: selectedArticles)
            } else if let article = articles.first(where: { $0.persistentModelID == displayedArticleID }) {
                ArticleDetailView(article: article, marksRead: article.persistentModelID == pickedID, query: searchText)
            } else {
                ContentUnavailableView("Aucun article sélectionné", systemImage: "doc.text")
            }
        }
        .onAppear {
            // A decoded PersistentIdentifier is == to the live one but hashes differently, so it would miss its
            // dictionary key: swap each for the live model's own identifier.
            let live = { (id: PersistentIdentifier) in context.model(for: id).persistentModelID }
            let liveItem = { (item: SidebarItem) -> SidebarItem in
                switch item {
                case let .feed(id): .feed(live(id))
                case let .folder(id): .folder(live(id))
                case let .cairn(id): .cairn(live(id))
                case let .tag(id, key): .tag(live(id), key)
                default: item
                }
            }
            memory = SelectionMemory(item: memory.item.map(liveItem), articles: Dictionary(
                memory.articles.map { (liveItem($0.key), live($0.value)) }, uniquingKeysWith: { first, _ in first }))
            // An entry saved at the last quit may be gone: deleted feed, tag no longer on a kept article.
            switch memory.item {
            case let .feed(id) where !feeds.contains { $0.persistentModelID == id }: memory.item = .all
            case let .folder(id) where !folders.contains { $0.persistentModelID == id }: memory.item = .all
            case let .cairn(id) where !cairns.contains { $0.persistentModelID == id }: memory.item = .all
            case let .tag(id, key) where !kept(in: id).contains { $0.tags?.contains { $0.key == key } ?? false }: memory.item = .all
            default: break
            }
            settleArticle()
        }
        .onChange(of: memory.item) { searchText = ""; multiArticles = []; multiDigests = []; settleArticle() }
        .onChange(of: multiFeeds) { searchText = ""; multiArticles = []; multiFeedArticle = nil }
        .onChange(of: memory) { memory.save() }
        .onChange(of: state.isSearchRequested) {
            guard state.isSearchRequested else { return }
            state.isSearchRequested = false
            isSearchFocused = true
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
        // The List only calls this setter on a user pick (mouse or keyboard). Only a single article is remembered and
        // marked read; an empty set is a deselection, not a pick.
        let selection = Binding<Set<PersistentIdentifier>> {
            let picked = selectedArticles
            return picked.count > 1 ? Set(picked.map(\.persistentModelID)) : Set([displayedArticleID].compactMap { $0 })
        } set: { ids in
            if ids.count > 1 {
                multiArticles = ids
                pickedID = nil
            } else {
                multiArticles = []
                if isMultiFeed { multiFeedArticle = ids.first } else { memory.articles[entry] = ids.first }
                pickedID = ids.first
            }
        }
        ArticleListView(articles: visibleArticles, query: searchText, selection: selection, unreadOnly: $unreadOnly)
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
            .searchable(text: $searchText, placement: .toolbar, prompt: "Rechercher")
            .searchFocused($isSearchFocused)
    }

    private var entry: SidebarItem { memory.item ?? .all }

    private var isMultiFeed: Bool { multiFeeds.count > 1 }

    private var sidebarSelection: Set<SidebarItem> {
        isMultiFeed ? Set(multiFeeds.map(SidebarItem.feed)) : Set([memory.item].compactMap { $0 })
    }

    /// Several feeds go together; any other entry is shown alone (see `SelectionRule`).
    private func showSidebar(_ new: Set<SidebarItem>) {
        let items = SelectionRule.restrict(old: sidebarSelection, new: new) { if case .feed = $0 { true } else { false } }
        let feedIDs = items.compactMap { if case let .feed(id) = $0 { id } else { nil } }
        if items.count > 1 {
            multiFeeds = Set(feedIDs)
            pickedID = nil
        } else {
            multiFeeds = []
            memory.item = items.first
            pickedID = nil
        }
    }

    /// Remembered article of the entry while it still exists, else the first one listed.
    private var displayedArticleID: PersistentIdentifier? {
        let remembered = isMultiFeed ? multiFeedArticle : memory.articles[entry]
        if let id = remembered, articles.contains(where: { $0.persistentModelID == id }) { return id }
        return visibleArticles.first?.persistentModelID
    }

    private var digestSelection: Binding<Set<PersistentIdentifier>> {
        Binding {
            let picked = selectedDigests
            return picked.count > 1 ? Set(picked.map(\.persistentModelID)) : Set([displayedDigest?.persistentModelID].compactMap { $0 })
        } set: { ids in
            if ids.count > 1 {
                multiDigests = ids
            } else {
                multiDigests = []
                memory.articles[.digests] = ids.first
            }
        }
    }

    /// On entering an entry, a remembered article no longer listed gives way to the first one. Not done while
    /// reading, or the unread filter would hide the article just read and auto-show the next one.
    private func settleArticle() {
        guard entry != .digests else { return }
        if let id = memory.articles[entry], visibleArticles.contains(where: { $0.persistentModelID == id }) { return }
        memory.articles[entry] = visibleArticles.first?.persistentModelID
    }

    private var visibleDigests: [Digest] { Library.search(searchText, in: digests) }

    // Only what is still listed: a lot action (delete, unkeep, mark read under the unread filter) can remove items
    // from the list without going through the List's selection setter.
    private var selectedArticles: [Article] { visibleArticles.filter { multiArticles.contains($0.persistentModelID) } }
    private var selectedDigests: [Digest] { visibleDigests.filter { multiDigests.contains($0.persistentModelID) } }

    /// Remembered digest while it is listed, else the newest one listed.
    private var displayedDigest: Digest? {
        let listed = visibleDigests
        return listed.first { $0.persistentModelID == memory.articles[.digests] } ?? listed.first
    }

    private var title: String {
        if isMultiFeed { return "\(multiFeeds.count) abonnements" }
        return switch memory.item {
        case .all, nil: "Tous les articles"
        case .digests: "Résumés quotidiens"
        case let .cairn(id): cairns.first { $0.persistentModelID == id }?.name ?? "Cairn"
        case let .tag(_, key): articles.lazy.flatMap { $0.tags ?? [] }.first { $0.key == key }?.name ?? "Tag"
        case let .feed(id): feeds.first { $0.persistentModelID == id }?.title ?? "Abonnement"
        case let .folder(id): folders.first { $0.persistentModelID == id }?.name ?? "Dossier"
        }
    }

    private func kept(in cairn: PersistentIdentifier) -> [Article] {
        articles.filter { $0.isKept && $0.cairn?.persistentModelID == cairn }
            .sorted { ($0.keptAt ?? .distantPast) > ($1.keptAt ?? .distantPast) }
    }

    private var visibleArticles: [Article] {
        var list: [Article] = if isMultiFeed {
            articles.filter { $0.feed.map { multiFeeds.contains($0.persistentModelID) } ?? false }
        } else {
            switch memory.item {
        case .all, nil: articles
        case .digests: []
        case let .feed(id): articles.filter { $0.feed?.persistentModelID == id }
        case let .folder(id): articles.filter { $0.feed?.folder?.persistentModelID == id }
        case let .cairn(id): kept(in: id)
        case let .tag(id, key): kept(in: id).filter { $0.tags?.contains { $0.key == key } ?? false }
            }
        }
        list = Library.search(searchText, in: list)
        if unreadOnly { list = list.filter { !$0.isRead } }
        return list
    }
}

struct ArticleListView: View {
    let articles: [Article]
    /// Current search, highlighted in the rows.
    let query: String
    @Binding var selection: Set<PersistentIdentifier>
    @Binding var unreadOnly: Bool
    @Environment(\.modelContext) private var context
    @State private var articlesToDelete: [Article] = []
    @State private var articlesToUnkeep: [Article] = []
    @State private var articlesToOpen: [Article] = []
    @AppStorage("showListIcons") private var showListIcons = true

    var body: some View {
        List(articles, selection: $selection) { article in
            HStack(spacing: 10) {
                // Hidden rather than removed when read, so every row keeps the same alignment.
                Circle().fill(.blue).frame(width: 8, height: 8)
                    .opacity(article.isRead ? 0 : 1)
                    .accessibilityLabel("Non lu")
                    .accessibilityHidden(article.isRead)
                if showListIcons {
                    SourceIcon(data: article.feed?.iconData ?? article.sourceIconData, side: SourceIcon.articleRowSide)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(AttributedString(article.title.isEmpty ? "Sans titre" : article.title, highlighting: query))
                        .lineLimit(2)
                    if let snippet = Library.snippet(for: query, in: article) {
                        Text(AttributedString(snippet, highlighting: query))
                            .font(.caption)
                            .lineLimit(2)
                    }
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
        }
        // It gets the selection when the clicked row is part of it, else that row alone.
        .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
            let lot = articles.filter { ids.contains($0.persistentModelID) }
            if !lot.isEmpty {
                ArticleMenuItems(articles: lot, articlesToUnkeep: $articlesToUnkeep, articlesToOpen: $articlesToOpen,
                                 articlesToDelete: $articlesToDelete)
            }
        }
        .onDeleteCommand {
            let lot = articles.filter { selection.contains($0.persistentModelID) }
            if !lot.isEmpty, lot.allSatisfy({ $0.feed == nil }) { articlesToDelete = lot }
        }
        .confirmationDialog(articlesToDelete.count == 1 ? "Supprimer « \(articlesToDelete[0].title) » ?"
                                                        : "Supprimer \(articlesToDelete.count) articles ?",
                            isPresented: Binding(get: { !articlesToDelete.isEmpty }, set: { if !$0 { articlesToDelete = [] } }),
                            presenting: articlesToDelete) { lot in
            Button("Supprimer", role: .destructive) {
                selection.subtract(lot.map(\.persistentModelID))
                for article in lot { Library.delete(article, context: context) }
            }
        } message: { lot in
            Text(lot.contains(where: \.isKept) ? (lot.count == 1 ? "Il sera retiré du cairn avec sa note et ses tags."
                                                                  : "Les articles gardés seront retirés du cairn avec leur note et leurs tags.")
                                               : "Cette action est définitive.")
        }
        .unkeepConfirmation($articlesToUnkeep)
        .openConfirmation($articlesToOpen)
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

extension AttributedString {
    /// `text` with every occurrence of the search query on a yellow background (same rule as the search).
    init(_ text: String, highlighting query: String) {
        self.init(text)
        highlight(query)
    }

    /// Puts every occurrence of the query on a yellow background, keeping existing styling (e.g. parsed Markdown).
    mutating func highlight(_ query: String) {
        let text = String(characters)
        for range in Library.matchRanges(of: query, in: text) {
            let start = characters.index(startIndex, offsetBy: text.distance(from: text.startIndex, to: range.lowerBound))
            let end = characters.index(start, offsetBy: text.distance(from: range.lowerBound, to: range.upperBound))
            self[start..<end].backgroundColor = .yellow.opacity(0.45)
        }
    }
}
