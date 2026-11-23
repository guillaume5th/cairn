import CairnCore
import SwiftData
import SwiftUI
import WebKit

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
    @AppStorage(KeptEditor.shownKey) private var inspectorShown = true
    @State private var page: WebPage?
    @State private var progress: Double?

    private var quoteAction: QuoteAction? {
        // The page outlives an article without content, whose reader shows no page to select in.
        Library.displayedContent(article) == nil ? nil : page.map { QuoteAction(article: article, page: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(AttributedString(article.title.isEmpty ? String(localized: "Untitled") : article.title, highlighting: query))
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
            if let audio = article.audioURL.flatMap(URL.init(string:)) {
                EpisodePlayer(url: audio)
                    .frame(height: 40)
                    .padding(.horizontal)
                    .padding(.bottom, 12)
            }
            if let video = Library.youtubeVideoID(in: article.link) {
                // With no content to read, the video is the content: it fills the pane.
                VideoPlayer(id: video, fillsPane: Library.displayedContent(article) == nil)
                    .id(video)
            }
            Divider()
                // Room for the whole line: below the 1 pt divider, the article's web view would hide half of it.
                .frame(height: 2, alignment: .top)
                .overlay(alignment: .top) {
                    // A bare accent line on the header's divider, which reads as the divider filling up; no track.
                    if Library.displayedContent(article) != nil, let progress {
                        Rectangle()
                            .fill(.tint)
                            .frame(height: 2)
                            .scaleEffect(x: progress, anchor: .leading)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true) // the scroll bar already tells VoiceOver where the reading is
                    }
                }
            fullContentStatus
            summaryBox

            if let html = Library.displayedContent(article) {
                HTMLView(html: html, baseURL: url, query: query, quotes: Library.quotes(in: article.note), page: $page,
                         progress: $progress)
            } else if Library.youtubeVideoID(in: article.link) != nil {
                Spacer(minLength: 0)
            } else {
                ContentUnavailableView {
                    Label("No content", systemImage: "doc")
                } description: {
                    Text("The feed provides no content for this article.")
                } actions: {
                    if let url { Button("Open in browser") { openURL(url) } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .focusedSceneValue(\.quoteAction, quoteAction)
        .inspector(isPresented: $inspectorShown) {
            KeptEditor(article: article, articlesToUnkeep: $articlesToUnkeep)
                .inspectorColumnWidth(min: 220, ideal: 260, max: 360)
        }
        .toolbar {
            ReaderToolbar(articles: [article], articlesToUnkeep: $articlesToUnkeep, articlesToOpen: $articlesToOpen) {
                // A toggle, like the list's filter: on while the full text is shown; turning it on loads it if needed.
                Toggle(isOn: Binding { article.fullContent != nil && !article.showsFeedContent } set: { showFullContent($0) }) {
                    Label("Full article", systemImage: "doc.text.magnifyingglass")
                }
                .disabled(url == nil || isLoadingFullContent)
                .help(url == nil ? "This article has no web link"
                      : article.fullContent == nil ? "Load the full article from its site"
                      : article.showsFeedContent ? "Show the full article" : "Show the feed content")
                Button(article.summary == nil ? "Summarize" : "Regenerate summary", systemImage: "text.append") { summarize() }
                    .disabled((Library.readableContent(article) ?? "").isEmpty || isSummarizing)
                    .help((Library.readableContent(article) ?? "").isEmpty ? "The feed provides no content to summarize"
                          : article.summary == nil ? "Summarize this article with AI" : "Redo this article's summary")
                QuoteButtons(action: quoteAction, hasShortcut: false)
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
                Text("Loading the full article…").foregroundStyle(.secondary)
            }
            .font(.callout)
            .padding([.horizontal, .top])
        } else if let error = state.fullContentErrors[article.persistentModelID] {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.secondary)
                Spacer()
                Button("Try again") { showFullContent(true) }
                if let url { Button("Open in browser") { openURL(url) } }
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
                DisclosureGroup(isExpanded: Binding { !summaryHidden } set: { summaryHidden = !$0 }) {
                    VStack(alignment: .leading, spacing: 6) {
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
                                        Button("Read more of the summary", systemImage: "chevron.down") {
                                            withAnimation { summaryScroll.scrollTo(edge: .bottom) }
                                        }
                                        .labelStyle(.iconOnly)
                                        .buttonStyle(.borderless)
                                        .help("Read more of the summary")
                                    }
                                }
                                .animation(.default, value: summaryHasMore)
                        }
                        if let error {
                            Text(error).font(.callout).foregroundStyle(.red).textSelection(.enabled)
                        }
                        if Library.isExcerpt(article) {
                            Text("Summary of the excerpt provided by the feed").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 6)
                } label: {
                    HStack {
                        Text(summaryHeader).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        if isSummarizing {
                            ProgressView().controlSize(.small)
                        } else {
                            Button(article.summary == nil ? "Try again" : "Regenerate", systemImage: "arrow.clockwise") { summarize() }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .help(article.summary == nil ? "Retry the summary" : "Regenerate summary")
                                .accessibilityLabel(article.summary == nil ? "Try again" : "Regenerate")
                            if article.summary != nil {
                                Button("Delete summary", systemImage: "trash") { deleteSummary() }
                                    .labelStyle(.iconOnly)
                                    .buttonStyle(.borderless)
                                    .help("Delete this article's summary")
                                    .accessibilityLabel("Delete summary")
                            }
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
        guard let date = article.summaryDate, article.summary != nil else { return isSummarizing ? String(localized: "Summarizing…") : String(localized: "Summary") }
        return [String(localized: "Summary"), date.formatted(date: .abbreviated, time: .shortened), article.summaryEngine].compactMap(\.self).joined(separator: " · ")
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
                    Button("Remove from cairn", role: .destructive, action: unkeep)
                }
            } label: {
                Label("Keep", image: icon)
            }
            // Without the arrow, the menu looks and sits like the other reader buttons.
            .menuIndicator(.hidden)
            .help(articles.count == 1 ? "Choose this article's cairn" : "Choose these articles' cairn")
        } else {
            Button(allKept ? "Remove from cairn" : "Keep in cairn", image: icon) {
                if allKept {
                    unkeep()
                } else if let cairn = cairns.first {
                    for article in articles where !article.isKept { Library.keep(article, in: cairn) }
                }
            }
            .help(allKept ? "Remove from cairn" : "Keep in cairn")
        }
    }

    private func unkeep() { Self.unkeep(articles, confirming: $articlesToUnkeep) }

    /// Unkeeps the articles at once, or through `unkeepConfirmation` when one has a note or tags.
    static func unkeep(_ articles: [Article], confirming articlesToUnkeep: Binding<[Article]>) {
        if articles.allSatisfy({ $0.note.isEmpty && ($0.tags ?? []).isEmpty }) {
            for article in articles { Library.unkeep(article) }
        } else {
            articlesToUnkeep.wrappedValue = articles
        }
    }
}

/// Adds to or removes from the read-later queue: removes when every article is queued, else queues the others.
struct ReadLaterButton: View {
    let articles: [Article]

    var body: some View {
        let allQueued = !articles.isEmpty && articles.allSatisfy(\.isQueued)
        Button(allQueued ? "Remove from Read later" : "Read later",
               systemImage: "clock") {
            for article in articles {
                if allQueued { Library.removeFromReadLater(article) } else { Library.readLater(article) }
            }
        }
        .help(allQueued ? "Remove from Read later" : "Read later")
    }
}

extension View {
    /// Confirms unkeeping articles of which at least one has a note or tags, which are lost.
    func unkeepConfirmation(_ articles: Binding<[Article]>) -> some View {
        let lot = articles.wrappedValue
        let losing = lot.count { !$0.note.isEmpty || !($0.tags ?? []).isEmpty }
        return confirmationDialog("Remove these \(lot.count) articles from the cairn?",
                                  isPresented: Binding(get: { !lot.isEmpty }, set: { if !$0 { articles.wrappedValue = [] } }),
                                  presenting: lot) { lot in
            Button("Remove", role: .destructive) { for article in lot { Library.unkeep(article) } }
        } message: { lot in
            Text(lot.count == 1 ? "Its notes and tags will be lost."
                 : "\(losing) articles will lose their notes or tags.")
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
        content.confirmationDialog("Open \(articles.count) articles in the browser?",
                                   isPresented: Binding(get: { !articles.isEmpty }, set: { if !$0 { articles = [] } }),
                                   presenting: articles) { lot in
            Button("Open") { for article in lot { if let url = OpenInBrowser.url(of: article) { openURL(url) } } }
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
            // ⇧⌘D as Safari's Add to Reading List.
            ReadLaterButton(articles: articles)
                .keyboardShortcut("d", modifiers: [.command, .shift])
            // Same symbols as the reader toolbar.
            Button(anyUnread ? "Mark as read" : "Mark as unread",
                   systemImage: anyUnread ? "checkmark.circle" : "circle.inset.filled") { for article in articles { article.isRead = anyUnread } }
                .keyboardShortcut("u", modifiers: [.command, .shift])
            Divider() // filing above, sending the article out of the app below
            if articles.count == 1 {
                ShareButton(article: articles[0])
            }
            Button("Open in browser", systemImage: "safari") { OpenInBrowser.open(articles, with: openURL, toConfirm: $articlesToOpen) }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(links.isEmpty)
            Button(links.count > 1 ? "Copy links" : "Copy link", systemImage: "link") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(links.map(\.absoluteString).joined(separator: "\n"), forType: .string)
            }
            .disabled(links.isEmpty)
            // Only articles whose feed is gone can be deleted: a followed feed would bring them back.
            if !articles.isEmpty, articles.allSatisfy({ $0.feed == nil }) {
                Divider()
                Button("Delete \(articles.count) articles…", systemImage: "trash", role: .destructive) {
                    articlesToDelete = articles
                }
            }
        }
        // Menus show only titles by default on macOS; icons as in Apple's apps since macOS 26.
        .labelStyle(.titleAndIcon)
        .disabled(articles.isEmpty)
    }
}

/// Appends the text selected in the reader to the article's note, keeping the article in `cairn` first if needed.
@MainActor struct QuoteAction {
    let article: Article
    let page: WebPage

    func callAsFunction(keepingIn cairn: Cairn?) async {
        let passage = await HTMLView.selection(in: page)
        guard !passage.allSatisfy(\.isWhitespace), article.isKept || cairn != nil else { return NSSound.beep() }
        if let cairn, !article.isKept { Library.keep(article, in: cairn) }
        article.note = Library.appendQuote(passage, to: article.note)
    }
}

/// « Surligner », as a menu of the cairns for an article not yet kept when there are several cairns:
/// then ⇧⌘H does nothing rather than pick a cairn. Greyed out without an article in the reader. In the Edit menu
/// and the reader's toolbar; only the menu declares ⇧⌘H.
struct QuoteButtons: View {
    let action: QuoteAction?
    var hasShortcut = true
    @Query(sort: \Cairn.name) private var cairns: [Cairn]

    var body: some View {
        if let action, !action.article.isKept, cairns.count > 1 {
            Menu("Highlight", systemImage: "highlighter") {
                ForEach(cairns) { cairn in
                    Button(cairn.name) { Task { await action(keepingIn: cairn) } }
                }
            }
            .menuIndicator(.hidden) // like KeepButton: the toolbar keeps its layout whether the article is kept or not
            .help("Quote the selected passage in the note, keeping the article")
        } else {
            Button("Highlight", systemImage: "highlighter") { Task { await action?(keepingIn: cairns.first) } }
                .keyboardShortcut(hasShortcut ? KeyboardShortcut("h", modifiers: [.command, .shift]) : nil)
                .disabled(action == nil)
                .help("Quote the selected passage in the note (⇧⌘H)")
        }
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
    @Entry var quoteAction: QuoteAction?
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
            Button("Share", systemImage: "square.and.arrow.up") {}
                .disabled(true)
                .help("This article has no web link")
        }
    }

    private func link(_ url: URL) -> some View {
        ShareLink(item: url, subject: Text(article.title), message: Text(article.title)) {
            Label("Share", systemImage: "square.and.arrow.up")
        }
        .help("Share this article")
    }
}

/// Reading pane for several selected articles: their count, and the reader's toolbar acting on them.
struct ArticleSelectionView: View {
    let articles: [Article]
    @State private var articlesToUnkeep: [Article] = []
    @State private var articlesToOpen: [Article] = []

    var body: some View {
        ContentUnavailableView(articles.isEmpty ? "No article selected"
                                   : "\(articles.count) articles selected",
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
    /// False for a selection or an empty pane: there is no inspector then.
    var isInspectable = true
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
                ReadLaterButton(articles: articles)
                // The filled dot the list shows on unread rows.
                Button(anyUnread ? "Mark as read" : "Mark as unread",
                       systemImage: anyUnread ? "checkmark.circle" : "circle.inset.filled") {
                    for article in articles { article.isRead = anyUnread }
                }
                .help(anyUnread ? "Mark as read" : "Mark as unread")
            }
            .disabled(articles.isEmpty)
            if articles.count == 1 {
                ShareButton(article: articles[0])
            } else {
                Button("Share", systemImage: "square.and.arrow.up") {}.disabled(true)
            }
            Button("Open in browser", systemImage: "safari") {
                OpenInBrowser.open(articles, with: openURL, toConfirm: $articlesToOpen)
            }
            .disabled(!articles.contains { OpenInBrowser.url(of: $0) != nil })
            .help("Open in browser")
        }
        ToolbarSpacer(.fixed)
        ToolbarItem {
            InspectorButton().disabled(!isInspectable)
        }
    }
}

/// Shows or hides the inspector of the article being read.
struct InspectorButton: View {
    @AppStorage(KeptEditor.shownKey) private var isShown = true

    var body: some View {
        Toggle("Inspector", systemImage: "sidebar.trailing", isOn: $isShown)
            .help(isShown ? "Hide inspector" : "Show inspector")
    }
}

extension ReaderToolbar where Reading == DisabledReadingButtons {
    /// For several articles or none: the reading buttons greyed out.
    init(articles: [Article], articlesToUnkeep: Binding<[Article]>, articlesToOpen: Binding<[Article]>) {
        self.init(articles: articles, articlesToUnkeep: articlesToUnkeep, articlesToOpen: articlesToOpen, isInspectable: false) {
            DisabledReadingButtons()
        }
    }

    /// For a pane without an article.
    static var empty: Self { Self(articles: [], articlesToUnkeep: .constant([]), articlesToOpen: .constant([])) }
}

struct DisabledReadingButtons: View {
    var body: some View {
        Group {
            Button("Full article", systemImage: "doc.text.magnifyingglass") {}
            Button("Summarize", systemImage: "text.append") {}
            Button("Highlight", systemImage: "highlighter") {}
        }
        .disabled(true)
    }
}

/// The inspector of the article being read: its cairn, notes and tags once kept, an invitation to keep it otherwise.
struct KeptEditor: View {
    static let shownKey = "inspectorShown"
    @Bindable var article: Article
    @Binding var articlesToUnkeep: [Article]
    @Environment(\.modelContext) private var context
    @Query(sort: \CairnCore.Tag.name) private var allTags: [CairnCore.Tag]
    @Query(sort: \Cairn.name) private var cairns: [Cairn]
    @State private var newTag = ""

    var body: some View {
        if article.isKept {
            Form {
                Section("Information") {
                    if cairns.count > 1 {
                        // Moving keeps the notes and tags (Library.keep).
                        Picker("Cairn", selection: Binding { article.cairn?.persistentModelID } set: { id in
                            if let cairn = cairns.first(where: { $0.persistentModelID == id }) { Library.keep(article, in: cairn) }
                        }) {
                            ForEach(cairns) { Text($0.name).tag(Optional($0.persistentModelID)) }
                        }
                    } else {
                        LabeledContent("Cairn", value: article.cairn?.name ?? "")
                    }
                    if let keptAt = article.keptAt {
                        LabeledContent("Kept on", value: keptAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }
                Section("Notes") {
                    TextEditor(text: $article.note)
                        .font(.body)
                        .frame(minHeight: 80)
                        .scrollContentBackground(.hidden)
                        .accessibilityLabel("Personal notes")
                        .overlay(alignment: .topLeading) {
                            // TextEditor has no prompt; this one shows the quote gesture where its result lands.
                            if article.note.isEmpty {
                                Text("Select a passage then ⇧⌘H to quote it here")
                                    .foregroundStyle(.tertiary)
                                    .padding(.leading, 5)
                                    .allowsHitTesting(false)
                                    .accessibilityHidden(true)
                            }
                        }
                }
                Section("Tags") {
                    TagFlowLayout {
                        // The relationship is unordered: sort so tags keep their place between redraws.
                        ForEach((article.tags ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) { tag in
                            HStack(spacing: 4) {
                                Text(tag.name)
                                Button { Library.removeTag(tag, from: article) } label: {
                                    Image(systemName: "xmark.circle.fill")
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("Remove tag “\(tag.name)”")
                                .accessibilityLabel("Remove tag “\(tag.name)”")
                            }
                            .tagCapsule()
                        }
                        TextField("Add a tag", text: $newTag, prompt: Text("Add a tag"))
                            .labelsHidden() // a Form would put the title beside a narrow field
                            .textFieldStyle(.roundedBorder)
                            .frame(minWidth: 100)
                            .onSubmit { add(newTag) }
                    }
                    if !suggestions.isEmpty {
                        TagFlowLayout {
                            ForEach(suggestions) { tag in
                                Button(tag.name) { add(tag.name) }
                                    .buttonStyle(.plain)
                                    .tagCapsule()
                            }
                            Color.clear.frame(width: 0, height: 0) // the layout stretches its last subview
                        }
                        .font(.caption)
                    }
                }
            }
            .formStyle(.grouped)
        } else {
            ContentUnavailableView {
                Label("Article not kept", image: "cairn")
            } description: {
                Text("Keep it to add notes and tags to it.")
            } actions: {
                KeepButton(articles: [article], articlesToUnkeep: $articlesToUnkeep)
                    .labelStyle(.titleOnly)
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
        padding(.horizontal, 8).padding(.vertical, 3).background(.fill.tertiary, in: Capsule())
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
