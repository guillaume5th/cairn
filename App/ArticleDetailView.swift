import CairnCore
import SwiftData
import SwiftUI

struct ArticleDetailView: View {
    @Bindable var article: Article
    /// False when the article was selected automatically: it is shown without being marked read.
    let marksRead: Bool
    /// Current search, highlighted in the title and the content.
    var query = ""
    @Environment(\.openURL) private var openURL
    @Environment(AppState.self) private var state
    @State private var articlesToUnkeep: [Article] = []
    @State private var articlesToOpen: [Article] = []
    @AppStorage(TextScale.key) private var textScale = 1.0
    /// Hidden summaries stay hidden from one article to the next, like a collapsed section.
    @AppStorage("articleSummaryHidden") private var summaryHidden = false
    /// True while part of the summary is below its scroll view: macOS hides scroll bars until one scrolls.
    @State private var summaryHasMore = false
    @State private var summaryScroll = ScrollPosition()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AttributedString(article.title.isEmpty ? "Sans titre" : article.title, highlighting: query))
                    // 17 pt and 13 pt are .title2 and .body on macOS, scaled: system text styles do not scale there.
                    .font(.system(size: 17 * textScale, weight: .bold))
                    .textSelection(.enabled)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    SourceIcon(data: article.feed?.iconData ?? article.sourceIconData)
                    Text("\(article.sourceTitle) · \(article.publishedAt.formatted(date: .abbreviated, time: .shortened))")
                }
                .font(.system(size: 13 * textScale))
                .foregroundStyle(.secondary)
            }
            .padding()
            Divider()
            fullContentStatus
            summaryBox

            if let html = Library.displayedContent(article) {
                HTMLView(html: html, baseURL: url, query: query)
            } else {
                ContentUnavailableView {
                    Label("Aucun contenu", systemImage: "doc")
                } description: {
                    Text("Le flux ne fournit pas de contenu pour cet article.")
                } actions: {
                    if let url { Button("Ouvrir dans le navigateur") { openURL(url) } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if article.isKept {
                Divider()
                KeptEditor(article: article).padding()
            }
        }
        .toolbar {
            ReaderToolbar(articles: [article], articlesToUnkeep: $articlesToUnkeep, articlesToOpen: $articlesToOpen) {
                // A toggle, like the list's filter: on while the full text is shown; turning it on loads it if needed.
                Toggle(isOn: Binding { article.fullContent != nil && !article.showsFeedContent } set: { showFullContent($0) }) {
                    Label("Article complet", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(url == nil || isLoadingFullContent)
                .help(url == nil ? "Cet article n'a pas de lien web"
                      : article.fullContent == nil ? "Charger l'article complet depuis son site"
                      : article.showsFeedContent ? "Afficher l'article complet" : "Afficher le contenu du flux")
                Button(article.summary == nil ? "Résumer" : "Régénérer le résumé", systemImage: "text.append") { summarize() }
                    .disabled((Library.readableContent(article) ?? "").isEmpty || isSummarizing)
                    .help((Library.readableContent(article) ?? "").isEmpty ? "Le flux ne fournit pas de contenu à résumer"
                          : article.summary == nil ? "Résumer cet article avec l'IA" : "Refaire le résumé de cet article")
            }
        }
        .unkeepConfirmation($articlesToUnkeep)
        .openConfirmation($articlesToOpen)
        .task(id: article.persistentModelID) {
            if marksRead { article.isRead = true }
            // The view is reused across articles: start each summary at its top.
            summaryScroll.scrollTo(edge: .top)
        }
    }

    private var isSummarizing: Bool { state.summarizing.contains(article.persistentModelID) }
    private var isLoadingFullContent: Bool { state.loadingFullContent.contains(article.persistentModelID) }

    /// On: the full text, loaded first when the article has none. Off: back to the feed's content (the text is kept).
    private func showFullContent(_ on: Bool) {
        if on, article.fullContent == nil {
            let article = article
            Task { await state.loadFullContent(article) }
        } else {
            article.showsFeedContent = !on
        }
    }

    /// Progress of the full-text load, or its failure with a way out.
    @ViewBuilder
    private var fullContentStatus: some View {
        if isLoadingFullContent {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Chargement de l'article complet…").foregroundStyle(.secondary)
            }
            .font(.callout)
            .padding([.horizontal, .top])
        } else if let error = state.fullContentErrors[article.persistentModelID] {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
                Spacer()
                Button("Réessayer") { showFullContent(true) }
                if let url { Button("Ouvrir dans le navigateur") { openURL(url) } }
            }
            .font(.callout)
            .padding([.horizontal, .top])
        }
    }

    /// Not tied to the view: switching articles does not cancel it, and the result goes to this article.
    private func summarize() {
        let article = article
        Task { await state.summarize(article) }
    }

    /// The article's AI summary, its progress or its failure, above the content.
    @ViewBuilder
    private var summaryBox: some View {
        let error = state.summaryErrors[article.persistentModelID]
        if article.summary != nil || isSummarizing || error != nil {
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Button(summaryHidden ? "Afficher le résumé" : "Masquer le résumé",
                               systemImage: summaryHidden ? "chevron.right" : "chevron.down") { summaryHidden.toggle() }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .help(summaryHidden ? "Afficher le résumé" : "Masquer le résumé")
                            .accessibilityLabel(summaryHidden ? "Afficher le résumé" : "Masquer le résumé")
                        Text(summaryHeader).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        if isSummarizing {
                            ProgressView().controlSize(.small)
                        } else {
                            Button(article.summary == nil ? "Réessayer" : "Régénérer", systemImage: "arrow.clockwise") { summarize() }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .help(article.summary == nil ? "Réessayer le résumé" : "Régénérer le résumé")
                                .accessibilityLabel(article.summary == nil ? "Réessayer" : "Régénérer")
                            if article.summary != nil {
                                Button("Supprimer le résumé", systemImage: "trash") { deleteSummary() }
                                    .labelStyle(.iconOnly)
                                    .buttonStyle(.borderless)
                                    .help("Supprimer le résumé de cet article")
                                    .accessibilityLabel("Supprimer le résumé")
                            }
                        }
                    }
                    if !summaryHidden {
                    if let summary = article.summary {
                        let text = VStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(summary.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                                MarkdownLine(line: line)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                        // As tall as the text up to a limit, then scrolls, so the article stays in view.
                        ScrollView { text }
                            .scrollBounceBehavior(.basedOnSize)
                            .scrollPosition($summaryScroll)
                            .onScrollGeometryChange(for: Bool.self) { $0.visibleRect.maxY < $0.contentSize.height - 1 } action: { _, hasMore in
                                summaryHasMore = hasMore
                            }
                            .frame(maxHeight: 220)
                            .fixedSize(horizontal: false, vertical: true)
                            .mask {
                                VStack(spacing: 0) {
                                    Rectangle()
                                    LinearGradient(colors: [.black, .black.opacity(summaryHasMore ? 0 : 1)], startPoint: .top, endPoint: .bottom)
                                        .frame(height: 32)
                                }
                            }
                            .overlay(alignment: .bottom) {
                                if summaryHasMore {
                                    Button("Lire la suite du résumé", systemImage: "chevron.down") {
                                        withAnimation { summaryScroll.scrollTo(edge: .bottom) }
                                    }
                                    .labelStyle(.iconOnly)
                                    .buttonStyle(.borderless)
                                    .help("Lire la suite du résumé")
                                }
                            }
                            .animation(.default, value: summaryHasMore)
                    }
                    if let error {
                        Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
                    }
                    if Library.isExcerpt(article) {
                        Text("Résumé de l'extrait fourni par le flux").font(.caption).foregroundStyle(.secondary)
                    }
                    }
                }
                .padding(4)
            }
            .padding([.horizontal, .top])
        }
    }

    private func deleteSummary() {
        article.summary = nil
        article.summaryDate = nil
        article.summaryEngine = nil
        state.summaryErrors[article.persistentModelID] = nil
        state.save()
    }

    private var summaryHeader: String {
        guard let date = article.summaryDate, article.summary != nil else { return isSummarizing ? "Résumé en cours…" : "Résumé" }
        return ["Résumé", date.formatted(date: .abbreviated, time: .shortened), article.summaryEngine].compactMap(\.self).joined(separator: " · ")
    }

    private var url: URL? {
        URL(string: article.link).flatMap { ["http", "https"].contains($0.scheme?.lowercased()) ? $0 : nil }
    }
}

/// Keep / unkeep control for one or more articles, shared by the reader toolbar, the selection summary and the
/// article context menu. With one cairn it is a toggle; with several, a menu of the cairns (checked when every
/// article is in it; picking one keeps them all there, moving those kept elsewhere). « Retirer du cairn » is offered
/// only when every article is kept; unkeeping articles with a note or tags goes through `unkeepConfirmation`.
struct KeepButton: View {
    let articles: [Article]
    @Binding var articlesToUnkeep: [Article]
    @Query(sort: \Cairn.name) private var cairns: [Cairn]

    var body: some View {
        let allKept = !articles.isEmpty && articles.allSatisfy(\.isKept)
        let icon = ImageResource(name: allKept ? "cairn.fill" : "cairn", bundle: .main)
        if cairns.count > 1 {
            Menu {
                ForEach(cairns) { cairn in
                    Toggle(cairn.name, isOn: Binding {
                        articles.allSatisfy { $0.cairn?.persistentModelID == cairn.persistentModelID }
                    } set: { isOn in
                        if isOn { for article in articles { Library.keep(article, in: cairn) } }
                    })
                }
                if allKept {
                    Divider()
                    Button("Retirer du cairn", role: .destructive, action: unkeep)
                }
            } label: {
                Label("Garder dans", image: icon)
            }
            // Without the arrow, the menu looks and sits like the other reader buttons.
            .menuIndicator(.hidden)
            .help(articles.count == 1 ? "Choisir le cairn de cet article" : "Choisir le cairn de ces articles")
        } else {
            Button(allKept ? "Retirer du cairn" : "Garder dans le cairn", image: icon) {
                if allKept {
                    unkeep()
                } else if let cairn = cairns.first {
                    for article in articles where !article.isKept { Library.keep(article, in: cairn) }
                }
            }
            .help(allKept ? "Retirer du cairn" : "Garder dans le cairn")
        }
    }

    private func unkeep() {
        if articles.allSatisfy({ $0.note.isEmpty && ($0.tags ?? []).isEmpty }) {
            for article in articles { Library.unkeep(article) }
        } else {
            articlesToUnkeep = articles
        }
    }
}

extension View {
    /// Confirms unkeeping articles of which at least one has a note or tags, which are lost.
    func unkeepConfirmation(_ articles: Binding<[Article]>) -> some View {
        let lot = articles.wrappedValue
        let losing = lot.count { !$0.note.isEmpty || !($0.tags ?? []).isEmpty }
        return confirmationDialog(lot.count == 1 ? "Retirer cet article du cairn ?" : "Retirer ces \(lot.count) articles du cairn ?",
                                  isPresented: Binding(get: { !lot.isEmpty }, set: { if !$0 { articles.wrappedValue = [] } }),
                                  presenting: lot) { lot in
            Button("Retirer", role: .destructive) { for article in lot { Library.unkeep(article) } }
        } message: { lot in
            Text(lot.count == 1 ? "Sa note et ses tags seront perdus."
                 : losing == 1 ? "1 article perdra sa note ou ses tags." : "\(losing) articles perdront leur note ou leurs tags.")
        }
    }

    /// Confirms opening more than `OpenInBrowser.confirmAbove` articles at once.
    func openConfirmation(_ articles: Binding<[Article]>) -> some View {
        modifier(OpenConfirmation(articles: articles))
    }
}

/// Opens the links of articles in the default browser.
@MainActor
enum OpenInBrowser {
    static let confirmAbove = 10

    static func url(of article: Article) -> URL? {
        URL(string: article.link).flatMap { ["http", "https"].contains($0.scheme?.lowercased()) ? $0 : nil }
    }

    /// Opens them, or asks first (through `toConfirm`, see `openConfirmation`) when there are many.
    static func open(_ articles: [Article], with openURL: OpenURLAction, toConfirm: Binding<[Article]>) {
        if articles.count > confirmAbove {
            toConfirm.wrappedValue = articles
        } else {
            for article in articles { if let url = url(of: article) { openURL(url) } }
        }
    }
}

private struct OpenConfirmation: ViewModifier {
    @Binding var articles: [Article]
    @Environment(\.openURL) private var openURL

    func body(content: Content) -> some View {
        content.confirmationDialog("Ouvrir \(articles.count) articles dans le navigateur ?",
                                   isPresented: Binding(get: { !articles.isEmpty }, set: { if !$0 { articles = [] } }),
                                   presenting: articles) { lot in
            Button("Ouvrir") { for article in lot { if let url = OpenInBrowser.url(of: article) { openURL(url) } } }
        }
    }
}

/// Actions on one or more articles (the clicked one, or the selection holding it), shared by their context menu and
/// the Article menu, so both list the same actions in the same order with the same shortcuts.
struct ArticleMenuItems: View {
    let articles: [Article]
    @Binding var articlesToUnkeep: [Article]
    @Binding var articlesToOpen: [Article]
    @Binding var articlesToDelete: [Article]
    @Environment(\.openURL) private var openURL

    var body: some View {
        let anyUnread = articles.contains { !$0.isRead }
        let links = articles.compactMap(OpenInBrowser.url(of:))
        Group {
            // ⇧⌘L and ⇧⌘U as Mail's Flag and Mark as Unread.
            KeepButton(articles: articles, articlesToUnkeep: $articlesToUnkeep)
                .keyboardShortcut("l", modifiers: [.command, .shift])
            Button(anyUnread ? "Marquer comme lu" : "Marquer comme non lu") { for article in articles { article.isRead = anyUnread } }
                .keyboardShortcut("u", modifiers: [.command, .shift])
            if articles.count == 1 {
                // Text only, like the other items: the menu bar would otherwise show its icon alone.
                ShareButton(article: articles[0]).labelStyle(.titleOnly)
            }
            Button("Ouvrir dans le navigateur") { OpenInBrowser.open(articles, with: openURL, toConfirm: $articlesToOpen) }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(links.isEmpty)
            Button(links.count > 1 ? "Copier les liens" : "Copier le lien") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(links.map(\.absoluteString).joined(separator: "\n"), forType: .string)
            }
            .disabled(links.isEmpty)
            // Only articles whose feed is gone can be deleted: a followed feed would bring them back.
            if !articles.isEmpty, articles.allSatisfy({ $0.feed == nil }) {
                Divider()
                Button(articles.count == 1 ? "Supprimer l'article…" : "Supprimer \(articles.count) articles…", role: .destructive) {
                    articlesToDelete = articles
                }
            }
        }
        .disabled(articles.isEmpty)
    }
}

/// The article list's selection and its confirmations, for the Article menu.
struct ArticleSelection {
    let articles: [Article]
    let articlesToUnkeep: Binding<[Article]>
    let articlesToOpen: Binding<[Article]>
    let articlesToDelete: Binding<[Article]>
}

extension FocusedValues {
    @Entry var articleSelection: ArticleSelection?
}

/// The Article menu: the actions of the selected or displayed articles, greyed out without an article list.
struct ArticleCommands: View {
    let context: ModelContext
    @FocusedValue(\.articleSelection) private var selection

    var body: some View {
        if let selection {
            ArticleMenuItems(articles: selection.articles, articlesToUnkeep: selection.articlesToUnkeep,
                             articlesToOpen: selection.articlesToOpen, articlesToDelete: selection.articlesToDelete)
                .modelContext(context) // for KeepButton's cairns: menus are outside the window's container
        } else {
            ArticleMenuItems(articles: [], articlesToUnkeep: .constant([]), articlesToOpen: .constant([]),
                             articlesToDelete: .constant([]))
                .modelContext(context)
        }
    }
}

/// The system share sheet with the article's title and link; greyed out without a web link.
struct ShareButton: View {
    let article: Article

    var body: some View {
        if let url = OpenInBrowser.url(of: article) {
            link(url)
        } else {
            Button("Partager", systemImage: "square.and.arrow.up") {}
                .disabled(true)
                .help("Cet article n'a pas de lien web")
        }
    }

    private func link(_ url: URL) -> some View {
        ShareLink(item: url, subject: Text(article.title), message: Text(article.title)) {
            Label("Partager", systemImage: "square.and.arrow.up")
        }
        .help("Partager cet article")
    }
}

/// Reading pane for several selected articles: their count, and the reader's toolbar acting on them.
struct ArticleSelectionView: View {
    let articles: [Article]
    @State private var articlesToUnkeep: [Article] = []
    @State private var articlesToOpen: [Article] = []

    var body: some View {
        ContentUnavailableView(articles.isEmpty ? "Aucun article sélectionné"
                                   : articles.count == 1 ? "1 article sélectionné" : "\(articles.count) articles sélectionnés",
                               systemImage: "doc.on.doc")
            .toolbar { ReaderToolbar(articles: articles, articlesToUnkeep: $articlesToUnkeep, articlesToOpen: $articlesToOpen) }
            .unkeepConfirmation($articlesToUnkeep)
            .openConfirmation($articlesToOpen)
    }
}

/// The reader's toolbar, the same in every state of the pane so that it never changes layout (as Mail does): one
/// article, several (filing and leaving act on all of them, reading and sharing are greyed out) or none (all greyed
/// out). Without it, an empty pane would let the list's buttons slide to the window's trailing edge.
struct ReaderToolbar<Reading: View>: ToolbarContent {
    let articles: [Article]
    @Binding var articlesToUnkeep: [Article]
    @Binding var articlesToOpen: [Article]
    /// Full article and summary, which only make sense for one article.
    @ViewBuilder let reading: Reading
    @Environment(\.openURL) private var openURL

    var body: some ToolbarContent {
        let anyUnread = articles.contains { !$0.isRead }
        ToolbarItemGroup {
            // Reading first, then filing, then leaving the app last.
            reading
            Group {
                KeepButton(articles: articles, articlesToUnkeep: $articlesToUnkeep)
                // The filled dot the list shows on unread rows.
                Button(anyUnread ? "Marquer comme lu" : "Marquer comme non lu",
                       systemImage: anyUnread ? "checkmark.circle" : "circle.inset.filled") {
                    for article in articles { article.isRead = anyUnread }
                }
                .help(anyUnread ? "Marquer comme lu" : "Marquer comme non lu")
            }
            .disabled(articles.isEmpty)
            if articles.count == 1 {
                ShareButton(article: articles[0])
            } else {
                Button("Partager", systemImage: "square.and.arrow.up") {}.disabled(true)
            }
            Button("Ouvrir dans le navigateur", systemImage: "safari") {
                OpenInBrowser.open(articles, with: openURL, toConfirm: $articlesToOpen)
            }
            .disabled(!articles.contains { OpenInBrowser.url(of: $0) != nil })
            .help("Ouvrir dans le navigateur")
        }
    }
}

extension ReaderToolbar where Reading == DisabledReadingButtons {
    /// For several articles or none: the reading buttons greyed out.
    init(articles: [Article], articlesToUnkeep: Binding<[Article]>, articlesToOpen: Binding<[Article]>) {
        self.init(articles: articles, articlesToUnkeep: articlesToUnkeep, articlesToOpen: articlesToOpen) {
            DisabledReadingButtons()
        }
    }

    /// For a pane without an article.
    static var empty: Self { Self(articles: [], articlesToUnkeep: .constant([]), articlesToOpen: .constant([])) }
}

struct DisabledReadingButtons: View {
    var body: some View {
        Group {
            Button("Article complet", systemImage: "doc.text.magnifyingglass") {}
            Button("Résumer", systemImage: "text.append") {}
        }
        .disabled(true)
    }
}

struct KeptEditor: View {
    @Bindable var article: Article
    @Environment(\.modelContext) private var context
    @Query(sort: \CairnCore.Tag.name) private var allTags: [CairnCore.Tag]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note").font(.headline)
            TextEditor(text: $article.note)
                .font(.body)
                .frame(minHeight: 60, maxHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel("Note personnelle")

            Text("Tags").font(.headline)
            TagFlowLayout {
                // The relationship is unordered: sort so tags keep their place between redraws.
                ForEach((article.tags ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) { tag in
                    HStack(spacing: 4) {
                        Text(tag.name)
                        Button { Library.removeTag(tag, from: article) } label: {
                            Image(systemName: "xmark").font(.caption2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Retirer le tag « \(tag.name) »")
                        .accessibilityLabel("Retirer le tag « \(tag.name) »")
                    }
                    .tagCapsule()
                }
                TextField("Ajouter un tag", text: $newTag)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 120)
                    .onSubmit { add(newTag) }
            }
            .padding(6)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            if !suggestions.isEmpty {
                HStack {
                    Text("Suggestions :").foregroundStyle(.secondary)
                    ForEach(suggestions) { tag in
                        Button(tag.name) { add(tag.name) }
                            .buttonStyle(.plain)
                            .tagCapsule()
                    }
                }
                .font(.caption)
            }
        }
    }

    private var suggestions: [CairnCore.Tag] {
        let key = Library.tagKey(newTag)
        guard !key.isEmpty else { return [] }
        let current = Set((article.tags ?? []).map(\.key))
        return Array(allTags.filter { $0.key.hasPrefix(key) && !current.contains($0.key) }.prefix(5))
    }

    private func add(_ name: String) {
        // A failed tag lookup leaves the tag unadded, which the user sees immediately.
        try? Library.addTag(named: name, to: article, context: context)
        newTag = ""
    }
}

private extension View {
    func tagCapsule() -> some View {
        padding(.horizontal, 8).padding(.vertical, 3).background(.tint.opacity(0.2), in: Capsule())
    }
}

/// Lays subviews out left to right, wrapping to a new line when the width runs out, each line centered
/// vertically. The last subview (the tag field) stretches over what its line has left.
struct TagFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let frames = frames(for: subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? frames.map(\.maxX).max() ?? 0, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(for: subviews, width: bounds.width)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(for subviews: Subviews, width: CGFloat) -> [CGRect] {
        var lines: [[CGRect]] = [[]]
        var x: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            var size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { lines.append([]); x = 0 }
            if index == subviews.count - 1 && width.isFinite { size.width = max(size.width, width - x) }
            lines[lines.count - 1].append(CGRect(origin: CGPoint(x: x, y: 0), size: size))
            x += size.width + spacing
        }
        var y: CGFloat = 0
        return lines.flatMap { line in
            let height = line.map(\.height).max() ?? 0
            defer { y += height + spacing }
            return line.map { $0.offsetBy(dx: 0, dy: y + (height - $0.height) / 2) }
        }
    }
}
