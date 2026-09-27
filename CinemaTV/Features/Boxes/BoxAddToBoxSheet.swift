import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct BoxAddToBoxButton: View {
    let content: BoxContent
    @State private var showsSheet = false
    var body: some View {
        Button("Add to Box", systemImage: "shippingbox") { showsSheet = true }
            .sheet(isPresented: $showsSheet) { BoxAddToBoxSheet(content: content) }
    }
}

struct BoxAddToBoxSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \PersonalBox.updatedAt, order: .reverse) private var records: [PersonalBox]
    let content: BoxContent
    @State private var newDraft: BoxDraft?
    @State private var error: BoxFailure?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    BoxContentRow(content: content).listRowBackground(Color.clear).listRowInsets(EdgeInsets())
                }
                Section {
                    Button("Create a Box", systemImage: "plus") { create() }
                    ForEach(records.filter { $0.isOriginal != true }) { record in
                        if let box = try? BoxStore(context: context).draft(for: record) {
                            Button {
                                do {
                                    var changed = box
                                    var addition = content
                                    addition.id = UUID()
                                    changed.contents.append(addition)
                                    try BoxStore(context: context).save(changed)
                                    dismiss()
                                } catch { self.error = BoxFailure(error) }
                            } label: {
                                HStack(spacing: 16) {
                                    BoxCoverView(box: box).frame(width: 44, height: 60)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(box.title).foregroundStyle(.primary)
                                        Text("\(box.contents.count) items").font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } header: { Text("Choose a Box") }
            }
            .navigationTitle("Add to Box").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
            .sheet(item: $newDraft) { draft in BoxComposerScreen(draft: draft) { dismiss() } }
            .boxError($error)
        }.preferredColorScheme(.dark).tint(DSColor.accent)
    }

    private func create() {
        do {
            let profile = try BoxStore(context: context).profile()
            newDraft = BoxDraft(authorID: profile.id ?? "", authorName: profile.displayName ?? "", contents: [content])
        } catch { self.error = BoxFailure(error) }
    }
}
