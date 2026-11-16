@testable import CairnCore
import Foundation
import SwiftData
import Testing

@MainActor
struct LegacyImportTests {
    /// A fresh folder for one test.
    private func folder() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appending(path: "cairn import \(UUID().uuidString)") // a space, like "Application Support"
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// A real store with one feed, as the sandboxed app would have left it, with its journal files copied aside.
    private func legacyStore(in directory: URL) throws {
        let container = try CairnStore.container(at: directory.appending(path: "default.store"))
        container.mainContext.insert(Feed(url: "https://rss.test/feed", title: "Blog RSS"))
        try container.mainContext.save()
    }

    @Test func storeIsCopiedAndOpens() throws {
        let legacy = try folder(), target = try folder().appending(path: "app/default.store")
        try legacyStore(in: legacy)

        #expect(try LegacyImport.importStore(from: legacy, to: target))

        let container = try CairnStore.container(at: target) // a context does not retain its container
        #expect(try container.mainContext.fetch(FetchDescriptor<Feed>()).map(\.title) == ["Blog RSS"])
        #expect(!FileManager.default.fileExists(atPath: target.path(percentEncoded: false) + ".importing"))
    }

    /// Plain files: a real store is still being checkpointed by its closing container, which would change the "source".
    @Test func legacyIsLeftUntouchedAndJournalsFollow() throws {
        let legacy = try folder(), target = try folder().appending(path: "default.store")
        for (suffix, text) in [("", "db"), ("-wal", "wal"), ("-shm", "shm")] {
            try Data(text.utf8).write(to: legacy.appending(path: "default.store" + suffix))
        }

        try LegacyImport.importStore(from: legacy, to: target)

        for (suffix, text) in [("", "db"), ("-wal", "wal"), ("-shm", "shm")] {
            #expect(try Data(contentsOf: legacy.appending(path: "default.store" + suffix)) == Data(text.utf8))
            #expect(try Data(contentsOf: URL(filePath: target.path(percentEncoded: false) + suffix)) == Data(text.utf8))
        }
    }

    @Test func existingStoreIsNeverOverwritten() throws {
        let legacy = try folder(), target = try folder().appending(path: "default.store")
        try legacyStore(in: legacy)
        try Data("mine".utf8).write(to: target)

        #expect(try !LegacyImport.importStore(from: legacy, to: target))
        #expect(try Data(contentsOf: target) == Data("mine".utf8))
    }

    @Test func noLegacyContainer() throws {
        let target = try folder().appending(path: "app/default.store")

        #expect(try !LegacyImport.importStore(from: try folder(), to: target))
        #expect(!FileManager.default.fileExists(atPath: target.path(percentEncoded: false)))
        // A fresh install opens an empty library without error.
        let container = try CairnStore.container(at: target)
        #expect(try container.mainContext.fetch(FetchDescriptor<Feed>()).isEmpty)
    }

    @Test func settingsAreTakenOnceAndNeverOverwrite() throws {
        let plist = try folder().appending(path: "legacy.plist")
        try PropertyListSerialization.data(fromPropertyList: ["digestEngine": "ollama", "showListIcons": false] as [String: Any],
                                           format: .binary, options: 0).write(to: plist)
        let name = "cairn-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        defaults.set(true, forKey: "showListIcons")

        #expect(LegacyImport.importSettings(from: plist, into: defaults))
        #expect(defaults.string(forKey: "digestEngine") == "ollama")
        #expect(defaults.bool(forKey: "showListIcons"))

        defaults.removeObject(forKey: "digestEngine")
        #expect(!LegacyImport.importSettings(from: plist, into: defaults))
        #expect(defaults.object(forKey: "digestEngine") == nil)
    }

    @Test func missingPreferencesFileIsHarmless() throws {
        let name = "cairn-test-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }

        #expect(!LegacyImport.importSettings(from: try folder().appending(path: "none.plist"), into: defaults))
    }
}
