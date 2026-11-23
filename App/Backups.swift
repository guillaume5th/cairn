import CairnCore
import Foundation
import SwiftUI

/// Daily backup to a folder the user chose once (kept by a security-scoped bookmark), and its restore.
@MainActor
enum BackupSettings {
    static let folderKey = "backupFolderBookmark"
    /// Seconds since 1970 of the last written backup, 0 when none (a Double so `@AppStorage` can show it).
    static let lastDateKey = "backupLastDate"
    static let lastFailureKey = "backupLastFailure"
    static let errorKey = "backupError"
    static let keepCount = 7

    /// Settings worth restoring; interface state (selection, last digest attempt) and the backup's own keys stay out.
    static let settingKeys = [TextScale.key, "showListIcons", AppState.dockBadgeKey, AppState.refreshIntervalKey,
                              "articleSummaryHidden", "collapsedFolders", DigestSettings.enabledKey,
                              DigestSettings.timeKey, DigestSettings.engineKey, DigestSettings.ollamaURLKey,
                              DigestSettings.ollamaModelKey, DigestSettings.claudeCodePathKey, DigestSettings.claudeCodeModelKey,
                              DigestSettings.claudeModelKey, DigestSettings.retentionKey, DigestSettings.notifyKey,
                              Retention.key, ContentView.oldestFirstKey]

    private static var defaults: UserDefaults { .standard }

    static var hasFolder: Bool { defaults.data(forKey: folderKey) != nil }

    /// Due once a day; after a failure, retried an hour later rather than every minute.
    static var isDue: Bool {
        let now = Date.now.timeIntervalSince1970
        return hasFolder
            && now >= defaults.double(forKey: lastDateKey) + 86_400
            && now >= defaults.double(forKey: lastFailureKey) + 3_600
    }

    /// The chosen folder; a stale bookmark is renewed.
    static func folder() throws -> URL? {
        guard let data = defaults.data(forKey: folderKey) else { return nil }
        var isStale = false
        let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
        if isStale, let fresh = try? url.bookmarkData(options: .withSecurityScope) { defaults.set(fresh, forKey: folderKey) }
        return url
    }

    /// `url` comes from the folder picker, which grants access for this session only.
    static func setFolder(_ url: URL) throws {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        defaults.set(try url.bookmarkData(options: .withSecurityScope), forKey: folderKey)
        defaults.removeObject(forKey: errorKey)
        defaults.removeObject(forKey: lastFailureKey)
    }

    static func currentSettings() -> [String: Backup.SettingValue] {
        var settings: [String: Backup.SettingValue] = [:]
        for key in settingKeys {
            switch defaults.object(forKey: key) {
            case let number as NSNumber where CFGetTypeID(number) == CFBooleanGetTypeID(): settings[key] = .bool(number.boolValue)
            case let number as NSNumber where CFNumberIsFloatType(number): settings[key] = .double(number.doubleValue)
            case let number as NSNumber: settings[key] = .int(number.intValue)
            case let string as String: settings[key] = .string(string)
            default: break
            }
        }
        return settings
    }

    /// A key missing from the backup goes back to its default value.
    static func apply(_ settings: [String: Backup.SettingValue]) {
        for key in settingKeys {
            switch settings[key] {
            case let .bool(value): defaults.set(value, forKey: key)
            case let .int(value): defaults.set(value, forKey: key)
            case let .double(value): defaults.set(value, forKey: key)
            case let .string(value): defaults.set(value, forKey: key)
            case nil: defaults.removeObject(forKey: key)
            }
        }
    }

    /// "Cairn 2026-11-13 1530.json": sorting by name sorts by date, and the pattern tells Cairn's backups apart.
    static func fileName(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HHmm"
        return "Cairn \(formatter.string(from: date)).json"
    }

    static func isBackupFile(_ name: String) -> Bool {
        name.wholeMatch(of: /Cairn \d{4}-\d{2}-\d{2} \d{4}\.json/) != nil
    }
}

extension AppState {
    /// Writes a backup in the chosen folder (atomically), then keeps only the most recent ones.
    func backUp() {
        let defaults = UserDefaults.standard
        do {
            guard let folder = try BackupSettings.folder() else { return }
            let now = Date.now
            let data = try Library.makeBackup(context: context, settings: BackupSettings.currentSettings(), now: now).encoded()
            let accessing = folder.startAccessingSecurityScopedResource()
            defer { if accessing { folder.stopAccessingSecurityScopedResource() } }
            try data.write(to: folder.appending(path: BackupSettings.fileName(at: now)), options: .atomic)
            let files = try FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))
                .filter(BackupSettings.isBackupFile).sorted(by: >)
            for name in files.dropFirst(BackupSettings.keepCount) {
                try? FileManager.default.removeItem(at: folder.appending(path: name))
            }
            defaults.set(now.timeIntervalSince1970, forKey: BackupSettings.lastDateKey)
            defaults.removeObject(forKey: BackupSettings.errorKey)
            defaults.removeObject(forKey: BackupSettings.lastFailureKey)
        } catch {
            defaults.set(String(localized: "Backup failed: \(error.localizedDescription)"), forKey: BackupSettings.errorKey)
            defaults.set(Date.now.timeIntervalSince1970, forKey: BackupSettings.lastFailureKey)
        }
    }

    /// Reads the chosen file; nothing changes until `restore` is confirmed.
    func readBackup(_ result: Result<URL, any Error>) -> Backup? {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            return try Backup.decode(try Data(contentsOf: url))
        } catch {
            message = error.localizedDescription
            return nil
        }
    }

    /// Replaces the library once the window's views are gone, then lets the window start over on String(localized: "All articles").
    func restore(_ backup: Backup) async {
        isRestoring = true
        defer { isRestoring = false }
        try? await Task.sleep(for: .milliseconds(200)) // lets SwiftUI tear the views down first
        do {
            try Library.restore(backup, context: context)
            try context.save()
            BackupSettings.apply(backup.settings)
            UserDefaults.standard.removeObject(forKey: "selectionMemory") // its identifiers are gone
            updateBadge()
            Task { await refresh() }
        } catch {
            context.rollback()
            message = String(localized: "Restore failed: \(error.localizedDescription)")
        }
    }
}

/// The Backup section of Settings.
struct BackupSection: View {
    @Environment(AppState.self) private var state
    @AppStorage(BackupSettings.folderKey) private var bookmark: Data?
    @AppStorage(BackupSettings.lastDateKey) private var lastDate = 0.0
    @AppStorage(BackupSettings.errorKey) private var error: String?
    @State private var isChoosingFolder = false
    @State private var isChoosingBackup = false
    @State private var backupToRestore: Backup?

    var body: some View {
        Section {
            LabeledContent("Folder") {
                HStack {
                    Text(folderName ?? String(localized: "None")).foregroundStyle(.secondary)
                    Button("Choose…") { isChoosingFolder = true }
                        .fileImporter(isPresented: $isChoosingFolder, allowedContentTypes: [.folder]) { result in
                            guard let url = try? result.get() else { return }
                            do {
                                try BackupSettings.setFolder(url)
                                state.backUp()
                            } catch {
                                state.message = error.localizedDescription
                            }
                        }
                }
            }
            HStack {
                Button("Back up now") { state.backUp() }
                    .disabled(bookmark == nil)
                Spacer()
                Button("Restore…") { isChoosingBackup = true }
                    .fileImporter(isPresented: $isChoosingBackup, allowedContentTypes: [.json]) { result in
                        backupToRestore = state.readBackup(result)
                    }
            }
        } header: {
            Text("Backup")
        } footer: {
            Group {
                if let error {
                    Label(error, systemImage: "exclamationmark.triangle")
                } else if bookmark == nil {
                    Text("Choose a folder, for example in iCloud Drive, to back up your subscriptions, articles, cairns and settings there every day.")
                } else if lastDate > 0 {
                    Text("Last backup: \(Date(timeIntervalSince1970: lastDate).formatted(date: .abbreviated, time: .shortened)). The \(BackupSettings.keepCount) most recent are kept.")
                }
            }
            .foregroundStyle(.secondary)
        }
        .confirmationDialog("Restore the backup of \(backupToRestore?.createdAt.formatted(date: .long, time: .shortened) ?? "")?",
                            isPresented: Binding(get: { backupToRestore != nil }, set: { if !$0 { backupToRestore = nil } }),
                            presenting: backupToRestore) { backup in
            Button("Restore", role: .destructive) { Task { await state.restore(backup) } }
        } message: { _ in
            Text("Your current subscriptions, folders, cairns, articles and settings will be replaced by those of the backup, as they were at that time.")
        }
    }

    private var folderName: String? {
        _ = bookmark // re-evaluated when the folder changes
        return (try? BackupSettings.folder())?.lastPathComponent
    }
}
