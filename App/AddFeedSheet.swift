import CairnCore
import SwiftUI

struct AddFeedSheet: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss
    @State private var url = ""
    @State private var error: String?
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ajouter un flux").font(.headline)
            TextField("URL du flux", text: $url, prompt: Text("https://exemple.com/feed.xml"))
                .textFieldStyle(.roundedBorder)
                .onSubmit { Task { await add() } }
                .disabled(isLoading)
            if let error {
                Text(error).foregroundStyle(.red).font(.callout)
            }
            HStack {
                if isLoading { ProgressView().controlSize(.small) }
                Spacer()
                Button("Annuler", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Ajouter") { Task { await add() } }
                    .keyboardShortcut(.defaultAction)
                    .disabled(isLoading || url.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 440)
    }

    private func add() async {
        isLoading = true
        defer { isLoading = false }
        do {
            _ = try await Library.addFeed(urlString: url, context: state.context, fetcher: state.fetcher)
            state.save()
            dismiss()
            // The icon appears without waiting for the next refresh; the sheet does not wait for it.
            Task { await state.refreshIcons() }
        } catch {
            self.error = error.localizedDescription
        }
    }
}
