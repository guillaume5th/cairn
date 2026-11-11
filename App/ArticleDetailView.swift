import CairnCore
import SwiftData
import SwiftUI

struct ArticleDetailView: View {
    @Bindable var article: Article
    @Environment(\.openURL) private var openURL
    @State private var confirmUnkeep = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title.isEmpty ? "Sans titre" : article.title)
                    .font(.title2.bold())
                    .textSelection(.enabled)
                Text("\(article.sourceTitle) · \(article.publishedAt.formatted(date: .abbreviated, time: .shortened))")
                    .foregroundStyle(.secondary)
            }
            .padding()
            Divider()

            if let html = article.content {
                HTMLView(html: html, baseURL: url)
            } else {
                ContentUnavailableView {
                    Label("Aucun contenu", systemImage: "doc")
                } description: {
                    Text("Le flux ne fournit pas de contenu pour cet article.")
                } actions: {
                    if let url { Button("Ouvrir dans le navigateur") { openURL(url) } }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if article.isKept {
                Divider()
                KeptEditor(article: article).padding()
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Button(article.isKept ? "Retirer du cairn" : "Garder",
                       systemImage: article.isKept ? "mountain.2.fill" : "mountain.2") {
                    if !article.isKept {
                        Library.setKept(true, article)
                    } else if article.note.isEmpty && (article.tags ?? []).isEmpty {
                        Library.setKept(false, article)
                    } else {
                        confirmUnkeep = true
                    }
                }
                .help(article.isKept ? "Retirer cet article du cairn" : "Garder cet article dans le cairn")
                Button("Marquer comme non lu", systemImage: "circle") { article.isRead = false }
                    .help("Marquer comme non lu")
                Button("Ouvrir dans le navigateur", systemImage: "safari") { if let url { openURL(url) } }
                    .disabled(url == nil)
                    .help("Ouvrir dans le navigateur")
            }
        }
        .confirmationDialog("Retirer cet article du cairn ?", isPresented: $confirmUnkeep) {
            Button("Retirer", role: .destructive) { Library.setKept(false, article) }
        } message: {
            Text("Sa note et ses tags seront perdus.")
        }
        .task(id: article.persistentModelID) { article.isRead = true }
    }

    private var url: URL? {
        URL(string: article.link).flatMap { ["http", "https"].contains($0.scheme?.lowercased()) ? $0 : nil }
    }
}

struct KeptEditor: View {
    @Bindable var article: Article
    @Environment(\.modelContext) private var context
    @Query(sort: \CairnCore.Tag.name) private var allTags: [CairnCore.Tag]
    @State private var newTag = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Note").font(.headline)
            TextEditor(text: $article.note)
                .font(.body)
                .frame(minHeight: 60, maxHeight: 120)
                .scrollContentBackground(.hidden)
                .padding(4)
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel("Note personnelle")

            Text("Tags").font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(article.tags ?? []) { tag in
                        Button { Library.removeTag(tag, from: article) } label: {
                            Label(tag.name, systemImage: "xmark")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Retirer le tag « \(tag.name) »")
                    }
                    TextField("Ajouter un tag", text: $newTag)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)
                        .onSubmit { add(newTag) }
                }
            }
            if !suggestions.isEmpty {
                HStack {
                    Text("Suggestions :").foregroundStyle(.secondary)
                    ForEach(suggestions) { tag in
                        Button(tag.name) { add(tag.name) }.controlSize(.small)
                    }
                }
                .font(.caption)
            }
        }
    }

    private var suggestions: [CairnCore.Tag] {
        let key = Library.tagKey(newTag)
        guard !key.isEmpty else { return [] }
        let current = Set((article.tags ?? []).map(\.key))
        return Array(allTags.filter { $0.key.hasPrefix(key) && !current.contains($0.key) }.prefix(5))
    }

    private func add(_ name: String) {
        // A failed tag lookup leaves the tag unadded, which the user sees immediately.
        try? Library.addTag(named: name, to: article, context: context)
        newTag = ""
    }
}
