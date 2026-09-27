#if DEBUG && os(iOS)
import SwiftUI

struct CollectorBoxComposerPreview: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: CollectorEdition
    @State private var step: Int
    @State private var showsCover = false
    @State private var showsContent = false
    @State private var showsResult = false
    private let onSave: ((CollectorEdition) -> Void)?

    init(draft: CollectorEdition = .personalSample, initialStep: Int = 0, onSave: ((CollectorEdition) -> Void)? = nil) {
        _draft = State(initialValue: draft)
        _step = State(initialValue: initialStep)
        self.onSave = onSave
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                steps
                Group {
                    switch step {
                    case 0: identity
                    case 1: contents
                    default: review
                    }
                }.frame(maxWidth: 640).frame(maxWidth: .infinity)
            }
            .background(BoxesDirection.collector.background)
            .navigationTitle(draft.inspiredBy == nil ? "Montar box" : "Minha versão")
            .toolbarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                if step == 1 {
                    ToolbarItem(placement: .topBarTrailing) { Button("Adicionar conteúdo", systemImage: "plus") { showsContent = true } }
                }
            }
            .safeAreaInset(edge: .bottom) { actions }
            .sheet(isPresented: $showsCover) { CollectorCoverPicker(title: draft.title, selection: $draft.cover) }
            .sheet(isPresented: $showsContent) {
                CollectorContentPicker(author: draft.author) { draft.entries.append($0) }
            }
            .sheet(isPresented: $showsResult) {
                NavigationStack {
                    CollectorBoxDetailPreview(received: false, edition: draft) { draft = $0 }
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { showsResult = false } } }
                }
            }
        }.preferredColorScheme(.dark).tint(DSColor.accent)
    }

    private var steps: some View {
        HStack(spacing: 8) {
            ForEach(Array(["Capa", "Conteúdos", "Revisar"].enumerated()), id: \.offset) { index, name in
                Button { step = index } label: {
                    HStack(spacing: 7) {
                        Text("\(index + 1)").font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .frame(width: 22, height: 22)
                            .background(step == index ? DSColor.accent : .white.opacity(0.08), in: .circle)
                            .foregroundStyle(step == index ? .black : .secondary)
                        Text(name).font(.caption.weight(step == index ? .semibold : .regular))
                            .foregroundStyle(step == index ? .white : .secondary)
                    }.frame(maxWidth: .infinity).padding(.vertical, 14)
                        .overlay(alignment: .bottom) { Rectangle().fill(step == index ? DSColor.accent : .clear).frame(height: 2) }
                }.buttonStyle(.plain).accessibilityAddTraits(step == index ? .isSelected : [])
            }
        }.padding(.horizontal, 20)
    }

    private var identity: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 23) {
                VStack(spacing: 16) {
                    BoxesCover(title: draft.coverTitle, subtitle: draft.coverSignature, kind: draft.cover)
                        .frame(width: 166, height: 220)
                        .rotation3DEffect(.degrees(-10), axis: (x: 0, y: 1, z: 0))
                        .shadow(color: .black.opacity(0.5), radius: 18, x: 8, y: 12)
                    Button("Escolher capa", systemImage: "photo.on.rectangle") { showsCover = true }
                        .font(.subheadline.weight(.medium))
                }.frame(maxWidth: .infinity).padding(.vertical, 14)
                VStack(alignment: .leading, spacing: 9) {
                    eyebrow("COMO SE CHAMA A SUA EDIÇÃO?")
                    TextField("Nome do box", text: $draft.title)
                        .font(.system(.title2, design: .serif)).padding(16)
                        .background(.white.opacity(0.055), in: .rect(cornerRadius: 12))
                }
                VStack(alignment: .leading, spacing: 9) {
                    eyebrow("O QUE UNE ESSAS HISTÓRIAS?")
                    TextField("Uma ideia, uma lembrança, um clima…", text: $draft.description, axis: .vertical)
                        .font(.subheadline).lineLimit(3...5).padding(16)
                        .background(.white.opacity(0.055), in: .rect(cornerRadius: 12))
                }
                provenance
            }.padding(24)
        }
    }

    private var contents: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("A experiência, na sua ordem.").font(.system(.title2, design: .serif))
                    Text("Arraste os itens para contar a sua história.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    provenance
                }.padding(.vertical, 8)
            }.listRowBackground(Color.clear).listRowSeparator(.hidden)
            Section {
                ForEach(draft.entries) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.kind.symbol).font(.body)
                            .foregroundStyle(DSColor.accent).frame(width: 28)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title).font(.subheadline.weight(.medium))
                            Text(item.note.map { _ in "Impressão de \(item.author ?? draft.author)" } ?? "\(item.kind.rawValue) · \(item.subtitle)")
                                .font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 7)
                    }
                }
                .onMove { draft.entries.move(fromOffsets: $0, toOffset: $1) }
                .onDelete { draft.entries.remove(atOffsets: $0) }
                if draft.entries.isEmpty {
                    ContentUnavailableView("O começo da sua coleção", systemImage: "shippingbox", description: Text("Adicione uma obra ou uma impressão para começar."))
                }
            }.listRowBackground(Color.white.opacity(0.05))
            Section {
                Button("Adicionar conteúdo", systemImage: "plus.circle.fill") { showsContent = true }
                    .font(.subheadline.weight(.semibold)).padding(.vertical, 8)
            }.listRowBackground(Color.clear)
        }
        .environment(\.editMode, .constant(.active))
        .scrollContentBackground(.hidden)
    }

    private var review: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text("Sua edição está tomando forma.").font(.system(.title2, design: .serif))
                HStack(spacing: 20) {
                    BoxesCover(title: draft.coverTitle, subtitle: "MINHA EDIÇÃO", kind: draft.cover)
                        .frame(width: 103, height: 140)
                    VStack(alignment: .leading, spacing: 9) {
                        Text(draft.title.isEmpty ? "Seu box" : draft.title).font(.system(.title2, design: .serif))
                        Text(draft.summary).font(.caption).foregroundStyle(.secondary)
                        provenance
                    }
                    Spacer(minLength: 0)
                }
                if !draft.description.isEmpty { Text(draft.description).font(.subheadline).foregroundStyle(.secondary) }
                ForEach(Array(draft.entries.enumerated()), id: \.element.id) { index, item in
                    CollectorContentCard(item: item, position: index + 1)
                }
                Text("Você decide quando e com quem compartilhar.").font(.caption).foregroundStyle(.secondary)
                if !draft.isReady {
                    Text("Dê um nome ao box e escolha pelo menos um conteúdo.").font(.caption).foregroundStyle(DSColor.accent)
                }
            }.padding(24)
        }
    }

    @ViewBuilder private var provenance: some View {
        if let author = draft.inspiredBy {
            Label("Inspirado no box de \(author)", systemImage: "arrow.triangle.branch")
                .font(.caption).foregroundStyle(DSColor.accent)
        }
    }

    private var actions: some View {
        HStack(spacing: 15) {
            if step > 0 { Button("Voltar") { step -= 1 }.font(.subheadline).padding(.horizontal, 10) }
            Button {
                if step < 2 { step += 1 }
                else if let onSave { onSave(draft); dismiss() }
                else { showsResult = true }
            } label: {
                Text(step == 2 ? "Guardar box" : step == 1 ? "Revisar edição" : "Escolher conteúdos")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(15)
                    .foregroundStyle(.black).background(DSColor.accent, in: .capsule)
            }
            .disabled(step == 0 ? draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty : !draft.isReady)
        }.padding(.horizontal, 24).padding(.vertical, 12).frame(maxWidth: 640).frame(maxWidth: .infinity)
            .background(BoxesDirection.collector.background)
    }

    private func eyebrow(_ text: String) -> some View {
        Text(text).font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.4).foregroundStyle(.secondary)
    }
}

struct CollectorContentPicker: View {
    let author: String
    let onAdd: (CollectorItem) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var category = "Todos"
    @State private var writing = false
    @State private var note = ""
    @State private var subject = ""

    private var results: [CollectorItem] {
        CollectorEdition.catalog.filter {
            $0.kind != .note && (category == "Todos" || (category == "Obras" ? ![.trailer, .music].contains($0.kind) : [.trailer, .music].contains($0.kind))) &&
            (query.isEmpty || "\($0.title) \($0.subtitle)".localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button("Escrever minha impressão", systemImage: "square.and.pencil") { writing = true }
                }
                Section {
                    Picker("Tipo de conteúdo", selection: $category) {
                        ForEach(["Todos", "Obras", "Extras"], id: \.self) { Text($0) }
                    }.pickerStyle(.segmented).listRowBackground(Color.clear)
                    ForEach(results) { item in
                        Button { onAdd(item.copied()); dismiss() } label: {
                            HStack(spacing: 12) {
                                Image(systemName: item.kind.symbol).frame(width: 26).foregroundStyle(DSColor.accent)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                                    Text("\(item.kind.rawValue) · \(item.subtitle)").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 0)
                                Image(systemName: "plus.circle").foregroundStyle(DSColor.accent)
                            }.padding(.vertical, 6)
                        }
                    }
                    if results.isEmpty { ContentUnavailableView.search(text: query) }
                } header: { Text("Catálogo de exemplo") }
            }
            .searchable(text: $query, prompt: "Filmes, séries, músicas…")
            .navigationTitle("Adicionar ao box").toolbarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { dismiss() } } }
            .sheet(isPresented: $writing) { noteEditor }
        }.preferredColorScheme(.dark).tint(DSColor.accent)
    }

    private var noteEditor: some View {
        NavigationStack {
            Form {
                Section("Sobre qual conteúdo?") { TextField("Ex.: Interestelar", text: $subject) }
                Section("O que ficou com você?") {
                    TextField("Uma cena, uma sensação, uma lembrança…", text: $note, axis: .vertical).lineLimit(6...12)
                }
                Section { Text("Assinado por \(author)").font(.caption).foregroundStyle(.secondary) }
            }
            .navigationTitle("Minha impressão").toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { writing = false } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Adicionar") {
                        onAdd(.init(kind: .note, title: "Minha impressão", subtitle: subject.isEmpty ? "Sobre este box" : "Sobre \(subject)", artwork: .space, note: note, author: author))
                        writing = false
                        dismiss()
                    }.disabled(note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview("Colecionador · Montar edição") { CollectorBoxComposerPreview() }
#Preview("Colecionador · Ordenar conteúdos") { CollectorBoxComposerPreview(initialStep: 1) }
#Preview("Colecionador · Revisar minha versão") { CollectorBoxComposerPreview(draft: CollectorEdition.sample.personalized(), initialStep: 2) }
#endif
