import Foundation

/// Takes over the data of the sandboxed versions of Cairn, which lived in `~/Library/Containers/<bundle id>/Data`.
/// Everything is copied, never moved: the old container stays as it was, so going back to an older version still works.
public enum LegacyImport {
    public static let importedKey = "sandboxDataImported"

    /// `~/Library/Containers/<bundle id>/Data` of the sandboxed app.
    public static func container(bundleID: String, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        home.appending(path: "Library/Containers/\(bundleID)/Data")
    }

    /// The store, with its journal files and external data, copied from `legacy` (the folder holding `default.store`).
    /// Nothing happens when `store` already exists or there is nothing to copy. Returns whether a store was copied.
    @discardableResult
    public static func importStore(from legacy: URL, to store: URL) throws -> Bool {
        let files = FileManager.default
        let source = legacy.appending(path: "default.store")
        guard !files.fileExists(atPath: store.path(percentEncoded: false)), files.fileExists(atPath: source.path(percentEncoded: false)) else { return false }
        try files.createDirectory(at: store.deletingLastPathComponent(), withIntermediateDirectories: true)
        // Copied beside the final name, then renamed: a copy cut short must not look like a store on the next launch.
        let partial = store.appendingPathExtension("importing")
        try? files.removeItem(at: partial)
        try files.copyItem(at: source, to: partial)
        for suffix in ["-wal", "-shm"] {
            let journal = legacy.appending(path: "default.store" + suffix)
            guard files.fileExists(atPath: journal.path(percentEncoded: false)) else { continue }
            let target = URL(filePath: partial.path(percentEncoded: false) + suffix)
            try? files.removeItem(at: target)
            try files.copyItem(at: journal, to: target)
        }
        // SwiftData keeps large attributes (icons) next to the store, in ".default_SUPPORT".
        let support = legacy.appending(path: ".default_SUPPORT")
        let supportTarget = store.deletingLastPathComponent().appending(path: ".default_SUPPORT")
        if files.fileExists(atPath: support.path(percentEncoded: false)), !files.fileExists(atPath: supportTarget.path(percentEncoded: false)) {
            try files.copyItem(at: support, to: supportTarget)
        }
        for suffix in ["-wal", "-shm"] where files.fileExists(atPath: partial.path(percentEncoded: false) + suffix) {
            try files.moveItem(atPath: partial.path(percentEncoded: false) + suffix, toPath: store.path(percentEncoded: false) + suffix)
        }
        try files.moveItem(at: partial, to: store)
        return true
    }

    /// The settings of the old container's preferences file, for the keys `defaults` does not have yet. Done once:
    /// afterwards a setting the user deleted does not come back.
    @discardableResult
    public static func importSettings(from plist: URL, into defaults: UserDefaults) -> Bool {
        guard !defaults.bool(forKey: importedKey) else { return false }
        defer { defaults.set(true, forKey: importedKey) }
        guard let data = try? Data(contentsOf: plist),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return false }
        for (key, value) in values where defaults.object(forKey: key) == nil { defaults.set(value, forKey: key) }
        return true
    }
}
