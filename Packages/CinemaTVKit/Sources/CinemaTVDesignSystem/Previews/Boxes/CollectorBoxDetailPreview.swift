#if DEBUG && os(iOS)
import SwiftUI

struct CollectorBoxDetailPreview: View {
    let received: Bool
    var onSave: ((CollectorEdition) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var edition: CollectorEdition
    @State private var editing: CollectorEdition?
    @State private var showsShare = false
    @State private var savedOriginal = false
    @State private var adapted: CollectorEdition?

    init(received: Bool, edition: CollectorEdition? = nil, onSave: ((CollectorEdition) -> Void)? = nil) {
        self.received = received
        self.onSave = onSave
        _edition = State(initialValue: edition ?? (received ? .sample : .personalSample))
        _savedOriginal = State(initialValue: edition?.preservedOriginal ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CollectorOpeningCover(edition: edition)
                introduction
                if let adapted {
                    NavigationLink {
                        CollectorBoxDetailPreview(received: false, edition: adapted) { updated in
                            self.adapted = updated
                            onSave?(updated)
                        }
                    } label: {
                        Label("Abrir minha versão", systemImage: "arrow.triangle.branch")
                            .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(14)
                            .background(.white.opacity(0.06), in: .rect(cornerRadius: 12))
                    }
                }
                HStack(alignment: .firstTextBaseline) {
                    Text("Dentro do box").font(.system(.title2, design: .serif))
                    Spacer()
                    Text("\(edition.entries.count) ITENS").font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .tracking(2).foregroundStyle(.secondary)
                }
                VStack(spacing: 16) {
                    ForEach(Array(edition.entries.enumerated()), id: \.element.id) { index, item in
                        CollectorContentCard(item: item, position: index + 1)
                    }
                }
                Label(received ? "Uma edição de \(edition.author), preservada como chegou." : "A sequência conta a sua história.", systemImage: "shippingbox")
                    .font(.caption).foregroundStyle(.secondary).padding(.vertical, 10)
            }
            .padding(.horizontal, 24).padding(.bottom, 24)
            .frame(maxWidth: 640).frame(maxWidth: .infinity)
        }
        .background(BoxesDirection.collector.background).foregroundStyle(.white)
        .navigationTitle(received ? "Edição recebida" : "Meu box")
        .toolbarTitleDisplayMode(.inline).toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            if received {
                ToolbarItem(placement: .cancellationAction) { Button("Fechar", systemImage: "xmark") { dismiss() } }
            } else {
                ToolbarItem(placement: .topBarTrailing) { Button("Editar", systemImage: "pencil") { editing = edition } }
                ToolbarItem(placement: .topBarTrailing) { Button("Compartilhar", systemImage: "square.and.arrow.up") { showsShare = true } }
            }
        }
        .safeAreaInset(edge: .bottom) { if received { receiveActions } }
        .sheet(item: $editing) { draft in
            CollectorBoxComposerPreview(draft: draft) { updated in
                if received { adapted = updated } else { edition = updated }
                onSave?(updated)
            }
        }
        .sheet(isPresented: $showsShare) {
            CollectorSharePreview(edition: edition, onSave: onSave)
        }
        .preferredColorScheme(.dark).tint(DSColor.accent)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(received ? "ESCOLHIDO PARA COMPARTILHAR" : "EDIÇÃO PESSOAL")
                .font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(2).foregroundStyle(DSColor.accent)
            Text(edition.title).font(.system(.largeTitle, design: .serif).weight(.semibold)).tracking(-0.8)
            HStack(spacing: 8) {
                Text(String(edition.author.prefix(1))).font(.caption.bold()).frame(width: 26, height: 26)
                    .background(.white.opacity(0.08), in: .circle)
                Text(edition.byline).font(.subheadline)
            }
            if let original = edition.inspiredBy {
                Label("Inspirado no box de \(original)", systemImage: "arrow.triangle.branch")
                    .font(.caption).foregroundStyle(DSColor.accent)
            }
            if !edition.description.isEmpty {
                Text(edition.description).font(.subheadline).foregroundStyle(.secondary).lineSpacing(4)
            }
            Text(edition.summary).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var receiveActions: some View {
        VStack(spacing: 12) {
            Button {
                guard !savedOriginal else { return }
                savedOriginal = true
                var original = edition
                original.id = UUID()
                original.preservedOriginal = true
                onSave?(original)
            } label: {
                Label(savedOriginal ? (onSave == nil ? "Original guardado nesta prévia" : "Original na sua estante") : "Guardar original", systemImage: savedOriginal ? "checkmark" : "plus")
                    .font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity).padding(15)
                    .foregroundStyle(.black).background(DSColor.accent, in: .capsule)
            }.disabled(savedOriginal)
            Button("Criar minha versão") { editing = edition.personalized() }
                .font(.subheadline.weight(.semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 24).padding(.vertical, 12).frame(maxWidth: 640).frame(maxWidth: .infinity)
        .background(BoxesDirection.collector.background)
    }
}

struct CollectorOpeningCover: View {
    let edition: CollectorEdition
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isOpen = true

    var body: some View {
        Button {
            withAnimation(reduceMotion ? nil : .spring(response: 0.65, dampingFraction: 0.82)) { isOpen.toggle() }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    RadialGradient(colors: [.white.opacity(0.09), .clear], center: .center, startRadius: 5, endRadius: 170)
                    HStack(spacing: 5) {
                        ForEach(Array(edition.entries.filter { [.movie, .series, .season, .episode].contains($0.kind) }.prefix(3).enumerated()), id: \.element.id) { index, item in
                            BoxesArtwork(kind: item.artwork)
                                .overlay(alignment: .bottom) {
                                    Text(String(format: "%02d", index + 1)).font(.system(size: 10, design: .monospaced))
                                        .padding(.bottom, 10)
                                }.clipShape(.rect(cornerRadius: 4))
                        }
                    }
                    .padding(10).frame(width: 158, height: 206)
                    .background(Color(white: 0.16), in: .rect(cornerRadius: 7))
                    .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(.white.opacity(0.16)))
                    .rotationEffect(.degrees(4)).offset(x: isOpen ? 64 : 0, y: 4)
                    .opacity(isOpen ? 1 : 0)
                    BoxesCover(title: edition.coverTitle, subtitle: edition.coverSignature, kind: edition.cover)
                        .frame(width: 170, height: 225)
                        .rotation3DEffect(.degrees(isOpen ? -25 : -8), axis: (x: 0, y: 1, z: 0))
                        .rotationEffect(.degrees(isOpen ? -6 : -2))
                        .offset(x: isOpen ? -48 : 0)
                        .shadow(color: .black.opacity(0.6), radius: 14, x: 8, y: 14)
                }.frame(height: 250)
                Label(isOpen ? "Fechar capa" : "Abrir edição", systemImage: isOpen ? "book.closed" : "book")
                    .font(.system(size: 10, weight: .medium)).foregroundStyle(.secondary)
            }.foregroundStyle(.white).frame(maxWidth: .infinity)
        }.buttonStyle(.plain)
            .accessibilityLabel(isOpen ? "Fechar capa de \(edition.title)" : "Abrir edição \(edition.title)")
            .padding(.top, 8)
    }
}

struct CollectorContentCard: View {
    let item: CollectorItem
    let position: Int
    var body: some View {
        Group {
            if let note = item.note {
                VStack(alignment: .leading, spacing: 13) {
                    HStack {
                        Label("IMPRESSÕES", systemImage: "quote.opening")
                        Spacer()
                        Text(String(format: "%02d", position))
                    }.font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(1.8)
                    Text("“\(note)”").font(.system(.title3, design: .serif).italic()).lineSpacing(4)
                    Text("\(item.author ?? "Você") · \(item.subtitle)").font(.caption)
                        .foregroundStyle(.black.opacity(0.55))
                }.padding(20).foregroundStyle(.black.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(red: 0.91, green: 0.87, blue: 0.76), in: .rect(cornerRadius: 4))
            } else {
                HStack(spacing: 15) {
                    BoxesArtwork(kind: item.artwork)
                        .frame(width: item.kind == .trailer ? 104 : 64, height: 84)
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay {
                            if item.kind == .trailer || item.kind == .music {
                                Image(systemName: item.kind == .trailer ? "play.circle.fill" : "waveform")
                                    .font(.title2).foregroundStyle(.white)
                            }
                        }
                    VStack(alignment: .leading, spacing: 7) {
                        Text("\(String(format: "%02d", position))  /  \(item.kind.rawValue.uppercased())")
                            .font(.system(size: 9, weight: .medium, design: .monospaced)).tracking(1).foregroundStyle(DSColor.accent)
                        Text(item.title).font(.subheadline.weight(.semibold))
                        Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white.opacity(0.045), in: .rect(cornerRadius: 12))
            }
        }.accessibilityElement(children: .combine)
    }
}

#Preview("Colecionador · Abrir box") {
    NavigationStack { CollectorBoxDetailPreview(received: false) }
}
#Preview("Colecionador · Receber edição") {
    NavigationStack { CollectorBoxDetailPreview(received: true) }
}
#endif
