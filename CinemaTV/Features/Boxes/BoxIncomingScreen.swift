import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct BoxIncomingScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    let editionID: UUID
    @State private var edition: BoxEdition?
    @State private var loadingError: String?
    @State private var error: BoxFailure?
    @State private var attempt = 0
    @State private var adaptation: BoxDraft?

    var body: some View {
        Group {
            if let edition {
                BoxExperienceView(box: edition.box) {
                    VStack(alignment: .leading, spacing: 14) {
                        Label("An edition shared with you", systemImage: "gift").font(.subheadline).foregroundStyle(DSColor.accent)
                        Text("Keep it as it arrived, or make it the beginning of your own box.").font(.subheadline).foregroundStyle(.secondary)
                        Button("Keep Original", systemImage: "shippingbox") {
                            do {
                                let saved = try BoxStore(context: context).importOriginal(edition)
                                if let id = saved.id { router.push(.box(id: id)) }
                            } catch { self.error = BoxFailure(error) }
                        }.buttonStyle(.borderedProminent)
                        Button("Create My Version", systemImage: "square.on.square") {
                            do {
                                let profile = try BoxStore(context: context).profile()
                                adaptation = BoxStore.inspiredDraft(from: edition, authorID: profile.id ?? "", authorName: profile.displayName ?? "")
                            } catch { self.error = BoxFailure(error) }
                        }.buttonStyle(.bordered)
                    }
                }
            } else if let loadingError {
                ContentUnavailableView {
                    Label("Box Unavailable", systemImage: "shippingbox")
                } description: { Text(loadingError) } actions: { Button("Try Again") { attempt += 1 } }
            } else { ProgressView("Opening your box…").frame(maxWidth: .infinity, maxHeight: .infinity) }
        }
        .background(BoxAppearance.background).preferredColorScheme(.dark)
        .navigationTitle("Shared Box").navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
        .task(id: attempt) {
            loadingError = nil
            do { edition = try await BoxSharingConfiguration.service.fetch(editionID: editionID) }
            catch is CancellationError { } catch { loadingError = error.localizedDescription }
        }
        .sheet(item: $adaptation) { draft in
            BoxComposerScreen(draft: draft) { router.push(.box(id: draft.id)) }
        }
        .boxError($error)
    }
}
