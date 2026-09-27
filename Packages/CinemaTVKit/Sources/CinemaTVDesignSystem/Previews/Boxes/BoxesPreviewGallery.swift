#if DEBUG && os(iOS)
import SwiftUI

/// Open this file in Xcode Canvas. All data and actions are local preview fixtures.
public struct BoxesPreviewGallery: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Três maneiras de guardar o que o cinema deixou em você.")
                        .font(.system(.title2, design: .serif))
                        .padding(.vertical, 10)
                }
                Section("Escolha uma direção") {
                    NavigationLink { BoxesCollectorPreview() } label: {
                        proposal("A", title: "Colecionador", description: "Capas, lombadas e a sensação de uma edição física.", color: DSColor.accent)
                    }
                    NavigationLink { BoxesEditorialPreview() } label: {
                        proposal("B", title: "Editorial", description: "Um olhar autoral, com respiro e tipografia de revista.", color: .brown)
                    }
                    NavigationLink { BoxesMixtapePreview() } label: {
                        proposal("C", title: "Mixtape", description: "Pôsteres, músicas e lembranças em uma colagem pessoal.", color: .purple)
                    }
                }
                Section("Explore a experiência") {
                    ForEach(BoxesDirection.allCases) { direction in
                        NavigationLink("Receber box · \(direction.title)") {
                            BoxesDetailPreview(direction: direction, received: true)
                        }
                    }
                    NavigationLink("Montar minha versão") { BoxesComposerPreview(direction: .collector, inspired: true) }
                    NavigationLink("Arte para compartilhar") { BoxesSharePreview(direction: .collector) }
                }
                Section {
                    Text("Protótipos visuais com conteúdo ilustrativo. Você pode editar a montagem e experimentar as ações; nada é publicado ou salvo na coleção do app.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("CinemaTV Boxes")
        }.tint(DSColor.accent)
    }

    private func proposal(_ letter: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 15) {
            Text(letter).font(.system(.title2, design: .serif).bold())
                .frame(width: 42, height: 54).background(color.opacity(0.16), in: .rect(cornerRadius: 8))
                .foregroundStyle(color)
            VStack(alignment: .leading, spacing: 5) {
                Text(title).font(.headline)
                Text(description).font(.caption).foregroundStyle(.secondary)
            }
        }.padding(.vertical, 6)
    }
}

#Preview("Boxes · Todas as propostas") { BoxesPreviewGallery() }
#Preview("Boxes A · Colecionador") { BoxesCollectorPreview() }
#Preview("Boxes B · Editorial") { BoxesEditorialPreview() }
#Preview("Boxes C · Mixtape") { BoxesMixtapePreview() }
#Preview("Boxes D · Recebido") { NavigationStack { BoxesDetailPreview(direction: .collector, received: true) } }
#Preview("Boxes E · Minha versão") { BoxesComposerPreview(direction: .collector, inspired: true) }
#Preview("Boxes F · Compartilhar") { BoxesSharePreview(direction: .collector) }
#endif
