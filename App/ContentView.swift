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
    /// Mac selection mode (iOS uses its edit mode): ticking never opens nor marks an article read, even a single one.
    @State private var isSelectionModeOn = false
    /// Digests selected together (two or more).
    @State private var multiDigests: Set<PersistentIdentifier> = []
    /// Digest the user picked themself, for the compact layout (see `isCompact`).
    @State private var pickedDigestID: PersistentIdentifier?
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    /// Article shown in a multi-feed list, which has no memory.
    @State private var multiFeedArticle: PersistentIdentifier?
    @State private var unreadOnly = false
    /// iOS: the add-feed alert's field.
    @State private var newFeedURL = ""
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
            } else if selectedArticles.count > 1 || isSelectionModeOn {
                ArticleSelectionView(articles: selectedArticles)
            } else if let article = articles.first(where: { $0.persistentModelID == displayedArticleID }) {
                ArticleDetailView(article: article, marksRead: article.persistentModelID == pickedID, query: searchText)
                    // iPhone: marking it unread means "later", so go back to the list (the iPad and Mac show it beside).
                    .onChange(of: article.isRead) { wasRead, isRead in if isCompact && wasRead && !isRead { pickedID = nil } }
            } else {
                ContentUnavailableView("Aucun article sélectionné", systemImage: "doc.text")
                    .toolbar { DisabledReaderToolbar() }
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
        .onChange(of: memory.item) {
            searchText = ""; multiArticles = []; multiDigests = []; pickedDigestID = nil; isSelectionModeOn = false
            settleArticle()
        }
        .onChange(of: multiFeeds) { searchText = ""; multiArticles = []; multiFeedArticle = nil; isSelectionModeOn = false }
        .onChange(of: memory) { memory.save() }
        .onChange(of: state.isSearchRequested) {
            guard state.isSearchRequested else { return }
            state.isSearchRequested = false
            isSearchFocused = true
        }
        // Same alert as "Nouveau dossier"; a failure (unreadable feed) comes back in the app's message alert.
        .alert("Ajouter un abonnement", isPresented: $state.isAddingFeed) {
            TextField("URL du flux", text: $newFeedURL, prompt: Text("https://exemple.com/feed.xml"))
                .autocorrectionDisabled()
                #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif
            Button("Annuler", role: .cancel) { newFeedURL = "" }
            Button("Ajouter") {
                let url = newFeedURL
                newFeedURL = ""
                Task {
                    do { try await state.addFeed(url) } catch { state.message = error.localizedDescription }
                }
            }
            .disabled(newFeedURL.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        #if os(iOS)
        .sheet(isPresented: $state.isShowingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Réglages")
                    .toolbar { Button("OK") { state.isShowingSettings = false } }
            }
        }
        #endif
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
            if picked.count > 1 || isSelectionModeOn { return Set(picked.map(\.persistentModelID)) }
            return Set([isCompact ? pickedID : displayedArticleID].compactMap { $0 })
        } set: { ids in
            if isSelectionModeOn {
                multiArticles = ids
                pickedID = nil
            } else if ids.isEmpty && (isCompact || !multiArticles.isEmpty) {
                // Back to the list, or a multiple selection dropped: keep the remembered article.
                multiArticles = []
                pickedID = nil
            } else if ids.count > 1 {
                multiArticles = ids
                pickedID = nil
            } else {
                multiArticles = []
                if isMultiFeed { multiFeedArticle = ids.first } else { memory.articles[entry] = ids.first }
                pickedID = ids.first
            }
        }
        ArticleListView(articles: visibleArticles, title: title, query: searchText, isCompact: isCompact,
                        selection: selection, isSelectionModeOn: $isSelectionModeOn, unreadOnly: $unreadOnly)
            .toolbar {
                #if os(macOS) // iOS refreshes by pulling the list down (and ⌘R on an iPad keyboard)
                ToolbarItem {
                    // The icon spins instead of being replaced: a ProgressView or a disabled button splits the item out
                    // of the toolbar capsule. A click while refreshing is ignored by refresh().
                    Button("Rafraîchir", systemImage: "arrow.clockwise") { Task { await state.refresh() } }
                        .symbolEffect(.rotate, options: .repeat(.continuous).speed(2.5), isActive: state.isRefreshing)
                        .help(state.isRefreshing ? "Rafraîchissement en cours" : "Rafraîchir tous les abonnements (⌘R)")
                }
                #endif
            }
            .searchable(text: $searchText, placement: .toolbar, prompt: "Rechercher")
            .searchFocused($isSearchFocused)
    }

    private var entry: SidebarItem { memory.item ?? .all }

    /// iPhone (or a narrow iPad window): the split view pushes whatever is selected, so only what the user tapped
    /// counts as selected; the remembered article would otherwise open full screen on its own.
    private var isCompact: Bool {
        #if os(iOS)
        sizeClass == .compact
        #else
        false
        #endif
    }

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
            if picked.count > 1 { return Set(picked.map(\.persistentModelID)) }
            return Set([isCompact ? pickedDigestID : displayedDigest?.persistentModelID].compactMap { $0 })
        } set: { ids in
            if isCompact && ids.isEmpty {
                pickedDigestID = nil
            } else if ids.count > 1 {
                multiDigests = ids
            } else {
                multiDigests = []
                memory.articles[.digests] = ids.first
                pickedDigestID = ids.first
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
    let title: String
    /// Current search, highlighted in the rows.
    let query: String
    /// The window's width class, from ContentView: the list's own is compact on an iPad too (a split view column).
    let isCompact: Bool
    @Binding var selection: Set<PersistentIdentifier>
    /// Mac only: selection mode turned on with the button (iOS uses its edit mode).
    @Binding var isSelectionModeOn: Bool
    @Binding var unreadOnly: Bool
    @Environment(\.modelContext) private var context
    @State private var articlesToDelete: [Article] = []
    @State private var articlesToUnkeep: [Article] = []
    @State private var articlesToOpen: [Article] = []
    @AppStorage("showListIcons") private var showListIcons = true
    @Environment(AppState.self) private var state
    #if os(iOS)
    @Environment(\.editMode) private var editMode
    #endif

    var body: some View {
        List(articles, selection: listSelection) { article in
            HStack(spacing: 10) {
                #if os(macOS)
                if isSelecting { SelectionMark(isTicked: selection.contains(article.persistentModelID)) }
                #endif
                // Hidden rather than removed when read, so every row keeps the same alignment.
                UnreadDot(isOnHighlight: isHighlighted(article))
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
                        if article.isKept { KeptMark(isOnHighlight: isHighlighted(article)) }
                        Text(article.sourceTitle).lineLimit(1)
                        Spacer()
                        Text(article.publishedAt, format: .relative(presentation: .named))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            #if os(macOS)
            .modifier(TickOnClick(isOn: isSelectionModeOn) { selection.formSymmetricDifference([article.persistentModelID]) })
            .modifier(TickedRow(isTicked: isSelectionModeOn && selection.contains(article.persistentModelID),
                                joinsAbove: isSelectionModeOn && isTicked(article, offset: -1),
                                joinsBelow: isSelectionModeOn && isTicked(article, offset: 1)))
            #endif
        }
        // It gets the selection when the clicked row is part of it, else that row alone.
        .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
            let lot = articles.filter { ids.contains($0.persistentModelID) }
            if !lot.isEmpty {
                ArticleMenuItems(articles: lot, articlesToUnkeep: $articlesToUnkeep, articlesToOpen: $articlesToOpen,
                                 articlesToDelete: $articlesToDelete)
            }
        }
        #if os(macOS)
        .onExitCommand { if isSelecting { leaveSelection() } }
        .safeAreaInset(edge: .bottom) {
            // The Mac's counterpart of the iPhone's bottom bar: the selection's actions under the list.
            if isSelecting {
                HStack(spacing: 22) {
                    SelectionActions(articles: selectedArticles, articlesToUnkeep: $articlesToUnkeep,
                                     articlesToOpen: $articlesToOpen, articlesToDelete: $articlesToDelete)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .font(.title2)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)
                .padding(.bottom, 10)
            }
        }
        .onDeleteCommand {
            let lot = articles.filter { selection.contains($0.persistentModelID) }
            if !lot.isEmpty, lot.allSatisfy({ $0.feed == nil }) { articlesToDelete = lot }
        }
        #endif
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
        .refreshable { await state.refresh() }
        .navigationTitle(listTitle)
        #if os(iOS)
        // Leaving selection mode drops what was ticked without an action. The reading pane follows the mode, as on the Mac.
        .onChange(of: editMode?.wrappedValue.isEditing) {
            let isEditing = editMode?.wrappedValue.isEditing == true
            if !isEditing { selection = [] }
            isSelectionModeOn = isEditing
        }
        #endif
        .toolbar {
            // A toggle, like the unread filter, so the toolbar shows it on. An icon rather than EditButton, whose
            // "Modifier" text outweighs the icon buttons next to it. Its own item: two toggles in one macOS toolbar
            // group act as one control, and switching the filter also switched selection mode.
            ToolbarItem {
                Toggle(isOn: Binding { isSelecting } set: { $0 ? enterSelection() : leaveSelection() }) {
                    Label("Sélectionner", systemImage: "checklist")
                }
                .help(isSelecting ? "Terminer la sélection (Échap)" : "Sélectionner des articles")
            }
            ToolbarItemGroup {
                Toggle(isOn: $unreadOnly) { Label("Non lus seulement", systemImage: "line.3.horizontal.decrease.circle") }
                    .help("N'afficher que les articles non lus")
                Button("Tout marquer comme lu", systemImage: "checkmark.circle") {
                    for article in articles { article.isRead = true }
                }
                .help("Marquer tous les articles de la liste comme lus")
            }
            #if os(iOS)
            selectionBar
            #endif
        }
    }

    private var isSelecting: Bool {
        #if os(iOS)
        editMode?.wrappedValue.isEditing == true
        #else
        isSelectionModeOn || selection.count > 1
        #endif
    }

    /// Whether the row sits on the blue selection highlight: on iOS, the selected row outside selection mode on a
    /// regular width (iOS's selection mode ticks rows in grey). The Mac relies on the prominence.
    private func isHighlighted(_ article: Article) -> Bool {
        #if os(iOS)
        !isSelecting && !isCompact && selection.contains(article.persistentModelID)
        #else
        false
        #endif
    }

        /// Whether the row `offset` rows away from `article` is ticked.
    private func isTicked(_ article: Article, offset: Int) -> Bool {
        guard selection.contains(article.persistentModelID),
              let index = articles.firstIndex(where: { $0.persistentModelID == article.persistentModelID }),
              articles.indices.contains(index + offset) else { return false }
        return selection.contains(articles[index + offset].persistentModelID)
    }

    /// Only what is still listed.
    private var selectedArticles: [Article] { articles.filter { selection.contains($0.persistentModelID) } }

    private func enterSelection() {
        #if os(iOS)
        withAnimation { editMode?.wrappedValue = .active }
        #else
        isSelectionModeOn = true
        #endif
    }

    /// Drops what was ticked without an action.
    private func leaveSelection() {
        #if os(iOS)
        withAnimation { editMode?.wrappedValue = .inactive } // the onChange clears the selection
        #else
        isSelectionModeOn = false
        selection = []
        #endif
    }

    /// In the Mac's selection mode the rows' own click ticks them (see `TickOnClick`), so the table selects
    /// nothing: its native selection waits before dropping a row of a multiple selection, in case of a drag.
    private var listSelection: Binding<Set<PersistentIdentifier>> {
        #if os(macOS)
        isSelectionModeOn ? .constant([]) : $selection
        #else
        $selection
        #endif
    }

    /// In selection mode, the count replaces the list's name, as in Mail.
    private var listTitle: String {
        guard isSelecting else { return title }
        let count = selectedArticles.count
        return count == 0 ? "Aucune sélection" : count == 1 ? "1 sélectionné" : "\(count) sélectionnés"
    }

    #if os(iOS)
    // The selection's actions under the list, as the Mac's capsule (iOS's edit mode draws the rows).
    @ToolbarContentBuilder private var selectionBar: some ToolbarContent {
        if isSelecting {
            ToolbarSpacer(.flexible, placement: .bottomBar)
            ToolbarItemGroup(placement: .bottomBar) {
                SelectionActions(articles: selectedArticles, articlesToUnkeep: $articlesToUnkeep,
                                 articlesToOpen: $articlesToOpen, articlesToDelete: $articlesToDelete)
            }
            ToolbarSpacer(.flexible, placement: .bottomBar)
        }
    }
    #endif
}

/// Actions on the ticked articles, under the list (Mac) or in the bottom bar (iPhone).
private struct SelectionActions: View {
    let articles: [Article]
    @Binding var articlesToUnkeep: [Article]
    @Binding var articlesToOpen: [Article]
    @Binding var articlesToDelete: [Article]
    @Environment(\.openURL) private var openURL

    var body: some View {
        let anyUnread = articles.contains { !$0.isRead }
        Group {
            KeepButton(articles: articles, articlesToUnkeep: $articlesToUnkeep)
            Button(anyUnread ? "Marquer comme lu" : "Marquer comme non lu",
                   systemImage: anyUnread ? "checkmark.circle" : "circle.inset.filled") {
                for article in articles { article.isRead = anyUnread }
            }
            .help(anyUnread ? "Marquer ces articles comme lus" : "Marquer ces articles comme non lus")
            Button("Ouvrir dans le navigateur", systemImage: "safari") {
                OpenInBrowser.open(articles, with: openURL, toConfirm: $articlesToOpen)
            }
            .help("Ouvrir ces articles dans le navigateur")
            // Only articles whose feed is gone can be deleted: a followed feed would bring them back.
            if !articles.isEmpty, articles.allSatisfy({ $0.feed == nil }) {
                Button("Supprimer", systemImage: "trash", role: .destructive) { articlesToDelete = articles }
                    .help("Supprimer ces articles")
            }
        }
        .disabled(articles.isEmpty)
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

/// Blue like Mail, white on a selected row where blue would vanish into the accent-colored highlight.
#if os(macOS)
/// In the Mac's selection mode, a click on the row ticks it. Added only then: a gesture on every row slows the list
/// down (rebuilding it on a filter change) and gets in the way of the table's own clicks.
private struct TickOnClick: ViewModifier {
    let isOn: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if isOn { content.contentShape(.rect).onTapGesture(perform: action) } else { content }
    }
}

/// A ticked row in the Mac's selection mode, drawn like the table's own selection (as after a ⌘-click): the table
/// selects nothing in that mode, its native selection being slow to drop a row. Ticked neighbours make one block,
/// rounded only at its ends.
private struct TickedRow: ViewModifier {
    let isTicked: Bool
    let joinsAbove: Bool
    let joinsBelow: Bool

    func body(content: Content) -> some View {
        if isTicked {
            let top: CGFloat = joinsAbove ? 0 : 8, bottom: CGFloat = joinsBelow ? 0 : 8
            content
                .foregroundStyle(.white)
                .environment(\.backgroundProminence, .increased) // white checkbox and unread dot, as on a selected row
                .listRowSeparator(.hidden)
                .listRowBackground(UnevenRoundedRectangle(topLeadingRadius: top, bottomLeadingRadius: bottom,
                                                          bottomTrailingRadius: bottom, topTrailingRadius: top)
                    .fill(Color(nsColor: .selectedContentBackgroundColor)).padding(.horizontal, 10))
        } else {
            content
        }
    }
}
#endif

/// The Mac's selection-mode checkbox: white on a highlighted (selected) row, where the tint would vanish.
private struct SelectionMark: View {
    let isTicked: Bool
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        Image(systemName: isTicked ? "checkmark.circle.fill" : "circle")
            .foregroundStyle(prominence == .increased ? AnyShapeStyle(.white)
                                                      : isTicked ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .accessibilityHidden(true)
    }
}

/// The cairn icon of a kept article's row: tinted, white on the blue selection highlight (like UnreadDot).
private struct KeptMark: View {
    var isOnHighlight = false
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        Image("cairn.fill")
            .foregroundStyle(isOnHighlight || prominence == .increased ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
    }
}

private struct UnreadDot: View {
    /// The row is drawn on the blue selection highlight (iPadOS does not always raise the prominence for it).
    var isOnHighlight = false
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        Circle().fill(isOnHighlight || prominence == .increased ? Color.white : Color.blue).frame(width: 8, height: 8)
    }
}
