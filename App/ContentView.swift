import CairnCore
import SwiftData
import SwiftUI

enum SidebarItem: Hashable {
    case all
    case cairn
    case tag(String)
    case feed(PersistentIdentifier)
}

struct ContentView: View {
    @Environment(AppState.self) private var state
    @Query(sort: \Article.publishedAt, order: .reverse) private var articles: [Article]
    @State private var selection: SidebarItem? = .all
    @State private var selectedArticleID: PersistentIdentifier?
    @State private var unreadOnly = false
    @State private var searchText = ""
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        @Bindable var state = state
        NavigationSplitView {
            SidebarView(selection: $selection)
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            articleList
                .navigationSplitViewColumnWidth(min: 260, ideal: 340)
        } detail: {
            if let article = articles.first(where: { $0.persistentModelID == selectedArticleID }) {
                ArticleDetailView(article: article)
            } else {
                ContentUnavailableView("Aucun article sélectionné", systemImage: "doc.text")
            }
        }
        .onChange(of: selection) { selectedArticleID = nil; searchText = "" }
        .onChange(of: state.isSearchRequested) {
            guard state.isSearchRequested else { return }
            state.isSearchRequested = false
            if !isCairn { selection = .cairn }
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
        let list = ArticleListView(articles: visibleArticles, selection: $selectedArticleID, unreadOnly: $unreadOnly)
            .navigationTitle(title)
            .toolbar {
                if state.isRefreshing {
                    ToolbarItem { ProgressView().controlSize(.small).help("Rafraîchissement en cours") }
                }
            }
        if isCairn {
            list.searchable(text: $searchText, placement: .toolbar, prompt: "Rechercher dans le cairn")
                .searchFocused($isSearchFocused)
        } else {
            list
        }
    }

    private var isCairn: Bool {
        switch selection {
        case .cairn, .tag: true
        default: false
        }
    }

    private var title: String {
        switch selection {
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
        var list: [Article] = switch selection {
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

    var body: some View {
        List(articles, selection: $selection) { article in
            VStack(alignment: .leading, spacing: 2) {
                Text(article.title.isEmpty ? "Sans titre" : article.title)
                    .fontWeight(article.isRead ? .regular : .semibold)
                    .lineLimit(2)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if article.isKept { Image("cairn.fill").foregroundStyle(.tint) }
                    SourceIcon(data: article.feed?.iconData ?? article.sourceIconData)
                    Text(article.sourceTitle).lineLimit(1)
                    Spacer()
                    Text(article.publishedAt, format: .relative(presentation: .named))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, 2)
            .contextMenu {
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
