import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct BoxComposerScreen: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var draft: BoxDraft
    @State private var step = 0
    @State private var showsPicker = false
    @State private var editedReview: BoxContent?
    @State private var confirmsDiscard = false
    @State private var error: BoxFailure?
    private let initial: BoxDraft
    private let onSave: () -> Void

    init(draft: BoxDraft, onSave: @escaping () -> Void = {}) {
        initial = draft
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Box setup", selection: $step) {
                    Text("Cover").tag(0)
                    Text("Contents").tag(1)
                    Text("Review Box").tag(2)
                }.pickerStyle(.segmented).padding()
                Group {
                    switch step {
                    case 0: coverForm
                    case 1: contentsList
                    default: review
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(BoxAppearance.background)
            .navigationTitle(initial.title.isEmpty ? String(localized: "Create a Box") : String(localized: "Edit Box"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if draft != initial { confirmsDiscard = true } else { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if step < 2 {
                        Button("Next") { step += 1 }
                            .disabled(step == 0 ? draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : draft.contents.isEmpty)
                    } else {
                        Button("Save Box", action: save).fontWeight(.semibold)
                    }
                }
            }
            .sheet(isPresented: $showsPicker) {
                BoxContentPicker(authorID: draft.authorID, authorName: draft.authorName) { content in
                    draft.contents.append(content)
                }
            }
            .sheet(item: $editedReview) { content in
                BoxReviewEditor(content: content) { changed in
                    if let index = draft.contents.firstIndex(where: { $0.id == changed.id }) { draft.contents[index] = changed }
                }
            }
            .confirmationDialog("Discard Changes?", isPresented: $confirmsDiscard, titleVisibility: .visible) {
                Button("Discard Changes", role: .destructive) { dismiss() }
            }
            .boxError($error)
        }
        .preferredColorScheme(.dark).tint(DSColor.accent)
        .interactiveDismissDisabled(draft != initial)
    }

    private var coverForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(spacing: 16) {
                    BoxCoverView(box: draft).frame(width: 180, height: 250)
                        .shadow(color: .black.opacity(0.6), radius: 18, x: 8, y: 10)
                    Text("Your contents form the cover. The first item stays in front; reorder them in Contents to change it.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity).padding(.vertical, 12)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Box Title").font(.headline)
                    TextField("Give your box a name", text: $draft.title, axis: .vertical)
                        .accessibilityIdentifier("boxes.title")
                        .lineLimit(1...3).textFieldStyle(.roundedBorder)
                    TextField("What connects these stories?", text: $draft.description, axis: .vertical)
                        .lineLimit(3...6).textFieldStyle(.roundedBorder)
                }
            }.padding(24)
        }
    }

    private var contentsList: some View {
        List {
            Section {
                ForEach(Array(draft.contents.enumerated()), id: \.element.id) { index, content in
                    Button {
                        if content.kind == .review && content.authorID == draft.authorID { editedReview = content }
                    } label: { BoxContentRow(content: content, number: index + 1) }
                    .buttonStyle(.plain)
                    .disabled(content.kind != .review || content.authorID != draft.authorID)
                    .listRowBackground(Color.clear).listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 5, leading: 16, bottom: 5, trailing: 16))
                }
                .onMove { draft.contents.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { draft.contents.remove(atOffsets: $0) }
            } header: {
                Text("Set the order of your experience")
            } footer: {
                Text("Drag to reorder. Remove anything that does not belong. Inherited impressions keep their original author.")
            }
            Section {
                Button("Add Content", systemImage: "plus") { showsPicker = true }
                    .accessibilityIdentifier("boxes.addContent")
                    .disabled(draft.contents.count >= 200)
            }
        }
        .listStyle(.plain).scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
    }

    private var review: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                BoxCoverView(box: draft).frame(width: 170, height: 240).frame(maxWidth: .infinity)
                Text(draft.title).font(.system(.title, design: .serif, weight: .bold))
                if !draft.description.isEmpty { Text(draft.description).foregroundStyle(.secondary) }
                if let name = draft.inspiredByName { Text("Inspired by \(name)").font(.caption).foregroundStyle(DSColor.accent) }
                ForEach(Array(draft.contents.enumerated()), id: \.element.id) { index, content in
                    BoxContentRow(content: content, number: index + 1)
                }
                Label("Only you decide when and with whom to share.", systemImage: "lock")
                    .font(.footnote).foregroundStyle(.secondary)
            }.padding(24)
        }
    }

    private func save() {
        do {
            try BoxStore(context: context).save(draft)
            onSave()
            dismiss()
        } catch { self.error = BoxFailure(error) }
    }
}

private struct BoxReviewEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var content: BoxContent
    let onSave: (BoxContent) -> Void
    var body: some View {
        NavigationStack {
            Form {
                TextField("Title", text: $content.title)
                TextField("Your impression", text: Binding(get: { content.text ?? "" }, set: { content.text = $0 }), axis: .vertical).lineLimit(5...15)
                    .accessibilityIdentifier("boxes.reviewText")
                Toggle("Include a Rating", isOn: Binding(get: { content.rating != nil }, set: { content.rating = $0 ? 5 : nil }))
                if content.rating != nil {
                    Slider(value: Binding(get: { content.rating ?? 5 }, set: { content.rating = $0 }), in: 0.5...5, step: 0.5) { Text("Rating") }
                        .accessibilityValue(Text("\((content.rating ?? 5).formatted()) out of 5 stars"))
                    Text("\((content.rating ?? 5).formatted()) out of 5 stars")
                }
            }
            .navigationTitle("Edit Impression")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { onSave(content); dismiss() }
                        .disabled(content.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (content.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#if DEBUG
#Preview("Boxes · Montagem real") {
    BoxComposerScreen(draft: BoxCanvasData.draft)
        .modelContainer(BoxCanvasData.container())
}

#endif
