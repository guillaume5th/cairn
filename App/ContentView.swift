import CairnCore
import SwiftData
import SwiftUI

enum SidebarItem: Hashable, Codable {
    case all
    /// Articles published since local midnight.
    case today
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
    static let oldestFirstKey = "oldestFirst"
    @Environment(AppState.self) private var state
    @AppStorage(oldestFirstKey) private var oldestFirst = false
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
    /// Selection mode: ticking never opens nor marks an article read, even a single one.
    @State private var isSelectionModeOn = false
    /// Digests selected together (two or more).
    @State private var multiDigests: Set<PersistentIdentifier> = []
    /// Article shown in a multi-feed list, which has no memory.
    @State private var multiFeedArticle: PersistentIdentifier?
    @State private var unreadOnly = false
    /// The add-feed alert's field.
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
            } else {
                ContentUnavailableView("Aucun article sélectionné", systemImage: "doc.text")
                    .toolbar { ReaderToolbar.empty }
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
            searchText = ""; multiArticles = []; multiDigests = []; isSelectionModeOn = false
            settleArticle()
        }
        .onChange(of: multiFeeds) { searchText = ""; multiArticles = []; multiFeedArticle = nil; isSelectionModeOn = false }
        .onChange(of: memory) { memory.save() }
        .onChange(of: state.digestToOpen, initial: true) { openNotifiedDigest() }
        .onChange(of: state.keptArticleToOpen, initial: true) { openSpotlightResult() }
        .onChange(of: state.isSearchRequested) {
            guard state.isSearchRequested else { return }
            state.isSearchRequested = false
            isSearchFocused = true
        }
        .onOpenURL { url in
            guard let address = Library.address(fromFeedLink: url) else { return }
            newFeedURL = address
            state.isAddingFeed = true
        }
        // Same alert as "Nouveau dossier"; a failure (unreadable feed) comes back in the app's message alert.
        .alert("Ajouter un abonnement", isPresented: $state.isAddingFeed) {
            TextField("Adresse d'un site ou d'un flux", text: $newFeedURL, prompt: Text("exemple.com"))
                .autocorrectionDisabled()
            Button("Annuler", role: .cancel) { newFeedURL = "" }
            Button("Ajouter") {
                let url = newFeedURL
                newFeedURL = ""
                Task {
                    do { try await state.addFeed(url) } catch { state.message = error.localizedDescription }
                }
            }
            .disabled(newFeedURL.trimmingCharacters(in: .whitespaces).isEmpty)
        } message: {
            Text("Adresse d'un site ou de son flux RSS, Atom ou JSON Feed.")
        }
        // The address declares several feeds: the user picks one; feeds already followed cannot be picked again.
        .confirmationDialog("Ce site propose plusieurs flux", isPresented: Binding(get: { !state.feedChoices.isEmpty },
                                                                                  set: { if !$0 { state.feedChoices = [] } }),
                            titleVisibility: .visible, presenting: state.feedChoices) { feeds in
            ForEach(feeds) { feed in
                let followed = state.isSubscribed(feed.url)
                Button(Self.choiceLabel(feed, followed: followed)) {
                    Task {
                        do { try await state.subscribe(to: feed.url) } catch { state.message = error.localizedDescription }
                    }
                }
                .disabled(followed)
            }
            Button("Annuler", role: .cancel) {}
        } message: { _ in
            Text("Choisis le flux auquel t'abonner.")
        }
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
            return Set([displayedArticleID].compactMap { $0 })
        } set: { ids in
            if isSelectionModeOn {
                multiArticles = ids
                pickedID = nil
            } else if ids.isEmpty && !multiArticles.isEmpty {
                // A multiple selection dropped: keep the remembered article.
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
        ArticleListView(articles: visibleArticles, title: title, query: searchText,
                        selection: selection, isSelectionModeOn: $isSelectionModeOn, unreadOnly: $unreadOnly)
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

    /// Title and address; the address without its scheme and host, all choices being on the same site.
    private static func choiceLabel(_ feed: DiscoveredFeed, followed: Bool) -> String {
        let url = URL(string: feed.url)
        let path = url.map { $0.path() + ($0.query().map { "?\($0)" } ?? "") } ?? feed.url
        let label = feed.title.map { "\($0) — \(path)" } ?? feed.url
        return followed ? label + " (déjà suivi)" : label
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

    /// Remembered article of the entry while it still exists, else none: the pane shows its greyed reader buttons.
    private var displayedArticleID: PersistentIdentifier? {
        let remembered = isMultiFeed ? multiFeedArticle : memory.articles[entry]
        if let id = remembered, articles.contains(where: { $0.persistentModelID == id }) { return id }
        return nil
    }

    private var digestSelection: Binding<Set<PersistentIdentifier>> {
        Binding {
            let picked = selectedDigests
            if picked.count > 1 { return Set(picked.map(\.persistentModelID)) }
            return Set([displayedDigest?.persistentModelID].compactMap { $0 })
        } set: { ids in
            if ids.count > 1 {
                multiDigests = ids
            } else {
                multiDigests = []
                memory.articles[.digests] = ids.first
            }
        }
    }

    /// Shows a kept article chosen in Spotlight, in its cairn.
    private func openSpotlightResult() {
        guard let link = state.keptArticleToOpen else { return }
        state.keptArticleToOpen = nil
        guard let article = articles.first(where: { $0.isKept && $0.link == link }), let cairn = article.cairn else { return }
        multiFeeds = []
        memory.item = .cairn(cairn.persistentModelID)
        memory.articles[.cairn(cairn.persistentModelID)] = article.persistentModelID
    }

    /// Shows the digest of a tapped notification: the "Résumés quotidiens" entry, that digest selected.
    private func openNotifiedDigest() {
        guard let id = state.digestToOpen else { return }
        state.digestToOpen = nil
        memory.item = .digests
        memory.articles[.digests] = id
    }

    /// On entering an entry, a remembered article no longer listed is forgotten. Not done while reading, or the
    /// unread filter would hide the article just read.
    private func settleArticle() {
        guard entry != .digests else { return }
        if let id = memory.articles[entry], visibleArticles.contains(where: { $0.persistentModelID == id }) { return }
        memory.articles[entry] = nil
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
        case .today: "Aujourd'hui"
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
        // shortcut: not recomputed at midnight by itself, only on the next change; add a day timer if that matters.
        case .today: articles.filter { $0.publishedAt >= Calendar.current.startOfDay(for: .now) }
        case .digests: []
        case let .feed(id): articles.filter { $0.feed?.persistentModelID == id }
        case let .folder(id): articles.filter { $0.feed?.folder?.persistentModelID == id }
        case let .cairn(id): kept(in: id)
        case let .tag(id, key): kept(in: id).filter { $0.tags?.contains { $0.key == key } ?? false }
            }
        }
        list = Library.search(searchText, in: list)
        if unreadOnly { list = list.filter { !$0.isRead } }
        return oldestFirst ? list.reversed() : list
    }
}

struct ArticleListView: View {
    let articles: [Article]
    let title: String
    /// Current search, highlighted in the rows.
    let query: String
    @Binding var selection: Set<PersistentIdentifier>
    /// Selection mode, turned on with the button.
    @Binding var isSelectionModeOn: Bool
    @Binding var unreadOnly: Bool
    @Environment(\.modelContext) private var context
    @State private var articlesToDelete: [Article] = []
    @State private var articlesToUnkeep: [Article] = []
    @State private var articlesToOpen: [Article] = []
    @AppStorage("showListIcons") private var showListIcons = true
    @Environment(AppState.self) private var state

    var body: some View {
        ScrollViewReader { proxy in list.onKeyPress(keys: [.space, "n"]) { _ in openNextUnread(proxy) } }
    }

    /// Space or N, while the list has the focus (the article and text fields keep their own Space).
    private func openNextUnread(_ proxy: ScrollViewProxy) -> KeyPress.Result {
        guard !isSelecting else { return .ignored }
        let current = selection.count == 1 ? selection.first : nil
        guard let next = Library.nextUnread(after: current, in: articles) else {
            NSSound.beep()
            return .handled
        }
        selection = [next.persistentModelID] // as a click: remembered and marked read
        proxy.scrollTo(next.persistentModelID)
        return .handled
    }

    private var list: some View {
        List(articles, selection: listSelection) { article in
            HStack(spacing: 10) {
                if isSelecting { SelectionMark(isTicked: selection.contains(article.persistentModelID)) }
                // Hidden rather than removed when read, so every row keeps the same alignment.
                UnreadDot()
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
                        if article.isKept { KeptMark() }
                        Text(article.sourceTitle).lineLimit(1)
                        Spacer()
                        Text(article.publishedAt, format: .relative(presentation: .named))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 2)
            .modifier(TickOnClick(isOn: isSelectionModeOn) { selection.formSymmetricDifference([article.persistentModelID]) })
        }
        // It gets the selection when the clicked row is part of it, else that row alone.
        .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
            let lot = articles.filter { ids.contains($0.persistentModelID) }
            if !lot.isEmpty {
                ArticleMenuItems(articles: lot, articlesToUnkeep: $articlesToUnkeep, articlesToOpen: $articlesToOpen,
                                 articlesToDelete: $articlesToDelete)
            }
        }
        .onExitCommand { if isSelecting { leaveSelection() } }
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
        .focusedSceneValue(\.articleSelection, ArticleSelection(articles: selectedArticles, articlesToUnkeep: $articlesToUnkeep,
                                                               articlesToOpen: $articlesToOpen, articlesToDelete: $articlesToDelete))
        .overlay {
            if articles.isEmpty { ContentUnavailableView("Aucun article", systemImage: "tray") }
        }
        .navigationTitle(listTitle)
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
        }
    }

    private var isSelecting: Bool {
        isSelectionModeOn || selection.count > 1
    }

    /// Only what is still listed.
    private var selectedArticles: [Article] { articles.filter { selection.contains($0.persistentModelID) } }

    /// In the Mac's selection mode the rows' own click ticks them (see `TickOnClick`): the table shows the ticked
    /// rows as its selection but its own changes are ignored, a plain click replacing the whole selection there.
    private var listSelection: Binding<Set<PersistentIdentifier>> {
        isSelectionModeOn ? Binding { selection } set: { _ in } : $selection
    }

    private func enterSelection() {
        isSelectionModeOn = true
    }

    /// Drops what was ticked without an action.
    private func leaveSelection() {
        isSelectionModeOn = false
        selection = []
    }

    /// In selection mode, the count replaces the list's name, as in Mail.
    private var listTitle: String {
        guard isSelecting else { return title }
        let count = selectedArticles.count
        return count == 0 ? "Aucune sélection" : count == 1 ? "1 sélectionné" : "\(count) sélectionnés"
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

/// In the Mac's selection mode, a click on the row ticks it. Added only then: a gesture on every row slows the list
/// down (rebuilding it on a filter change) and gets in the way of the table's own clicks.
private struct TickOnClick: ViewModifier {
    let isOn: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if isOn { content.contentShape(.rect).onTapGesture(perform: action) } else { content }
    }
}

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
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        Image("cairn.fill")
            .foregroundStyle(prominence == .increased ? AnyShapeStyle(.white) : AnyShapeStyle(.tint))
    }
}

/// The accent color, like Mail, white on a selected row where it would vanish into the highlight.
private struct UnreadDot: View {
    @Environment(\.backgroundProminence) private var prominence

    var body: some View {
        Circle().fill(prominence == .increased ? Color.white : Color.accentColor).frame(width: 8, height: 8)
    }
}
