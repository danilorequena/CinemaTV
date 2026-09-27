import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct BoxesLibraryScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var typeSize
    @Query(sort: \PersonalBox.updatedAt, order: .reverse) private var records: [PersonalBox]
    @State private var draft: BoxDraft?
    @State private var error: BoxFailure?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("YOUR PERSONAL COLLECTION").font(.caption.weight(.semibold)).tracking(2).foregroundStyle(DSColor.accent)
                    Text("Stories worth keeping.").font(.system(.largeTitle, design: .serif, weight: .bold))
                    Text("Films, music and everything that stayed with you. Curated your way.")
                        .foregroundStyle(.secondary)
                }
                if records.isEmpty {
                    ContentUnavailableView {
                        Label("Your first box starts here", systemImage: "shippingbox")
                    } description: {
                        Text("Give it a cover, collect your favorites and choose who to share it with.")
                    } actions: {
                        Button("Create a Box", systemImage: "plus", action: create).buttonStyle(.borderedProminent)
                    }
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 260 : 145), spacing: 24)], alignment: .leading, spacing: 30) {
                        ForEach(records) { record in
                            if let box = try? BoxStore(context: context).draft(for: record), let id = record.id {
                                NavigationLink(value: Route.box(id: id)) {
                                    VStack(alignment: .leading, spacing: 10) {
                                        BoxCoverView(box: box).aspectRatio(0.70, contentMode: .fit)
                                            .shadow(color: .black.opacity(0.5), radius: 12, x: 5, y: 12)
                                        Text(box.title).font(.headline).foregroundStyle(.primary).lineLimit(2)
                                        HStack {
                                            Text("\(box.contents.count) items")
                                            if record.isOriginal == true { Text("Original") }
                                        }
                                        .font(.caption).foregroundStyle(.secondary)
                                    }
                                }.buttonStyle(.plain)
                            } else {
                                ContentUnavailableView("Box Unavailable", systemImage: "exclamationmark.triangle", description: Text("This box could not be read."))
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .background(BoxAppearance.background).preferredColorScheme(.dark)
        .navigationTitle("My Boxes").navigationBarTitleDisplayMode(.inline)
        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Create a Box", systemImage: "plus", action: create) } }
        .sheet(item: $draft) { BoxComposerScreen(draft: $0) }
        .boxError($error)
    }

    private func create() {
        do {
            let profile = try BoxStore(context: context).profile()
            draft = BoxDraft(authorID: profile.id ?? "", authorName: profile.displayName ?? "")
        } catch { self.error = BoxFailure(error) }
    }
}

/// Entry remains visible even before anything has been added to tracking.
struct BoxesLibraryEntry: View {
    var body: some View {
        NavigationLink(value: Route.boxes) {
            HStack(spacing: 14) {
                Image(systemName: "shippingbox.fill").font(.title2).foregroundStyle(DSColor.accent)
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Boxes").font(.headline)
                    Text("Your own editions of the stories you love").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }.padding(18).background(.quaternary.opacity(0.5), in: .rect(cornerRadius: 18))
        }.buttonStyle(.plain).accessibilityIdentifier("boxes.libraryEntry")
    }
}


#if DEBUG
#Preview("Boxes · Biblioteca integrada") {
    BoxCanvasNavigation {
        BoxesLibraryScreen()
    }
}

#endif
