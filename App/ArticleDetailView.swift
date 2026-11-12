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
            summaryBox

            if let html = article.content {
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
            ToolbarItemGroup {
                // Reading first, then filing, then leaving the app last.
                Button(article.summary == nil ? "Résumer" : "Régénérer le résumé", systemImage: "text.append") { summarize() }
                    .disabled((article.content ?? "").isEmpty || isSummarizing)
                    .help((article.content ?? "").isEmpty ? "Le flux ne fournit pas de contenu à résumer"
                          : article.summary == nil ? "Résumer cet article avec l'IA" : "Refaire le résumé de cet article")
                KeepButton(articles: [article], articlesToUnkeep: $articlesToUnkeep)
                // The filled dot the list shows on unread rows.
                Button("Marquer comme non lu", systemImage: "circle.inset.filled") { article.isRead = false }
                    .help("Marquer comme non lu")
                Button("Ouvrir dans le navigateur", systemImage: "safari") { if let url { openURL(url) } }
                    .disabled(url == nil)
                    .help("Ouvrir dans le navigateur")
            }
        }
        .unkeepConfirmation($articlesToUnkeep)
        .task(id: article.persistentModelID) {
            if marksRead { article.isRead = true }
            // The view is reused across articles: start each summary at its top.
            summaryScroll.scrollTo(edge: .top)
        }
    }

    private var isSummarizing: Bool { state.summarizing.contains(article.persistentModelID) }

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

/// Context-menu items for one or more articles (the clicked one, or the selection holding it).
struct ArticleMenuItems: View {
    let articles: [Article]
    @Binding var articlesToUnkeep: [Article]
    @Binding var articlesToOpen: [Article]
    @Binding var articlesToDelete: [Article]
    @Environment(\.openURL) private var openURL

    var body: some View {
        let anyUnread = articles.contains { !$0.isRead }
        KeepButton(articles: articles, articlesToUnkeep: $articlesToUnkeep)
        Button(anyUnread ? "Marquer comme lu" : "Marquer comme non lu") { for article in articles { article.isRead = anyUnread } }
        Button("Ouvrir dans le navigateur") { OpenInBrowser.open(articles, with: openURL, toConfirm: $articlesToOpen) }
        // Only articles whose feed is gone can be deleted: a followed feed would bring them back.
        if articles.allSatisfy({ $0.feed == nil }) {
            Divider()
            Button(articles.count == 1 ? "Supprimer l'article…" : "Supprimer \(articles.count) articles…", role: .destructive) {
                articlesToDelete = articles
            }
        }
    }
}

/// Reading pane for several selected articles: their count, and the reader actions applied to all of them.
struct ArticleSelectionView: View {
    let articles: [Article]
    @Environment(\.openURL) private var openURL
    @State private var articlesToUnkeep: [Article] = []
    @State private var articlesToOpen: [Article] = []

    var body: some View {
        let anyUnread = articles.contains { !$0.isRead }
        ContentUnavailableView(articles.isEmpty ? "Aucun article sélectionné"
                                   : articles.count == 1 ? "1 article sélectionné" : "\(articles.count) articles sélectionnés",
                               systemImage: "doc.on.doc")
            #if os(macOS)
            // The actions are under the list; without an item of its own here, the list's buttons slide right.
            .toolbar { ToolbarSpacer(.flexible) }
            #else
            .toolbar {
                ToolbarItemGroup {
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
                }
            }
            #endif
            .unkeepConfirmation($articlesToUnkeep)
            .openConfirmation($articlesToOpen)
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
