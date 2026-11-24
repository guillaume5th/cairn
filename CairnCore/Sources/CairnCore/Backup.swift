import Foundation
import SwiftData

/// The library as it was: subscriptions with their icons, folders, cairns, every article with its read state, and
/// settings. Daily digests are left out. Saved as JSON (icons as base64).
public struct Backup: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version = Backup.currentVersion
    public var createdAt: Date
    public var feeds: [FeedEntry]
    public var folders: [String]
    public var cairns: [String]
    /// Color of each colored cairn, by name. Absent from backups made before cairns had colors.
    public var cairnColors: [String: String]?
    public var articles: [ArticleEntry]
    /// App settings by UserDefaults key; the app chooses which keys.
    public var settings: [String: SettingValue]

    public struct FeedEntry: Codable, Equatable, Sendable {
        public var url: String
        public var title: String
        public var folder: String?
        public var addedAt: Date
        public var loadsFullContentSince: Date?
        public var iconData: Data?
        public var iconCheckedAt: Date?
        /// Absent from backups made before the option existed.
        public var notifiesNewArticles: Bool?
    }

    /// An article, linked to its feed by URL (nil when the feed was deleted) and, when kept, to its cairn by name.
    public struct ArticleEntry: Codable, Equatable, Sendable {
        public var externalID: String
        public var link: String
        public var title: String
        public var publishedAt: Date
        public var content: String?
        public var isRead: Bool
        public var isKept: Bool
        public var keptAt: Date?
        public var note: String
        public var sourceTitle: String
        public var sourceIconData: Data?
        public var feedURL: String?
        public var cairn: String?
        public var tags: [String]
        public var summary: String?
        public var summaryDate: Date?
        public var summaryEngine: String?
        public var fullContent: String?
        public var fullContentFetchedAt: Date?
        public var showsFeedContent: Bool
        public var audioURL: String?
        /// Absent from backups made before the read-later queue.
        public var readLaterAt: Date?
    }

    public enum SettingValue: Codable, Equatable, Sendable {
        case bool(Bool), int(Int), double(Double), string(String)

        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let value = try? container.decode(Bool.self) { self = .bool(value) }
            else if let value = try? container.decode(Int.self) { self = .int(value) }
            else if let value = try? container.decode(Double.self) { self = .double(value) }
            else { self = .string(try container.decode(String.self)) }
        }

        public func encode(to encoder: any Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case let .bool(value): try container.encode(value)
            case let .int(value): try container.encode(value)
            case let .double(value): try container.encode(value)
            case let .string(value): try container.encode(value)
            }
        }
    }

    public func encoded() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(self)
    }

    /// Refuses anything that is not a backup of a known version.
    public static func decode(_ data: Data) throws -> Backup {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let backup = try? decoder.decode(Backup.self, from: data) else { throw CairnError.invalidBackup }
        guard backup.version <= currentVersion else { throw CairnError.unsupportedBackup }
        return backup
    }
}

extension Library {
    public static func makeBackup(context: ModelContext, settings: [String: Backup.SettingValue], now: Date = .now) throws -> Backup {
        let feeds = try context.fetch(FetchDescriptor<Feed>(sortBy: [SortDescriptor(\.title)]))
        let articles = try context.fetch(FetchDescriptor<Article>(sortBy: [SortDescriptor(\.publishedAt)]))
        let cairns = try context.fetch(FetchDescriptor<Cairn>(sortBy: [SortDescriptor(\.name)]))
        return Backup(
            createdAt: now,
            feeds: feeds.map { .init(url: $0.url, title: $0.title, folder: $0.folder?.name, addedAt: $0.addedAt,
                                     loadsFullContentSince: $0.loadsFullContentSince, iconData: $0.iconData,
                                     iconCheckedAt: $0.iconCheckedAt, notifiesNewArticles: $0.notifiesNewArticles) },
            folders: try context.fetch(FetchDescriptor<Folder>(sortBy: [SortDescriptor(\.name)])).map(\.name),
            cairns: cairns.map(\.name),
            cairnColors: Dictionary(cairns.compactMap { cairn in cairn.color.map { (cairn.name, $0) } },
                                    uniquingKeysWith: { first, _ in first }),
            articles: articles.map { article in
                .init(externalID: article.externalID, link: article.link, title: article.title,
                      publishedAt: article.publishedAt, content: article.content, isRead: article.isRead,
                      isKept: article.isKept, keptAt: article.keptAt, note: article.note,
                      sourceTitle: article.sourceTitle, sourceIconData: article.sourceIconData,
                      feedURL: article.feed?.url, cairn: article.isKept ? article.cairn?.name ?? "" : nil,
                      tags: (article.tags ?? []).map(\.name).sorted(), summary: article.summary,
                      summaryDate: article.summaryDate, summaryEngine: article.summaryEngine,
                      fullContent: article.fullContent, fullContentFetchedAt: article.fullContentFetchedAt,
                      showsFeedContent: article.showsFeedContent, audioURL: article.audioURL,
                      readLaterAt: article.readLaterAt)
            },
            settings: settings)
    }

    /// Replaces articles, feeds, folders, tags and cairns with those of the backup; daily digests stay.
    public static func restore(_ backup: Backup, context: ModelContext) throws {
        for article in try context.fetch(FetchDescriptor<Article>()) { context.delete(article) }
        for tag in try context.fetch(FetchDescriptor<Tag>()) { context.delete(tag) }
        for feed in try context.fetch(FetchDescriptor<Feed>()) { context.delete(feed) }
        for folder in try context.fetch(FetchDescriptor<Folder>()) { context.delete(folder) }
        for cairn in try context.fetch(FetchDescriptor<Cairn>()) { context.delete(cairn) }

        var folders: [String: Folder] = [:]
        func folder(named name: String) -> Folder {
            if let folder = folders[tagKey(name)] { return folder }
            let folder = Folder(name: name)
            context.insert(folder)
            folders[folder.key] = folder
            return folder
        }
        var cairns: [String: Cairn] = [:]
        func cairn(named name: String) -> Cairn {
            let name = name.isEmpty ? "Cairn" : name
            if let cairn = cairns[tagKey(name)] { return cairn }
            let cairn = Cairn(name: name)
            context.insert(cairn)
            cairns[cairn.key] = cairn
            return cairn
        }
        var tags: [String: Tag] = [:]

        for name in backup.folders { _ = folder(named: name) }
        for name in backup.cairns { cairn(named: name).color = backup.cairnColors?[name] }
        var feeds: [String: Feed] = [:]
        for entry in backup.feeds where feeds[entry.url] == nil {
            let feed = Feed(url: entry.url, title: entry.title)
            context.insert(feed)
            feed.addedAt = entry.addedAt
            feed.loadsFullContentSince = entry.loadsFullContentSince
            feed.iconData = entry.iconData
            feed.iconCheckedAt = entry.iconCheckedAt
            feed.notifiesNewArticles = entry.notifiesNewArticles ?? false
            feed.folder = entry.folder.map(folder(named:))
            feeds[entry.url] = feed
        }
        for entry in backup.articles {
            let article = Article(externalID: entry.externalID, link: entry.link, title: entry.title,
                                  publishedAt: entry.publishedAt, content: entry.content, sourceTitle: entry.sourceTitle)
            context.insert(article)
            article.feed = entry.feedURL.flatMap { feeds[$0] }
            article.isRead = entry.isRead
            article.sourceIconData = entry.sourceIconData
            if entry.isKept {
                article.isKept = true
                article.keptAt = entry.keptAt
                article.cairn = cairn(named: entry.cairn ?? "")
            }
            article.note = entry.note
            article.tags = entry.tags.map { name in
                if let tag = tags[tagKey(name)] { return tag }
                let tag = Tag(name: name)
                context.insert(tag)
                tags[tag.key] = tag
                return tag
            }
            article.summary = entry.summary
            article.summaryDate = entry.summaryDate
            article.summaryEngine = entry.summaryEngine
            article.fullContent = entry.fullContent
            article.fullContentFetchedAt = entry.fullContentFetchedAt
            article.showsFeedContent = entry.showsFeedContent
            article.audioURL = entry.audioURL
            article.readLaterAt = entry.readLaterAt
        }
        try ensureCairn(context: context)
    }
}
