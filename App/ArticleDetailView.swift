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
            TagFlowLayout {
                // The relationship is unordered: sort so tags keep their place between redraws.
                ForEach((article.tags ?? []).sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }) { tag in
                    HStack(spacing: 4) {
                        Text(tag.name)
                        Button { Library.removeTag(tag, from: article) } label: {
                            Image(systemName: "xmark").font(.caption2.weight(.semibold))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                        .help("Retirer le tag « \(tag.name) »")
                        .accessibilityLabel("Retirer le tag « \(tag.name) »")
                    }
                    .tagCapsule()
                }
                TextField("Ajouter un tag", text: $newTag)
                    .textFieldStyle(.plain)
                    .frame(minWidth: 120)
                    .onSubmit { add(newTag) }
            }
            .padding(6)
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 6))
            if !suggestions.isEmpty {
                HStack {
                    Text("Suggestions :").foregroundStyle(.secondary)
                    ForEach(suggestions) { tag in
                        Button(tag.name) { add(tag.name) }
                            .buttonStyle(.plain)
                            .tagCapsule()
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

private extension View {
    func tagCapsule() -> some View {
        padding(.horizontal, 8).padding(.vertical, 3).background(.tint.opacity(0.2), in: Capsule())
    }
}

/// Lays subviews out left to right, wrapping to a new line when the width runs out, each line centered
/// vertically. The last subview (the tag field) stretches over what its line has left.
struct TagFlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let frames = frames(for: subviews, width: proposal.width ?? .infinity)
        return CGSize(width: proposal.width ?? frames.map(\.maxX).max() ?? 0, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for (subview, frame) in zip(subviews, frames(for: subviews, width: bounds.width)) {
            subview.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(for subviews: Subviews, width: CGFloat) -> [CGRect] {
        var lines: [[CGRect]] = [[]]
        var x: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            var size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { lines.append([]); x = 0 }
            if index == subviews.count - 1 && width.isFinite { size.width = max(size.width, width - x) }
            lines[lines.count - 1].append(CGRect(origin: CGPoint(x: x, y: 0), size: size))
            x += size.width + spacing
        }
        var y: CGFloat = 0
        return lines.flatMap { line in
            let height = line.map(\.height).max() ?? 0
            defer { y += height + spacing }
            return line.map { $0.offsetBy(dx: 0, dy: y + (height - $0.height) / 2) }
        }
    }
}
