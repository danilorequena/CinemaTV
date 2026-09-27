#if DEBUG && os(iOS)
import SwiftUI

/// Direction A: a personal shelf of physical collector editions.
public struct BoxesCollectorPreview: View {
    @State private var composing: CollectorEdition?
    @State private var editions = CollectorEdition.shelf
    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    introduction
                    featured
                    collection
                    Button { composing = CollectorEdition() } label: {
                        HStack(spacing: 16) {
                            Image(systemName: "plus").font(.title2)
                                .frame(width: 48, height: 56)
                                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(.white.opacity(0.25), style: StrokeStyle(lineWidth: 1, dash: [4])))
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Toda coleção começa com uma ideia.").font(.subheadline.weight(.medium))
                                Text("Monte seu próximo box").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                        }.foregroundStyle(.white.opacity(0.8))
                    }.buttonStyle(.plain)
                }
                .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 32)
                .frame(maxWidth: 660)
                .frame(maxWidth: .infinity)
            }
            .background(BoxesDirection.collector.background)
            .navigationTitle("Meus Boxes")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Criar box", systemImage: "plus") { composing = CollectorEdition() }
                }
            }
            .sheet(item: $composing) { draft in
                CollectorBoxComposerPreview(draft: draft, onSave: save)
            }
        }
        .preferredColorScheme(.dark).tint(DSColor.accent)
    }

    private var introduction: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Sua vida em cinema.").font(.system(.title3, design: .serif).italic())
                Text("As histórias ficam. A edição é sua.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(String(format: "%02d", editions.count))\nBOXES").font(.system(size: 10, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.trailing).tracking(2).foregroundStyle(DSColor.accent)
        }
    }

    private var featured: some View {
        NavigationLink {
            CollectorBoxDetailPreview(received: editions[0].preservedOriginal, edition: editions[0], onSave: save)
        } label: {
            VStack(alignment: .leading, spacing: 19) {
                ZStack {
                    RadialGradient(colors: [Color(red: 0.24, green: 0.25, blue: 0.25), .clear], center: .center, startRadius: 0, endRadius: 210)
                    BoxesCover(title: editions[0].coverTitle, subtitle: editions[0].coverSignature, kind: editions[0].cover)
                        .frame(width: 210, height: 278)
                        .rotation3DEffect(.degrees(-12), axis: (x: 0, y: 1, z: 0))
                        .rotationEffect(.degrees(-3))
                        .shadow(color: .black.opacity(0.8), radius: 20, x: 14, y: 18)
                }
                .frame(maxWidth: .infinity).frame(height: 316)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(LinearGradient(colors: [.clear, .white.opacity(0.17), .clear], startPoint: .leading, endPoint: .trailing)).frame(height: 1)
                }
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(editions[0].title).font(.title3.weight(.semibold))
                        Text(editions[0].summary)
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "arrow.up.right").font(.subheadline)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.07), in: .circle)
                }
            }.foregroundStyle(.white)
        }.buttonStyle(.plain)
    }

    private var collection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("NA SUA ESTANTE").font(.system(size: 10, weight: .semibold)).tracking(2)
                Spacer()
                Text("Feitos para revisitar").font(.caption).foregroundStyle(.secondary)
            }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 22) {
                ForEach(editions.dropFirst()) { edition in
                    NavigationLink {
                        CollectorBoxDetailPreview(received: edition.preservedOriginal, edition: edition, onSave: save)
                    } label: {
                        smallBox(title: edition.coverTitle, name: edition.title, detail: edition.summary, kind: edition.cover)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private func smallBox(title: String, name: String, detail: String, kind: BoxesArtworkKind) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BoxesCover(title: title, subtitle: "MINHA EDIÇÃO", kind: kind)
                .aspectRatio(0.76, contentMode: .fit)
                .shadow(color: .black.opacity(0.6), radius: 8, x: 5, y: 7)
            Text(name).font(.caption.weight(.semibold))
            Text(detail).font(.system(size: 10)).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save(_ edition: CollectorEdition) {
        if let index = editions.firstIndex(where: { $0.id == edition.id }) { editions[index] = edition }
        else { editions.append(edition) }
    }
}

#Preview("A · Colecionador") { BoxesCollectorPreview() }
#endif
