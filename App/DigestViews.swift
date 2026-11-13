import CairnCore
import SwiftData
import SwiftUI

/// Daily digest settings, kept on this Mac (UserDefaults). Keys shared by `@AppStorage` and `AppState`.
enum DigestSettings {
    static let timeKey = "digestTime"
    static let engineKey = "digestEngine"
    static let ollamaURLKey = "ollamaURL"
    static let ollamaModelKey = "ollamaModel"
    static let retentionKey = "digestRetentionDays"
    static let lastAttemptKey = "digestLastAttempt"
    static let notifyKey = "digestNotify"
    static let enabledKey = "digestEnabled"

    /// Minutes after midnight.
    static let defaultTime = 8 * 60
    static let defaultOllamaURL = "http://localhost:11434"
    static let defaultOllamaModel = "llama3.2"
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
        guard defaults.string(forKey: engineKey) == Engine.ollama.rawValue else { return (AppleSummarizer(), "Apple") }
        let model = defaults.string(forKey: ollamaModelKey) ?? defaultOllamaModel
        let address = defaults.string(forKey: ollamaURLKey) ?? defaultOllamaURL
        guard let url = URL(string: address), ["http", "https"].contains(url.scheme?.lowercased()) else { throw CairnError.invalidURL }
        return (OllamaSummarizer(baseURL: url, model: model), "Ollama (\(model))")
    }

    static func timeText(_ minutes: Int) -> String {
        Calendar.current.date(bySettingHour: minutes / 60, minute: minutes % 60, second: 0, of: .now)?
            .formatted(date: .omitted, time: .shortened) ?? ""
    }

    enum Engine: String, CaseIterable {
        case apple, ollama
    }
}

struct SettingsView: View {
    @AppStorage(DigestSettings.timeKey) private var time = DigestSettings.defaultTime
    @AppStorage(DigestSettings.engineKey) private var engine = DigestSettings.Engine.apple
    @AppStorage(DigestSettings.ollamaURLKey) private var ollamaURL = DigestSettings.defaultOllamaURL
    @AppStorage(DigestSettings.ollamaModelKey) private var ollamaModel = DigestSettings.defaultOllamaModel
    @AppStorage(DigestSettings.retentionKey) private var retention = DigestSettings.defaultRetention
    @State private var installedModels: [String] = []
    @State private var modelsError: String?
    @State private var reloadCount = 0
    @AppStorage(DigestSettings.notifyKey) private var notifies = false
    @AppStorage(DigestSettings.enabledKey) private var isEnabled = true
    @State private var notificationsDenied = false

    private static let scheduleNote = "Les articles des dernières 24 heures sont résumés à cette heure-là si Cairn est ouvert, sinon au lancement suivant."
    private static let disabledNote = "Aucun résumé n'est produit automatiquement. Tu peux en générer un depuis la liste des résumés."
    private static let ollamaPlace = "Ollama doit tourner sur ce Mac ou sur ton réseau."
    private static let notificationsDeniedNote = "Les notifications de Cairn sont désactivées : autorise-les dans Réglages Système > Notifications > Cairn."
    @AppStorage(TextScale.key) private var textScale = 1.0
    @AppStorage("showListIcons") private var showListIcons = true

    var body: some View {
        Form {
            // Also in the Mac's View menu.
            Section("Affichage") {
                // Value then arrows on the right, like "Conserver les résumés".
                LabeledContent("Taille du texte") {
                    HStack {
                        Text(textScale, format: .percent.precision(.fractionLength(0))).monospacedDigit()
                        Stepper("Taille du texte",
                                onIncrement: textScale < TextScale.range.upperBound ? { textScale = TextScale.stepped(textScale, by: 0.1) } : nil,
                                onDecrement: textScale > TextScale.range.lowerBound ? { textScale = TextScale.stepped(textScale, by: -0.1) } : nil)
                            .labelsHidden()
                        Button("Taille normale", systemImage: "arrow.counterclockwise") { textScale = 1 }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.borderless)
                            .help("Taille normale")
                            .disabled(textScale == 1)
                    }
                }
                Toggle("Icônes dans la liste d'articles", isOn: $showListIcons)
            }
            Section {
                Toggle("Résumé automatique", isOn: $isEnabled)
                // Greyed out rather than hidden: the window fits its content and would change height.
                DatePicker("Heure du résumé", selection: timeBinding, displayedComponents: .hourAndMinute)
                    .disabled(!isEnabled)
                LabeledContent("Conserver les résumés") {
                    // Field + stepper: the standard macOS pairing for a bounded number.
                    HStack(spacing: 4) {
                        TextField("Conserver les résumés", value: $retention, format: .number)
                            .labelsHidden()
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 40)
                        Stepper("Conserver les résumés", value: $retention, in: DigestSettings.retentionRange)
                            .labelsHidden()
                        Text(retention > 1 ? "jours" : "jour")
                    }
                }
                .onChange(of: retention) {
                    let range = DigestSettings.retentionRange
                    if !range.contains(retention) { retention = min(max(retention, range.lowerBound), range.upperBound) }
                }
                // The system is asked only when the user turns it on.
                Toggle("Me prévenir quand le résumé est prêt", isOn: Binding { notifies } set: { isOn in
                    guard isOn else { notifies = false; return }
                    Task {
                        let granted = await DigestNotifications.requestAuthorization()
                        notifies = granted
                        notificationsDenied = !granted
                    }
                })
                .disabled(!isEnabled)
            } header: {
                Text("Résumé quotidien")
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isEnabled ? Self.scheduleNote : Self.disabledNote)
                    if notificationsDenied { Text(Self.notificationsDeniedNote) }
                }
                .foregroundStyle(.secondary)
            }

            Section {
                Picker("Moteur", selection: $engine) {
                    Text("Apple Intelligence").tag(DigestSettings.Engine.apple)
                    Text("Ollama").tag(DigestSettings.Engine.ollama)
                }
                // Only the chosen engine's options are shown, as in System Settings.
                if engine == .ollama {
                    TextField("Adresse du serveur", text: $ollamaURL, prompt: Text(DigestSettings.defaultOllamaURL))
                    LabeledContent("Modèle") {
                        HStack(spacing: 6) {
                            Picker("Modèle", selection: $ollamaModel) {
                                ForEach(modelChoices, id: \.self) { name in
                                    Text(installedModels.contains(name) ? name : "\(name) (non installé)").tag(name)
                                }
                            }
                            .labelsHidden()
                            .fixedSize()
                            Button("Actualiser la liste des modèles", systemImage: "arrow.clockwise") { reloadCount += 1 }
                                .labelStyle(.iconOnly)
                                .buttonStyle(.borderless)
                                .help("Relire les modèles installés sur le serveur Ollama")
                        }
                    }
                }
            } header: {
                Text("Moteur d'IA")
            } footer: {
                Group {
                    if engine == .apple {
                        Text("Les résumés quotidiens et les résumés d'articles sont rédigés sur cet appareil : les articles ne sont envoyés à aucun service en ligne.")
                    } else if let modelsError {
                        Label(modelsError, systemImage: "exclamationmark.triangle")
                    } else {
                        Text("Sert aux résumés quotidiens et aux résumés d'articles. \(Self.ollamaPlace) Installe d'autres modèles avec « ollama pull », puis actualise la liste.")
                    }
                }
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.never) // the window fits its content; no scroller
        .frame(width: 460)
        .fixedSize(horizontal: false, vertical: true)
        .task(id: "\(engine.rawValue)|\(ollamaURL)|\(reloadCount)") { await loadModels() }
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
            modelsError = models.isEmpty ? "Aucun modèle installé. Installe-en un avec « ollama pull <modèle> »." : nil
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
    @Environment(AppState.self) private var state
    @State private var digestsToDelete: [Digest] = []

    var body: some View {
        List(digests, selection: $selection) { digest in
            VStack(alignment: .leading, spacing: 2) {
                Text(digest.createdAt.formatted(.dateTime.weekday(.wide).day().month(.wide)).capitalized)
                Text("\(digest.createdAt.formatted(date: .omitted, time: .shortened)) · \(digest.items.count) article(s) · \(digest.engine)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let snippet = Library.snippet(for: query, in: digest) {
                    Text(AttributedString(snippet, highlighting: query))
                        .font(.caption)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 2)
        }
        // It gets the selection when the clicked row is part of it, else that row alone.
        .contextMenu(forSelectionType: PersistentIdentifier.self) { ids in
            let lot = digests.filter { ids.contains($0.persistentModelID) }
            if !lot.isEmpty {
                Button(lot.count == 1 ? "Supprimer le résumé…" : "Supprimer \(lot.count) résumés…", role: .destructive) {
                    digestsToDelete = lot
                }
            }
        }
        .onDeleteCommand { digestsToDelete = digests.filter { selection.contains($0.persistentModelID) } }
        .toolbar {
            // Trailing edge of the list column, like the article list's buttons.
            ToolbarItem {
                Button("Générer un résumé", systemImage: "text.badge.plus") { Task { await state.makeDigest(manual: true) } }
                    .symbolEffect(.pulse, isActive: state.isDigesting)
                    .disabled(state.isDigesting)
                    .help(state.isDigesting ? "Résumé en cours" : "Générer un résumé des dernières 24 heures maintenant")
            }
        }
        .digestDeleteConfirmation($digestsToDelete)
        .overlay {
            if digests.isEmpty { ContentUnavailableView("Aucun résumé", systemImage: "text.append") }
        }
    }
}

/// Deletes the digest once confirmed. The list then shows the next one (see `ContentView.displayedDigest`).
struct DigestDeleteConfirmation: ViewModifier {
    @Binding var digests: [Digest]
    @Environment(\.modelContext) private var context

    func body(content: Content) -> some View {
        content.confirmationDialog(digests.count == 1
                                   ? "Supprimer le résumé du \(digests[0].createdAt.formatted(date: .long, time: .shortened)) ?"
                                   : "Supprimer \(digests.count) résumés ?",
                                   isPresented: Binding(get: { !digests.isEmpty }, set: { if !$0 { digests = [] } }),
                                   presenting: digests) { lot in
            Button("Supprimer", role: .destructive) {
                for digest in lot { context.delete(digest) }
                try? context.save()
            }
        } message: { _ in
            Text("Cette action est définitive.")
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
    let query: String
    /// Whether any digest exists, searched or not.
    let hasDigests: Bool
    @AppStorage(DigestSettings.timeKey) private var digestTime = DigestSettings.defaultTime
    @AppStorage(DigestSettings.enabledKey) private var isEnabled = true
    @State private var digestsToDelete: [Digest] = []

    var body: some View {
        Group {
            if digests.count > 1 {
                ContentUnavailableView("\(digests.count) résumés sélectionnés", systemImage: "doc.on.doc")
            } else if let digest = digests.first {
                DigestView(digest: digest, query: query)
            } else if hasDigests {
                ContentUnavailableView.search(text: query)
            } else {
                ContentUnavailableView("Aucun résumé", systemImage: "text.append",
                                       description: Text(isEnabled ? "Prochain résumé à \(DigestSettings.timeText(digestTime))."
                                                                   : "Résumé automatique désactivé."))
            }
        }
        .toolbar {
            // Leading edge of the reading pane, like the article actions. Kept (disabled) without a digest: a reading
            // pane without toolbar items lets the list's buttons drift to the window's trailing edge.
            ToolbarItem {
                Button(digests.count > 1 ? "Supprimer les résumés" : "Supprimer le résumé", systemImage: "trash") {
                    digestsToDelete = digests
                }
                .disabled(digests.isEmpty)
                .help(digests.count > 1 ? "Supprimer ces résumés" : "Supprimer ce résumé")
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
                Text("Articles résumés").font(.headline)
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
