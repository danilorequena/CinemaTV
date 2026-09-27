#if DEBUG && os(iOS)
import SwiftUI

struct BoxesDetailPreview: View {
    let direction: BoxesDirection
    let received: Bool
    @State private var showsComposer = false
    @State private var showsShare = false
    @State private var saved = false

    var body: some View {
        if direction == .collector {
            CollectorBoxDetailPreview(received: received)
        } else { legacyBody }
    }

    private var legacyBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                cover
                VStack(alignment: .leading, spacing: 10) {
                    Text(received ? "UM BOX CHEGOU ATÉ VOCÊ" : "SUA EDIÇÃO PESSOAL")
                        .font(.system(size: 9, weight: .bold, design: .monospaced)).tracking(2)
                        .foregroundStyle(direction.ink.opacity(0.55))
                    Text("Além do tempo").font(.system(size: 36, weight: .semibold, design: .serif)).tracking(-1)
                    HStack(spacing: 8) {
                        Text("M").font(.caption.weight(.bold)).frame(width: 26, height: 26)
                            .background(direction.ink.opacity(0.1), in: .circle)
                        Text("Uma edição de Marina").font(.subheadline)
                    }
                    Text("Histórias que dobram o tempo e ficam com a gente. Minha ordem para assistir, ouvir e sentir de novo.")
                        .font(.subheadline).foregroundStyle(direction.ink.opacity(0.65)).lineSpacing(4)
                }
                HStack(spacing: 14) {
                    Label("2 filmes", systemImage: "film")
                    Label("1 episódio", systemImage: "tv")
                    Label("3 extras", systemImage: "sparkles")
                }.font(.system(size: 11)).foregroundStyle(direction.ink.opacity(0.65))
                Divider()
                VStack(alignment: .leading, spacing: 18) {
                    Text("Dentro deste box").font(.title3.weight(.semibold))
                    ForEach(BoxesPreviewEntry.samples) { entry in
                        BoxesEntryRow(entry: entry)
                    }
                    review
                }
                if received {
                    Label("Esta edição permanece como Marina compartilhou.", systemImage: "shippingbox")
                        .font(.caption).foregroundStyle(direction.ink.opacity(0.6))
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 24)
            .frame(maxWidth: 620).frame(maxWidth: .infinity)
        }
        .background(direction.background).foregroundStyle(direction.ink)
        .navigationTitle(received ? "Box recebido" : "Meu box")
        .toolbarTitleDisplayMode(.inline)
        .toolbarColorScheme(direction.scheme, for: .navigationBar)
        .toolbar {
            if !received {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Editar", systemImage: "pencil") { showsComposer = true }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Compartilhar", systemImage: "square.and.arrow.up") { showsShare = true }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if received { receiveActions }
        }
        .sheet(isPresented: $showsComposer) {
            BoxesComposerPreview(direction: direction, inspired: received)
        }
        .sheet(isPresented: $showsShare) { BoxesSharePreview(direction: direction) }
        .preferredColorScheme(direction.scheme).tint(direction.accent)
    }

    private var cover: some View {
        Group {
            if direction == .collector {
                BoxesCover().frame(width: 174, height: 226)
                    .rotation3DEffect(.degrees(-9), axis: (x: 0, y: 1, z: 0))
                    .shadow(color: .black.opacity(0.5), radius: 18, y: 14)
                    .frame(maxWidth: .infinity).padding(.vertical, 18)
            } else {
                HStack(spacing: direction == .editorial ? 3 : 9) {
                    BoxesArtwork(kind: .space)
                    BoxesArtwork(kind: .arrival)
                    BoxesArtwork(kind: .dark)
                }
                .frame(height: 205)
                .clipShape(.rect(cornerRadius: direction == .editorial ? 2 : 14))
                .rotationEffect(.degrees(direction == .mixtape ? -2 : 0))
                .padding(.top, 12)
            }
        }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("MINHAS IMPRESSÕES", systemImage: "quote.opening")
                    .font(.system(size: 9, weight: .bold)).tracking(1.5)
                Spacer()
                Text("★★★★★").font(.caption).foregroundStyle(direction == .editorial ? .brown : direction.accent)
            }
            Text("“Talvez o tempo seja só outro jeito de falar sobre quem a gente ama.”")
                .font(.system(.title3, design: .serif).italic()).lineSpacing(4)
            Text("Marina · sobre Interestelar").font(.caption).foregroundStyle(.secondary)
        }.padding(18).background(direction.ink.opacity(0.055), in: .rect(cornerRadius: 12))
    }

    private var receiveActions: some View {
        VStack(spacing: 10) {
            Button {
                saved = true
            } label: {
                Label(saved ? "Original guardado" : "Guardar original", systemImage: saved ? "checkmark" : "plus")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(.vertical, 14)
                    .foregroundStyle(.black).background(direction.accent, in: .capsule)
            }.disabled(saved)
            Button("Criar minha versão") { showsComposer = true }
                .font(.subheadline.weight(.medium)).foregroundStyle(direction.ink)
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 9)
        .frame(maxWidth: 620).frame(maxWidth: .infinity)
        .background(direction.background.opacity(0.97))
    }
}

struct BoxesComposerPreview: View {
    let direction: BoxesDirection
    var inspired = false
    @Environment(\.dismiss) private var dismiss
    @State private var title = "Além do tempo"
    @State private var description = "Histórias que dobram o tempo e ficam com a gente."
    @State private var ownNote = "Talvez o tempo seja só outro jeito de falar sobre quem a gente ama."
    @State private var inspiredNote = ""
    @State private var entries = BoxesPreviewEntry.samples
    @State private var coverKind: BoxesArtworkKind = .space
    @State private var showsItems = false
    @State private var showsSaved = false
    @State private var editMode: EditMode = .active

    var body: some View {
        if direction == .collector {
            CollectorBoxComposerPreview(draft: inspired ? CollectorEdition.sample.personalized() : .personalSample)
        } else { legacyBody }
    }

    private var legacyBody: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 20) {
                        BoxesCover(title: title.uppercased(), subtitle: "MINHA EDIÇÃO", kind: coverKind)
                            .frame(width: 104, height: 140)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dê a sua cara ao box.").font(.system(.title3, design: .serif))
                            Button("Trocar capa", systemImage: "photo") {
                                coverKind = coverKind == .space ? .arrival : .space
                            }.font(.subheadline)
                        }
                    }.padding(.vertical, 8)
                    TextField("Nome do box", text: $title).font(.title3.weight(.semibold))
                    TextField("O que une esta coleção?", text: $description, axis: .vertical)
                        .lineLimit(2...4).font(.subheadline)
                }.listRowBackground(direction.ink.opacity(0.05))
                if inspired {
                    Section {
                        Label("Inspirado no box de Marina", systemImage: "arrow.triangle.branch")
                            .font(.subheadline)
                        Text("Os comentários de Marina mantêm a assinatura dela. Acrescente também o seu olhar.")
                            .font(.caption).foregroundStyle(.secondary)
                    }.listRowBackground(direction.ink.opacity(0.05))
                }
                Section {
                    ForEach(entries) { entry in BoxesEntryRow(entry: entry) }
                        .onMove { entries.move(fromOffsets: $0, toOffset: $1) }
                        .onDelete { entries.remove(atOffsets: $0) }
                } header: {
                    Text("A experiência, na sua ordem")
                } footer: {
                    Text("Misture filmes, séries, episódios, músicas e impressões.")
                }.listRowBackground(direction.ink.opacity(0.05))
                if inspired {
                    Section("Impressões da edição original") {
                        Text("“Talvez o tempo seja só outro jeito de falar sobre quem a gente ama.”")
                            .font(.system(.body, design: .serif).italic())
                        Text("Marina · sobre Interestelar").font(.caption).foregroundStyle(.secondary)
                    }.listRowBackground(direction.ink.opacity(0.05))
                }
                Section("Minhas impressões") {
                    TextField("Acrescente o seu olhar", text: inspired ? $inspiredNote : $ownNote, axis: .vertical)
                        .lineLimit(3...6)
                }.listRowBackground(direction.ink.opacity(0.05))
                Section {
                    Button("Adicionar ao box", systemImage: "plus.circle.fill") { showsItems = true }
                }.listRowBackground(direction.ink.opacity(0.05))
            }
            .environment(\.editMode, $editMode)
            .scrollContentBackground(.hidden).background(direction.background)
            .navigationTitle(inspired ? "Minha versão" : "Montar box")
            .toolbarTitleDisplayMode(.inline)
            .toolbarColorScheme(direction.scheme, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancelar") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Concluir") { showsSaved = true }.disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showsItems) { itemPicker }
            .alert("Prévia da sua edição", isPresented: $showsSaved) {
                Button("Continuar explorando", role: .cancel) { }
                Button("Fechar") { dismiss() }
            } message: {
                Text("Este protótipo mostra a montagem do box. As alterações ficam apenas nesta prévia.")
            }
        }.preferredColorScheme(direction.scheme).tint(direction.accent)
    }

    private var itemPicker: some View {
        NavigationStack {
            List {
                ForEach(BoxesPreviewEntry.samples) { entry in
                    Button {
                        entries.append(.init(id: (entries.map(\.id).max() ?? 0) + 1, title: entry.title, detail: entry.detail, symbol: entry.symbol, kind: entry.kind))
                        showsItems = false
                    } label: { BoxesEntryRow(entry: entry) }
                }
            }
            .navigationTitle("Escolha para o box")
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Fechar") { showsItems = false } } }
        }.presentationDetents([.medium, .large])
    }
}

struct BoxesSharePreview: View {
    let direction: BoxesDirection
    @Environment(\.dismiss) private var dismiss
    @State private var story = true

    var body: some View {
        if direction == .collector {
            CollectorSharePreview(edition: .sample)
        } else { legacyBody }
    }

    private var legacyBody: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("Formato", selection: $story) {
                        Text("Story · 9:16").tag(true)
                        Text("Feed · 4:5").tag(false)
                    }.pickerStyle(.segmented)
                    GeometryReader { geometry in
                    VStack(spacing: story ? 18 : 12) {
                        Text("CINEMATV BOXES").font(.system(size: 9, weight: .semibold)).tracking(3)
                        Spacer(minLength: 0)
                        BoxesCover().frame(width: geometry.size.width * (story ? 0.48 : 0.34), height: geometry.size.width * (story ? 0.625 : 0.44))
                            .rotationEffect(.degrees(-5)).shadow(color: .black.opacity(0.4), radius: 10, y: 12)
                        Text("Algumas histórias\nmerecem ficar juntas.")
                            .font(.system(story ? .title2 : .headline, design: .serif)).multilineTextAlignment(.center)
                        Text("Além do tempo · Uma edição de Marina")
                            .font(.system(size: 10)).foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                        Label("Abra este box no CinemaTV", systemImage: "shippingbox")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .padding(22).frame(width: geometry.size.width, height: geometry.size.height)
                    .background(LinearGradient(colors: [Color(red: 0.23, green: 0.29, blue: 0.32), .black], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .foregroundStyle(.white).clipShape(.rect(cornerRadius: 14))
                    }
                    .aspectRatio(story ? 9.0 / 16.0 : 4.0 / 5.0, contentMode: .fit)
                    Text("Uma arte para apresentar sua edição.\nO link acompanha o compartilhamento.")
                        .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                    Label("Prévia visual · nenhum link publicado", systemImage: "eye")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(24).frame(maxWidth: 440).frame(maxWidth: .infinity)
            }.background(direction.background)
            .navigationTitle("Compartilhar edição")
            .toolbarTitleDisplayMode(.inline)
            .toolbarColorScheme(direction.scheme, for: .navigationBar)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Fechar") { dismiss() } } }
        }.preferredColorScheme(direction.scheme).tint(direction.accent)
    }
}

#Preview("D · Box recebido") {
    NavigationStack { BoxesDetailPreview(direction: .collector, received: true) }
}
#Preview("E · Montar minha versão") { BoxesComposerPreview(direction: .collector, inspired: true) }
#Preview("F · Arte de compartilhamento") { BoxesSharePreview(direction: .collector) }
#endif
