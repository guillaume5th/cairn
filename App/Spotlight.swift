import CairnCore
import CoreSpotlight
import SwiftData
import UniformTypeIdentifiers
import os

/// Kept articles in Spotlight, identified by their link (it survives a restore, unlike a SwiftData identifier).
@MainActor
enum Spotlight {
    private static var indexedFingerprint: Int?
    private static var pending: Task<Void, Never>?
    private static let log = Logger(subsystem: "dev.cairn.Cairn", category: "spotlight")

    /// Saves come in bursts: waits for them to settle, then updates.
    static func scheduleUpdate(context: ModelContext) {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { await update(context: context) }
        }
    }

    /// Replaces the whole index, only when an indexed field of a kept article changed since the last time.
    static func update(context: ModelContext) async {
        guard let kept = try? context.fetch(FetchDescriptor<Article>(predicate: #Predicate { $0.isKept })) else { return }
        let fingerprint = kept.map { [$0.link, $0.title, $0.sourceTitle, $0.note, $0.cairn?.name ?? "", tags($0).joined(separator: ",")] }
            .hashValue
        guard fingerprint != indexedFingerprint else { return }
        let items = kept.map(item)
        do {
            try await CSSearchableIndex.default().deleteAllSearchableItems()
            try await CSSearchableIndex.default().indexSearchableItems(items)
            indexedFingerprint = fingerprint
            log.info("Indexed \(items.count) kept articles")
        } catch {
            // Tried again at the next save.
            log.error("Indexing failed: \(error)")
        }
    }

    private static func item(for article: Article) -> CSSearchableItem {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = article.title
        attributes.contentDescription = [article.sourceTitle, article.note].filter { !$0.isEmpty }.joined(separator: " — ")
        attributes.keywords = tags(article) + [article.cairn?.name].compactMap { $0 }
        attributes.url = URL(string: article.link)
        attributes.thumbnailData = article.sourceIconData ?? article.feed?.iconData
        return CSSearchableItem(uniqueIdentifier: article.link, domainIdentifier: "kept", attributeSet: attributes)
    }

    private static func tags(_ article: Article) -> [String] { (article.tags ?? []).map(\.name).sorted() }
}
