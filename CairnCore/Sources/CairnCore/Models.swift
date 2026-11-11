import Foundation
import SwiftData

// CloudKit-compatible schema: every property has a default, every relationship is optional,
// and no @Attribute(.unique). Uniqueness is enforced by Library.

@Model
public final class Feed {
    public var url: String = ""
    public var title: String = ""
    public var lastError: String?
    public var addedAt: Date = Date.now
    /// Site icon (favicon), kept locally so it shows offline.
    @Attribute(.externalStorage) public var iconData: Data?
    /// Last icon lookup, successful or not.
    public var iconCheckedAt: Date?
    /// Site and icon URLs declared by the feed at its last ingestion in this session; not stored.
    @Transient public var siteURLHint: String? = nil
    @Transient public var iconURLHint: String? = nil
    @Relationship(deleteRule: .nullify, inverse: \Article.feed)
    public var articles: [Article]? = []
    public var folder: Folder?

    public init(url: String, title: String) {
        self.url = url
        self.title = title
    }

    public var unreadCount: Int {
        (articles ?? []).count { !$0.isRead }
    }
}

@Model
public final class Article {
    public var externalID: String = ""
    public var link: String = ""
    public var title: String = ""
    public var publishedAt: Date = Date.now
    public var content: String?
    public var isRead: Bool = false
    public var isKept: Bool = false
    public var keptAt: Date?
    public var note: String = ""
    /// Copy of the feed title so a kept article keeps its source after its feed is deleted.
    public var sourceTitle: String = ""
    /// Copy of the feed icon, set when the feed of a kept article is deleted.
    @Attribute(.externalStorage) public var sourceIconData: Data?
    public var feed: Feed?
    /// Set exactly when `isKept` is true (kept in place by `Library`).
    public var cairn: Cairn?
    @Relationship(deleteRule: .nullify, inverse: \Tag.articles)
    public var tags: [Tag]? = []

    public init(externalID: String, link: String, title: String, publishedAt: Date, content: String?, sourceTitle: String) {
        self.externalID = externalID
        self.link = link
        self.title = title
        self.publishedAt = publishedAt
        self.content = content
        self.sourceTitle = sourceTitle
    }
}

@Model
public final class Tag {
    public var name: String = ""
    /// Case- and diacritic-insensitive identity of the tag.
    public var key: String = ""
    public var articles: [Article]? = []

    public init(name: String) {
        self.name = name
        self.key = Library.tagKey(name)
    }
}

@Model
public final class Folder {
    public var name: String = ""
    /// Case- and diacritic-insensitive identity of the folder, like `Tag.key`.
    public var key: String = ""
    /// Deleting the folder leaves its feeds at the root.
    @Relationship(deleteRule: .nullify, inverse: \Feed.folder)
    public var feeds: [Feed]? = []

    public init(name: String) {
        self.name = name
        self.key = Library.tagKey(name)
    }

    public var unreadCount: Int {
        (feeds ?? []).reduce(0) { $0 + $1.unreadCount }
    }
}

@Model
public final class Cairn {
    public var name: String = ""
    /// Case- and diacritic-insensitive identity of the cairn, like `Tag.key`.
    public var key: String = ""
    @Relationship(deleteRule: .nullify, inverse: \Article.cairn)
    public var articles: [Article]? = []

    public init(name: String) {
        self.name = name
        self.key = Library.tagKey(name)
    }
}

public enum CairnStore {
    public static func container(inMemory: Bool = false) throws -> ModelContainer {
        try ModelContainer(
            for: Feed.self, Article.self, Tag.self, Folder.self, Cairn.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: inMemory)
        )
    }
}
