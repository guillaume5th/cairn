import CairnCore
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// App-wide state shared by the window and the menu commands.
@MainActor @Observable
final class AppState {
    /// Held here for the app's lifetime: a ModelContext does not retain its container.
    let container: ModelContainer
    let fetcher = FeedFetcher()
    var isRefreshing = false
    var isDigesting = false
    var isAddingFeed = false
    /// Feeds offered when the address given declares several; empty otherwise.
    var feedChoices: [DiscoveredFeed] = []
    var isImporting = false
    var isExporting = false
    var isSearchRequested = false
    /// iOS only: the Settings sheet (the Mac has a Settings window).
    var isShowingSettings = false
    var exportDocument: OPMLDocument?
    var message: String?
    /// Articles being summarized, and the last failure per article; neither is stored.
    var summarizing: Set<PersistentIdentifier> = []
    var summaryErrors: [PersistentIdentifier: String] = [:]
    /// Articles whose full text is loading, and the last failure per article; neither is stored.
    var loadingFullContent: Set<PersistentIdentifier> = []
    var fullContentErrors: [PersistentIdentifier: String] = [:]
    @ObservationIgnored private var isLoadingNewFullContent = false
    @ObservationIgnored private var fullContentQueue: [PersistentIdentifier] = []
    /// The window's `.task` runs again each time the window is reopened; the launch work must happen once.
    @ObservationIgnored private var launched = false

    var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    func launch() async {
        guard !launched else { return }
        launched = true
        do {
            // Before anything reads the cairns: files articles kept before cairns existed.
            try Library.ensureCairn(context: context)
            try context.save()
        } catch {
            message = "La préparation du cairn a échoué : \(error.localizedDescription)"
        }
        do {
            try Library.purge(context: context)
            try Library.purgeDigests(context: context, olderThan: DigestSettings.retention)
        } catch {
            message = "La purge des anciens articles a échoué : \(error.localizedDescription)"
        }
        await refresh()
        // Catch-up at launch, then a check every minute while the app is open (survives sleep and setting changes).
        Task {
            while !Task.isCancelled {
                if DigestSettings.isDue { await makeDigest() }
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    /// Refreshes, then has the chosen engine summarize the articles of the last 24 hours. Counts as the day's attempt
    /// whatever the outcome. No digest (and no engine call) when there is no article.
    func makeDigest(manual: Bool = false) async {
        guard !isDigesting else { return }
        isDigesting = true
        defer { isDigesting = false }
        UserDefaults.standard.set(Date.now, forKey: DigestSettings.lastAttemptKey)
        await refresh()
        do {
            let now = Date.now
            let articles = try Library.digestArticles(context: context, now: now)
            guard !articles.isEmpty else {
                if manual { message = "Aucun article publié ces dernières 24 heures : pas de résumé." }
                return
            }
            let items = Library.digestItems(for: articles)
            let prompt = Library.digestPrompt(for: articles)
            let (summarizer, engine) = try DigestSettings.summarizer()
            let text = try await summarizer.summarize(prompt)
            context.insert(Digest(createdAt: now, text: text, items: items, engine: engine))
            try Library.purgeDigests(context: context, olderThan: DigestSettings.retention)
            try context.save()
        } catch {
            message = "Le résumé n'a pas pu être produit : \(error.localizedDescription)"
        }
    }

    /// Has the chosen engine summarize the article. A failure keeps the previous summary and is kept per article.
    func summarize(_ article: Article) async {
        let id = article.persistentModelID
        guard summarizing.insert(id).inserted else { return }
        defer { summarizing.remove(id) }
        summaryErrors[id] = nil
        do {
            let (summarizer, engine) = try DigestSettings.summarizer()
            let text = try await summarizer.summarize(Library.articleSummaryPrompt(for: article))
            article.summary = text
            article.summaryDate = .now
            article.summaryEngine = engine
            save()
        } catch {
            summaryErrors[id] = "Le résumé n'a pas pu être produit : \(error.localizedDescription)"
        }
    }

    /// Downloads the article's page and keeps its main content. The result goes to this article even when the user
    /// has moved on; a failure keeps the feed's content and is kept per article.
    func loadFullContent(_ article: Article) async {
        let id = article.persistentModelID
        guard let url = URL(string: article.link), loadingFullContent.insert(id).inserted else { return }
        defer { loadingFullContent.remove(id) }
        fullContentErrors[id] = nil
        let result = await Result { try await ArticleExtractor.extract(from: url) }
        Library.recordFullContent(result, for: article)
        if case let .failure(error) = result {
            fullContentErrors[id] = "L'article complet n'a pas pu être chargé : \(error.localizedDescription)"
        }
        save()
    }

    /// Full text of the new articles of feeds set to load it, 3 at a time. Failures are silent: the feed's content stays.
    func loadNewFullContent() async {
        guard !isLoadingNewFullContent, let pending = try? Library.articlesAwaitingFullContent(context: context),
              !pending.isEmpty else { return }
        isLoadingNewFullContent = true
        defer { isLoadingNewFullContent = false }
        // Three loaders take turns on the main actor, each waiting on its download.
        fullContentQueue = pending.map(\.persistentModelID)
        async let first: Void = drainFullContentQueue()
        async let second: Void = drainFullContentQueue()
        async let third: Void = drainFullContentQueue()
        _ = await (first, second, third)
        save()
    }

    private func drainFullContentQueue() async {
        while !fullContentQueue.isEmpty {
            guard let article = context.model(for: fullContentQueue.removeFirst()) as? Article else { continue }
            guard let url = URL(string: article.link) else {
                Library.recordFullContent(.failure(CairnError.invalidURL), for: article)
                continue
            }
            let result = await Result { try await ArticleExtractor.extract(from: url) }
            Library.recordFullContent(result, for: article)
        }
    }

    /// Ignored while a refresh is already running.
    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            try await Library.refreshAll(context: context, fetcher: fetcher)
            try context.save()
        } catch {
            message = error.localizedDescription
        }
        // Not awaited: the refresh ends without waiting for the pages.
        Task { await loadNewFullContent() }
        await refreshIcons()
    }

    /// Looks up the icons that are due (see `Library.iconCheckInterval`). A failed lookup keeps the stored icon.
    /// Finds the feed at the address (a feed, or a site declaring one): subscribes to a single one, offers a choice
    /// (`feedChoices`) when there are several.
    func addFeed(_ address: String) async throws {
        let feeds = try await Library.discoverFeeds(urlString: address, fetcher: fetcher)
        if feeds.count == 1 {
            try await subscribe(to: feeds[0].url)
        } else {
            feedChoices = feeds
        }
    }

    /// Checks the URL is a readable feed, then subscribes; the icon follows without being waited for.
    func subscribe(to url: String) async throws {
        _ = try await Library.addFeed(urlString: url, context: context, fetcher: fetcher)
        save()
        Task { await refreshIcons() }
    }

    func isSubscribed(_ url: String) -> Bool { (try? Library.isSubscribed(url, context: context)) ?? false }

        func refreshIcons() async {
        do {
            try await Library.refreshIcons(context: context, fetcher: fetcher)
            try context.save()
        } catch {
            message = "La récupération des icônes a échoué : \(error.localizedDescription)"
        }
    }

    /// Inserted models only get their permanent persistentModelID on save. Saving right after inserts
    /// keeps List selections (keyed by that ID) valid.
    func save() {
        do {
            try context.save()
        } catch {
            message = "L'enregistrement a échoué : \(error.localizedDescription)"
        }
    }

    func importOPML(_ result: Result<URL, any Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let (added, skipped) = try Library.importOPML(try Data(contentsOf: url), context: context)
            try context.save()
            message = "\(added) abonnement(s) ajouté(s), \(skipped) déjà suivi(s)."
            if added > 0 { Task { await refresh() } }
        } catch {
            message = error.localizedDescription
        }
    }

    func prepareExport() {
        do {
            exportDocument = OPMLDocument(data: try Library.exportOPML(context: context))
            isExporting = true
        } catch {
            message = error.localizedDescription
        }
    }
}

extension UTType {
    /// Declared in both apps' Info.plist (UTImportedTypeDeclarations).
    static let opml = UTType(importedAs: "org.opml.opml", conformingTo: .xml)
}

struct OPMLDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.opml]
    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
