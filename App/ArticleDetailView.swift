import CairnCore
import SwiftData
import SwiftUI

struct ArticleDetailView: View {
    @Bindable var article: Article
    /// False when the article was selected automatically: it is shown without being marked read.
    let marksRead: Bool
    @Environment(\.openURL) private var openURL
    @State private var articleToUnkeep: Article?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                Text(article.title.isEmpty ? "Sans titre" : article.title)
                    .font(.title2.bold())
                    .textSelection(.enabled)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    SourceIcon(data: article.feed?.iconData ?? article.sourceIconData)
                    Text("\(article.sourceTitle) · \(article.publishedAt.formatted(date: .abbreviated, time: .shortened))")
                }
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
                KeepButton(article: article, articleToUnkeep: $articleToUnkeep)
                    .help(article.isKept ? "Retirer cet article du cairn" : "Garder cet article dans le cairn")
                Button("Marquer comme non lu", systemImage: "circle") { article.isRead = false }
                    .help("Marquer comme non lu")
                Button("Ouvrir dans le navigateur", systemImage: "safari") { if let url { openURL(url) } }
                    .disabled(url == nil)
                    .help("Ouvrir dans le navigateur")
            }
        }
        .unkeepConfirmation($articleToUnkeep)
        .task(id: article.persistentModelID) { if marksRead { article.isRead = true } }
    }

    private var url: URL? {
        URL(string: article.link).flatMap { ["http", "https"].contains($0.scheme?.lowercased()) ? $0 : nil }
    }
}

/// Keep / unkeep toggle shared by the reader toolbar and the article context menu. Unkeeping an article
/// with a note or tags goes through `unkeepConfirmation`, since they are lost.
struct KeepButton: View {
    let article: Article
    @Binding var articleToUnkeep: Article?

    var body: some View {
        Button(article.isKept ? "Retirer du cairn" : "Garder dans le cairn",
               image: ImageResource(name: article.isKept ? "cairn.fill" : "cairn", bundle: .main)) {
            if !article.isKept {
                Library.setKept(true, article)
            } else if article.note.isEmpty && (article.tags ?? []).isEmpty {
                Library.setKept(false, article)
            } else {
                articleToUnkeep = article
            }
        }
    }
}

extension View {
    func unkeepConfirmation(_ article: Binding<Article?>) -> some View {
        confirmationDialog("Retirer cet article du cairn ?",
                           isPresented: Binding(get: { article.wrappedValue != nil }, set: { if !$0 { article.wrappedValue = nil } }),
                           presenting: article.wrappedValue) { article in
            Button("Retirer", role: .destructive) { Library.setKept(false, article) }
        } message: { _ in
            Text("Sa note et ses tags seront perdus.")
        }
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
