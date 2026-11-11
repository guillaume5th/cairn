import CairnCore
import SwiftData
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarItem?
    @Environment(\.modelContext) private var context
    @Environment(AppState.self) private var state
    @Query(sort: \Feed.title) private var feeds: [Feed]
    @Query(sort: \CairnCore.Tag.name) private var tags: [CairnCore.Tag]
    // Every unread article, kept ones without a feed included, like the "Tous les articles" list.
    @Query(filter: #Predicate<Article> { !$0.isRead }) private var unreadArticles: [Article]
    @State private var feedToDelete: Feed?

    var body: some View {
        List(selection: $selection) {
            Label("Tous les articles", systemImage: "tray.full")
                .badge(unreadArticles.count)
                .tag(SidebarItem.all)
            Label("Cairn", image: "cairn").tag(SidebarItem.cairn)
            // Only tags still carried by a kept article.
            ForEach(tags.filter { $0.articles?.contains(where: \.isKept) ?? false }) { tag in
                Label(tag.name, systemImage: "tag")
                    .padding(.leading, 12)
                    .tag(SidebarItem.tag(tag.key))
            }

            Section {
                ForEach(feeds) { feed in
                    Label {
                        HStack {
                            Text(feed.title).lineLimit(1)
                            if let error = feed.lastError {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                                    .help(error)
                                    .accessibilityLabel("Erreur : \(error)")
                            }
                        }
                    } icon: {
                        SourceIcon(data: feed.iconData)
                    }
                    .badge(feed.unreadCount)
                    .tag(SidebarItem.feed(feed.persistentModelID))
                    .contextMenu {
                        Button("Supprimer l'abonnement…", role: .destructive) { feedToDelete = feed }
                    }
                }
            } header: {
                HStack {
                    Text("Abonnements")
                    Spacer()
                    Button("Ajouter un abonnement", systemImage: "plus") { state.isAddingFeed = true }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.borderless)
                        .help("Ajouter un abonnement (⌘N)")
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
