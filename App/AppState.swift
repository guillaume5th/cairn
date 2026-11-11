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
    var isAddingFeed = false
    var isImporting = false
    var isExporting = false
    var isSearchRequested = false
    var exportDocument: OPMLDocument?
    var message: String?

    var context: ModelContext { container.mainContext }

    init(container: ModelContainer) {
        self.container = container
    }

    func launch() async {
        do {
            try Library.purge(context: context)
        } catch {
            message = "La purge des anciens articles a échoué : \(error.localizedDescription)"
        }
        await refresh()
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
        await refreshIcons()
    }

    /// Looks up the icons that are due (see `Library.iconCheckInterval`). A failed lookup keeps the stored icon.
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
    static let opml = UTType(filenameExtension: "opml", conformingTo: .xml) ?? .xml
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
