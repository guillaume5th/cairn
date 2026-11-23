import CairnCore
import SwiftData
import SwiftUI

/// Daily digest settings, kept on this Mac (UserDefaults). Keys shared by `@AppStorage` and `AppState`.
enum DigestSettings {
    static let timeKey = "digestTime"
    static let engineKey = "digestEngine"
    static let ollamaURLKey = "ollamaURL"
    static let ollamaModelKey = "ollamaModel"
    static let claudeCodePathKey = "claudeCodePath"
    static let claudeCodeModelKey = "claudeCodeModel"
    static let claudeModelKey = "claudeModel"
    static let retentionKey = "digestRetentionDays"
    static let lastAttemptKey = "digestLastAttempt"
    static let notifyKey = "digestNotify"
    static let enabledKey = "digestEnabled"

    /// Minutes after midnight.
    static let defaultTime = 8 * 60
    static let defaultOllamaURL = "http://localhost:11434"
    static let defaultOllamaModel = "llama3.2"
    /// Haiku for both Claude engines: summarizing is a light task, and the API is billed per token.
    static let defaultClaudeCodeModel = "haiku"
    static let defaultRetention = 7
    static let retentionRange = 1...90

    private static var defaults: UserDefaults { .standard }
    static var time: Int { defaults.object(forKey: timeKey) as? Int ?? defaultTime }
    static var retention: Int { defaults.object(forKey: retentionKey) as? Int ?? defaultRetention }
    static var lastAttempt: Date? { defaults.object(forKey: lastAttemptKey) as? Date }
    static var notifies: Bool { defaults.bool(forKey: notifyKey) }
    /// The automatic digest; on until turned off. The digest made on demand does not depend on it.
    static var isEnabled: Bool { defaults.object(forKey: enabledKey) as? Bool ?? true }

    /// The only gate of the automatic digest: the scheduled one and the launch catch-up both go through it.
    static var isDue: Bool { isEnabled && Digest.isDue(now: .now, minutes: time, lastAttempt: lastAttempt) }

    /// The chosen engine and its display name.
    static func summarizer() throws -> (any Summarizer, String) {
        switch Engine(rawValue: defaults.string(forKey: engineKey) ?? "") ?? .apple {
        case .apple:
            return (AppleSummarizer(), "Apple")
        case .ollama:
            let model = defaults.string(forKey: ollamaModelKey) ?? defaultOllamaModel
            let address = defaults.string(forKey: ollamaURLKey) ?? defaultOllamaURL
            guard let url = URL(string: address), ["http", "https"].contains(url.scheme?.lowercased()) else { throw CairnError.invalidURL }
            return (OllamaSummarizer(baseURL: url, model: model), "Ollama (\(model))")
        case .claudeCode:
            guard let cli = claudeCodeURL() else { throw CairnError.claudeCodeNotFound }
            let model = defaults.string(forKey: claudeCodeModelKey).flatMap { $0.isEmpty ? nil : $0 } ?? defaultClaudeCodeModel
            return (ClaudeCodeSummarizer(executable: cli, model: model), "Claude Code (\(model))")
        case .claudeAPI:
            guard let key = Credentials.anthropicKey, !key.isEmpty else { throw CairnError.anthropicKeyMissing }
            let model = defaults.string(forKey: claudeModelKey) ?? AnthropicSummarizer.defaultModel
            return (AnthropicSummarizer(apiKey: key, model: model), "Claude API (\(model))")
        }
    }

    /// The Claude Code CLI: the path set in Settings, else the first usual install place. Nil when it is not there.
    static func claudeCodeURL() -> URL? {
        let set = (defaults.string(forKey: claudeCodePathKey) ?? "").trimmingCharacters(in: .whitespaces)
        guard !set.isEmpty else { return ClaudeCodeSummarizer.locate() }
        let url = URL(filePath: (set as NSString).expandingTildeInPath)
        return FileManager.default.isExecutableFile(atPath: url.path(percentEncoded: false)) ? url : nil
    }

    static func timeText(_ minutes: Int) -> String {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now)?
            .formatted(date: .omitted, time: .shortened) ?? ""
    }

    enum Engine: String, CaseIterable {
        case apple, ollama, claudeCode, claudeAPI
    }
}

struct SettingsView: View {
    @AppStorage(DigestSettings.timeKey) private var time = DigestSettings.defaultTime
    @AppStorage(DigestSettings.engineKey) private var engine = DigestSettings.Engine.apple
    @AppStorage(DigestSettings.ollamaURLKey) private var ollamaURL = DigestSettings.defaultOllamaURL
    @AppStorage(DigestSettings.ollamaModelKey) private var ollamaModel = DigestSettings.defaultOllamaModel
    @AppStorage(DigestSettings.claudeCodePathKey) private var claudeCodePath = ""
    @AppStorage(DigestSettings.claudeCodeModelKey) private var claudeCodeModel = DigestSettings.defaultClaudeCodeModel
    @AppStorage(DigestSettings.claudeModelKey) private var claudeModel = AnthropicSummarizer.defaultModel
    /// The API key lives in the keychain, not in UserDefaults: it is loaded when Settings opens.
    @State private var apiKey = ""
    @State private var apiKeyError: String?
    @AppStorage(DigestSettings.retentionKey) private var retention = DigestSettings.defaultRetention
    @State private var installedModels: [String] = []
    @State private var modelsError: String?
    @State private var reloadCount = 0
    @AppStorage(DigestSettings.notifyKey) private var notifies = false
    @AppStorage(DigestSettings.enabledKey) private var isEnabled = true
    @State private var notificationsDenied = false
    @State private var badgesDenied = false

    private static let scheduleNote = String(localized: "Articles from the last 24 hours are summarized at that time if Cairn is open, otherwise at the next launch.")
    private static let disabledNote = String(localized: "No summary is produced automatically. You can generate one from the summaries list.")
    private static let ollamaPlace = String(localized: "Ollama must be running on this Mac or on your network.")
    private static let sentToAnthropic = String(localized: "The content of summarized articles is sent to Anthropic.")
    private static let badgesDeniedNote = String(localized: "Cairn's badges are turned off: allow them in System Settings > Notifications > Cairn.")
    private static let notificationsDeniedNote = String(localized: "Cairn's notifications are turned off: allow them in System Settings > Notifications > Cairn.")
    @AppStorage(TextScale.key) private var textScale = 1.0
    @AppStorage("showListIcons") private var showListIcons = true
    @AppStorage(AppState.refreshIntervalKey) private var refreshInterval = AppState.defaultRefreshInterval
    @AppStorage(AppState.dockBadgeKey) private var showsDockBadge = true
    @AppStorage(Retention.key) private var retentionDays = Retention.defaultDays
    @Environment(AppState.self) private var state

    var body: some View {
        Form {
            Section {
                Picker("Refresh subscriptions", selection: $refreshInterval) {
                    Text("Never").tag(0)
                    Text("Every 15 minutes").tag(15)
                    Text("Every 30 minutes").tag(30)
                    Text("Every hour").tag(60)
                    Text("Every 2 hours").tag(120)
                }
                Picker("Retain unkept articles", selection: $retentionDays) {
                    Text("7 days").tag(7)
                    Text("14 days").tag(14)
                    Text("30 days").tag(30)
                    Text("2 months").tag(60)
                    Text("3 months").tag(90)
                    Text("6 months").tag(180)
                    Text("1 year").tag(365)
                }
            } header: {
                Text("Subscriptions")
            } footer: {
                Text("The oldest are deleted when Cairn launches. Articles kept in a cairn never are.")
                    .foregroundStyle(.secondary)
            }
            // Also in the Mac's View menu.
            Section {
                // Value then arrows on the right, like "Keep summaries".
                LabeledContent("Text size") {
                    HStack {
                        Text(textScale, format: .percent.precision(.fractionLength(0))).monospacedDigit()
                        Stepper("Text size",
                                onIncrement: textScale < TextScale.range.upperBound ? { textScale = TextScale.stepped(textScale, by: 0.1) } : nil,
                                onDecrement: textScale > TextScale.range.lowerBound ? { textScale = TextScale.stepped(textScale, by: -0.1) } : nil)
                            .labelsHidden()
                        Button("Actual Size", systemImage: "arrow.counterclockwise") { textScale = 1 }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .help("Actual Size")
                            .disabled(textScale == 1)
                    }
                }
                Toggle("Icons in the Article List", isOn: $showListIcons)
                Toggle("Badge on the icon", isOn: $showsDockBadge)
                    .onChange(of: showsDockBadge) {
                        state.updateBadge()
                        if showsDockBadge { Task { _ = await DigestNotifications.requestAuthorization(); badgesDenied = await DigestNotifications.badgesDenied() } }
                    }
            } header: {
                Text("Display")
            } footer: {
                if showsDockBadge && badgesDenied { Text(Self.badgesDeniedNote).foregroundStyle(.secondary) }
            }
            .task { badgesDenied = await DigestNotifications.badgesDenied() }
            Section {
                Toggle("Automatic summary", isOn: $isEnabled)
                // Greyed out rather than hidden: the window fits its content and would change height.
                DatePicker("Summary time", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .disabled(!isEnabled)
                LabeledContent("Keep summaries") {
                    // Field + stepper: the standard macOS pairing for a bounded number.
                    HStack(spacing: 4) {
                        TextField("Keep summaries", value: $retention, format: .number)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                        Stepper("Keep summaries", value: $retention, in: DigestSettings.retentionRange)
                            .labelsHidden()
                        Text(retention > 1 ? "days" : "day")
                    }
                }
                .onChange(of: retention) {
                    let range = DigestSettings.retentionRange
                    if !range.contains(retention) { retention = min(max(retention, range.lowerBound), range.upperBound) }
                }
                // The system is asked only when the user turns it on.
                Toggle("Notify me when the summary is ready", isOn: Binding { notifies } set: { isOn in
                    guard isOn else { notifies = false; return }
                    Task {
                        let granted = await DigestNotifications.requestAuthorization()
                        notifies = granted
                        notificationsDenied = !granted
                    }
                })
                .disabled(!isEnabled)
            } header: {
                Text("Daily summary")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEnabled ? Self.scheduleNote : Self.disabledNote)
                    if notificationsDenied { Text(Self.notificationsDeniedNote) }
                }
                .foregroundStyle(.secondary)
            }

            Section {
                Picker("Engine", selection: $engine) {
                    Text("Apple Intelligence").tag(DigestSettings.Engine.apple)
                    Text("Ollama").tag(DigestSettings.Engine.ollama)
                    Text("Claude Code").tag(DigestSettings.Engine.claudeCode)
                    Text("Claude (API)").tag(DigestSettings.Engine.claudeAPI)
                }
                // Only the chosen engine's options are shown, as in System Settings.
                if engine == .ollama {
                    TextField("Server address", text: $ollamaURL, prompt: Text(DigestSettings.defaultOllamaURL))
                    LabeledContent("Model") {
                        HStack(spacing: 6) {
                            Picker("Model", selection: $ollamaModel) {
                                ForEach(modelChoices, id: \.self) { name in
                                    Text(installedModels.contains(name) ? name : String(localized: "\(name) (not installed)")).tag(name)
                                }
                            }
                            .labelsHidden()
                            .fixedSize()
                            Button("Refresh the model list", systemImage: "arrow.clockwise") { reloadCount += 1 }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .help("Reload the models installed on the Ollama server")
                        }
                    }
                }
                if engine == .claudeCode {
                    TextField("CLI path", text: $claudeCodePath,
                              prompt: Text(ClaudeCodeSummarizer.locate()?.path(percentEncoded: false) ?? "~/.local/bin/claude"))
                    Picker("Model", selection: $claudeCodeModel) {
                        Text("Haiku").tag("haiku")
                        Text("Sonnet").tag("sonnet")
                        Text("Opus").tag("opus")
                    }
                }
                if engine == .claudeAPI {
                    SecureField("API key", text: $apiKey, prompt: Text("sk-ant-…"))
                        .onChange(of: apiKey) {
                            do { try Credentials.setAnthropicKey(apiKey); apiKeyError = nil } catch { apiKeyError = String(localized: "The key could not be saved in the keychain: \(error.localizedDescription)") }
                        }
                    Picker("Model", selection: $claudeModel) {
                        Text("Haiku").tag("claude-haiku-5-5")
                        Text("Sonnet").tag("claude-sonnet-5-5")
                        Text("Opus").tag("claude-opus-5-5")
                    }
                }
            } header: {
                Text("AI engine")
            } footer: {
                Group {
                    if engine == .apple {
                        Text("Daily and article summaries are written on this device: articles are not sent to any online service.")
                    } else if engine == .claudeCode {
                        if DigestSettings.claudeCodeURL() == nil {
                            Label(CairnError.claudeCodeNotFound.localizedDescription, systemImage: "exclamationmark.triangle")
                        } else {
                            Text("Uses the account signed in to Claude Code, so your Claude plan. \(Self.sentToAnthropic)")
                        }
                    } else if engine == .claudeAPI {
                        if let apiKeyError {
                            Label(apiKeyError, systemImage: "exclamationmark.triangle")
                        } else {
                            Text("Billed to your Anthropic API account, outside the Claude plan. The key is kept in the keychain. \(Self.sentToAnthropic)")
                        }
                    } else if let modelsError {
                        Label(modelsError, systemImage: "exclamationmark.triangle")
                    } else {
                        Text("Used for daily and article summaries. \(Self.ollamaPlace) Install other models with “ollama pull”, then refresh the list.")
                    }
                }
                .foregroundStyle(.secondary)
            }

            BackupSection()
        }
        .formStyle(.grouped)
        .scrollIndicators(.never) // the window fits its content; no scroller
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .task(id: "\(engine.rawValue)|\(ollamaURL)|\(reloadCount)") { await loadModels() }
        .task { apiKey = Credentials.anthropicKey ?? "" }
    }

    /// Installed models, plus the configured one when the server lacks it (shown as not installed).
    private var modelChoices: [String] {
        installedModels.contains(ollamaModel) ? installedModels : [ollamaModel] + installedModels
    }

    private func loadModels() async {
        guard engine == .ollama else { return }
        try? await Task.sleep(for: .milliseconds(400)) // the address may still be being typed
        guard !Task.isCancelled else { return }
        do {
            guard let url = URL(string: ollamaURL), ["http", "https"].contains(url.scheme?.lowercased()) else {
                throw CairnError.invalidURL
            }
            let models = try await OllamaSummarizer(baseURL: url, model: ollamaModel).installedModels()
            guard !Task.isCancelled else { return }
            installedModels = models
            modelsError = models.isEmpty ? String(localized: "No model installed. Install one with “ollama pull <model>”.") : nil
            // "llama3.2" and "llama3.2:latest" are the same model: use the name the server lists.
            if !models.contains(ollamaModel), models.contains(ollamaModel + ":latest") { ollamaModel += ":latest" }
        } catch {
            guard !Task.isCancelled else { return }
            installedModels = []
            modelsError = error.localizedDescription
        }
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: { Calendar.current.date(bySettingHour: time / 60, minute: time % 60, second: 0, of: .now) ?? .now },
            set: {
                let parts = Calendar.current.dateComponents([.hour, .minute], from: $0)
                time = (parts.hour ?? 0) * 60 + (parts.minute ?? 0)
            }
        )
    }
}

struct DigestListView: View {
    let digests: [Digest]
    /// Current search: a highlighted excerpt is shown under each row.
    let query: String
    @Binding var selection: Set<PersistentIdentifier>
    /// Selection mode, turned on with the button, as in the article list.
    @Binding var isSelectionModeOn: Bool
    @Binding var unreadOnly: Bool
    @Environment(AppState.self) private var state
    @State private var digestsToDelete: [Digest] = []

    var body: some View {
        List(digests, selection: listSelection) { digest in
            HStack(spacing: 10) {
                if isSelecting { SelectionMark(isTicked: selection.contains(digest.persistentModelID)) }
                // Hidden rather than removed when read, so every row keeps the same alignment.
                UnreadDot()
                    .opacity(digest.isRead ? 0 : 1)
                    .accessibilityLabel("Unread")
                    .accessibilityHidden(digest.isRead)
                VStack(alignment: .leading, spacing: 2) {
                    Text(digest.createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalized)
                    Text("\(digest.createdAt.formatted(date: .omitted, time: .shortened)) · \(String(localized: "\(digest.items.count) articles")) · \(digest.engine)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let snippet = Library.snippet(for: query, in: digest) {
                        Text(AttributedString(snippet, highlighting: query))
                            .font(.caption)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.vertical, 2)
            .modifier(TickOnClick(isOn: isSelectionModeOn) { selection.formSymmetricDifference([digest.persistentModelID]) })
            // Same labels and symbols as the article rows.
            .swipeActions(edge: .leading) {
                Button(digest.isRead ? "Mark as unread" : "Mark as read",
                       systemImage: digest.isRead ? "circle.inset.filled" : "checkmark.circle") { digest.isRead.toggle() }
                    .tint(.accentColor)
                    .labelStyle(.iconOnly)
            }
            // Asks for confirmation like the other ways to delete, so no full swipe.
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button("Delete summary…", systemImage: "trash", role: .destructive) { digestsToDelete = [digest] }
                    .labelStyle(.iconOnly)
            }
        }
        // It gets the selection when the clicked row is part of it, else that row alone.
        .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
            let lot = digests.filter { ids.contains($0.persistentModelID) }
            if !lot.isEmpty {
                let anyUnread = lot.contains { !$0.isRead }
                Button(anyUnread ? "Mark as read" : "Mark as unread",
                       systemImage: anyUnread ? "checkmark.circle" : "circle.inset.filled") {
                    for digest in lot { digest.isRead = anyUnread }
                }
                Divider()
                Button("Delete \(lot.count) summaries…", role: .destructive) {
                    digestsToDelete = lot
                }
            }
        }
        .onDeleteCommand { digestsToDelete = digests.filter { selection.contains($0.persistentModelID) } }
        .onExitCommand { if isSelecting { leaveSelection() } }
        .navigationTitle(listTitle)
        .toolbar {
            // Trailing edge of the list column, in the article list's order (see `ArticleListView`).
            ToolbarItem {
                Button("Generate a summary", systemImage: "text.badge.plus") { Task { await state.makeDigest(manual: true) } }
                    .symbolEffect(.pulse, isActive: state.isDigesting)
                    .disabled(state.isDigesting)
                    .help(state.isDigesting ? "Summary in progress" : "Generate a summary of the last 24 hours now")
            }
            ToolbarItem {
                Toggle(isOn: Binding { isSelecting } set: { $0 ? (isSelectionModeOn = true) : leaveSelection() }) {
                    Label("Select", systemImage: "checklist")
                }
                .help(isSelecting ? "End selection (Esc)" : "Select summaries")
            }
            ToolbarItemGroup {
                Toggle(isOn: $unreadOnly) { Label("Unread only", systemImage: "line.3.horizontal.decrease.circle") }
                    .help("Show only unread summaries")
                Button("Mark all as read", systemImage: "checkmark.circle") {
                    for digest in digests { digest.isRead = true }
                }
                .help("Mark all summaries in the list as read")
            }
        }
        .digestDeleteConfirmation($digestsToDelete)
        .overlay {
            if digests.isEmpty { ContentUnavailableView("No summaries", systemImage: "text.append") }
        }
    }

    private var isSelecting: Bool { isSelectionModeOn || selection.count > 1 }

    /// As in `ArticleListView`: in selection mode the rows' own click ticks them, the table's changes are ignored.
    private var listSelection: Binding<Set<PersistentIdentifier>> {
        isSelectionModeOn ? Binding { selection } set: { _ in } : $selection
    }

    /// Drops what was ticked without an action.
    private func leaveSelection() {
        isSelectionModeOn = false
        selection = []
    }

    /// In selection mode, the count replaces the list's name, as in Mail.
    private var listTitle: String {
        guard isSelecting else { return String(localized: "Daily summaries") }
        let count = digests.count { selection.contains($0.persistentModelID) }
        return count == 0 ? String(localized: "No selection") : String(localized: "\(count) selected")
    }
}

/// Deletes the digest once confirmed. The list then shows the next one (see `ContentView.displayedDigest`).
struct DigestDeleteConfirmation: ViewModifier {
    @Binding var digests: [Digest]
    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.confirmationDialog(digests.count == 1
                                   ? "Delete the summary of \(digests[0].createdAt.formatted(date: .long, time: .shortened))?"
                                   : "Delete \(digests.count) summaries?",
                                   isPresented: Binding(get: { !digests.isEmpty }, set: { if !$0 { digests = [] } }),
                                   presenting: digests) { lot in
            Button("Delete", role: .destructive) {
                for digest in lot { context.delete(digest) }
                try? context.save()
            }
        } message: { _ in
            Text("This action cannot be undone.")
        }
    }
}

extension View {
    func digestDeleteConfirmation(_ digests: Binding<[Digest]>) -> some View {
        modifier(DigestDeleteConfirmation(digests: digests))
    }
}

/// Reading pane of the « Résumés quotidiens » entry: the digest shown, the count of several selected ones, or why there is none.
struct DigestDetail: View {
    /// Selected digests: one is shown, several are counted.
    let digests: [Digest]
    /// Selection mode: the ticked digests are counted, even one or none.
    let isSelecting: Bool
    let query: String
    /// Whether any digest exists, searched or not.
    let hasDigests: Bool
    @AppStorage(DigestSettings.timeKey) private var digestTime = DigestSettings.defaultTime
    @AppStorage(DigestSettings.enabledKey) private var isEnabled = true
    @State private var digestsToDelete: [Digest] = []

    var body: some View {
        Group {
            if digests.count > 1 || isSelecting {
                ContentUnavailableView(digests.isEmpty ? "No summary selected"
                                       : "\(digests.count) summaries selected",
                                       systemImage: "doc.on.doc")
            } else if let digest = digests.first {
                DigestView(digest: digest, query: query)
            } else if hasDigests {
                ContentUnavailableView.search(text: query)
            } else {
                ContentUnavailableView("No summaries", systemImage: "text.append",
                                       description: Text(isEnabled ? "Next summary at \(DigestSettings.timeText(digestTime))."
                                                                   : "Automatic summary turned off."))
            }
        }
        .toolbar {
            // Leading edge of the reading pane, like the article actions. Kept (disabled) without a digest: a reading
            // pane without toolbar items lets the list's buttons drift to the window's trailing edge.
            ToolbarItemGroup {
                // The article reader's button: the filled dot the list shows on unread rows.
                let anyUnread = digests.contains { !$0.isRead }
                Button(anyUnread ? "Mark as read" : "Mark as unread",
                       systemImage: anyUnread ? "checkmark.circle" : "circle.inset.filled") {
                    for digest in digests { digest.isRead = anyUnread }
                }
                .disabled(digests.isEmpty)
                .help(anyUnread ? "Mark as read" : "Mark as unread")
                Button(digests.count > 1 ? "Delete summaries" : "Delete summary", systemImage: "trash") {
                    digestsToDelete = digests
                }
                .disabled(digests.isEmpty)
                .help(digests.count > 1 ? "Delete these summaries" : "Delete this summary")
            }
        }
        .digestDeleteConfirmation($digestsToDelete)
    }
}

struct DigestView: View {
    let digest: Digest
    /// Current search, highlighted in the text and the article list.
    let query: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(digest.createdAt.formatted(date: .complete, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                ForEach(Array(digest.text.components(separatedBy: .newlines).enumerated()), id: \.offset) { _, line in
                    MarkdownLine(line: line, query: query)
                }
                Divider().padding(.vertical, 8)
                Text("Summarized articles").font(.headline)
                ForEach(digest.items, id: \.self) { item in
                    VStack(alignment: .leading, spacing: 0) {
                        let title = AttributedString(item.title.isEmpty ? item.link : item.title, highlighting: query)
                        if let url = URL(string: item.link) {
                            Link(destination: url) { Text(title) }
                        } else {
                            Text(title)
                        }
                        Text(AttributedString(item.source, highlighting: query)).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .textSelection(.enabled)
            .frame(maxWidth: 700, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        // Shown alone means read, like an article; several selected ones only show their count.
        .task(id: digest.persistentModelID) { digest.isRead = true }
    }
}

/// One line of an AI summary. `Text` renders inline Markdown only, so headings are turned into a bold font here.
struct MarkdownLine: View {
    let line: String
    var query = ""

    var body: some View {
        let heading = line.prefix { $0 == "#" }.count
        let body = heading > 0 ? String(line.dropFirst(heading)).trimmingCharacters(in: .whitespaces) : line
        var attributed = (try? AttributedString(markdown: body, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(body)
        let _ = attributed.highlight(query)
        let text = Text(attributed)
        if heading > 0 {
            text.font(heading == 1 ? .title2.bold() : .headline).padding(.top, 6)
        } else if let item = Self.listItem(line) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(item.level == 0 ? "•" : "◦").foregroundStyle(.secondary)
                Self.inline(item.text, query: query)
            }
            .padding(.leading, CGFloat(item.level) * 16)
        } else if !line.trimmingCharacters(in: .whitespaces).isEmpty {
            text
        }
    }

    /// A Markdown list line ("* ", "- " or "+ "), its nesting level (two spaces or a tab per level) and its text.
    static func listItem(_ line: String) -> (level: Int, text: String)? {
        let indent = line.prefix { $0 == " " || $0 == "\t" }
        let rest = line.dropFirst(indent.count)
        guard let marker = rest.first, "*-+".contains(marker), rest.dropFirst().first == " " else { return nil }
        let width = indent.reduce(0) { $0 + ($1 == "\t" ? 2 : 1) }
        return (width / 2, String(rest.dropFirst(2)))
    }

    private static func inline(_ markdown: String, query: String) -> Text {
        var attributed = (try? AttributedString(markdown: markdown, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
            ?? AttributedString(markdown)
        let _ = attributed.highlight(query)
        return Text(attributed)
    }
}
