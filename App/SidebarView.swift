import CairnCore
import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.modelContext) private var context
    @Query(sort: \Feed.title) private var feeds: [Feed]
    @Query(sort: \CairnCore.Tag.name) private var tags: [CairnCore.Tag]
    @State private var feedToDelete: Feed?

    var body: some View {
        List(selection: $selection) {
            Label("Tous les articles", systemImage: "tray.full").tag(SidebarItem.all)
            Label("Cairn", image: "cairn").tag(SidebarItem.cairn)
            // Only tags still carried by a kept article.
            ForEach(tags.filter { $0.articles?.contains(where: \.isKept) ?? false }) { tag in
                Label(tag.name, systemImage: "tag")
                    .padding(.leading, 12)
                    .tag(SidebarItem.tag(tag.key))
            }

            Section("Abonnements") {
                ForEach(feeds) { feed in
                    HStack {
                        Text(feed.title).lineLimit(1)
                        if let error = feed.lastError {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .help(error)
                                .accessibilityLabel("Erreur : \(error)")
                        }
                    }
                    .badge(feed.unreadCount)
                    .tag(SidebarItem.feed(feed.persistentModelID))
                    .contextMenu {
                        Button("Supprimer l'abonnement…", role: .destructive) { feedToDelete = feed }
                    }
                }
            }
        }
        .confirmationDialog("Supprimer « \(feedToDelete?.title ?? "") » ?",
                            isPresented: Binding(get: { feedToDelete != nil }, set: { if !$0 { feedToDelete = nil } }),
                            presenting: feedToDelete) { feed in
            Button("Supprimer", role: .destructive) {
                if selection == .feed(feed.persistentModelID) { selection = .all }
                Library.delete(feed, context: context)
            }
        } message: { _ in
            Text("Ses articles non gardés seront supprimés. Les articles gardés restent dans le cairn.")
        }
    }
}
