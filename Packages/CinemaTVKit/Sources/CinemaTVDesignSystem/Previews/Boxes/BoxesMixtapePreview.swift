#if DEBUG && os(iOS)
import SwiftUI

public struct BoxesMixtapePreview: View {
    @State private var isCreatingBox = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    introduction
                    NavigationLink {
                        BoxesDetailPreview(direction: .mixtape, received: false)
                    } label: {
                        MixtapeFeaturedBox()
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Abre os filmes, episódios e anotações deste Box")
                    otherBoxes
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 32)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
            .background(MixtapePalette.ink)
            .navigationTitle("Meus Boxes")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Criar Box", systemImage: "plus") {
                        isCreatingBox = true
                    }
                    .tint(MixtapePalette.coral)
                }
            }
            .sheet(isPresented: $isCreatingBox) {
                BoxesComposerPreview(direction: .mixtape)
            }
        }
        .tint(MixtapePalette.lilac)
        .foregroundStyle(MixtapePalette.cream)
        .preferredColorScheme(.dark)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("M")
                    .font(.caption.bold())
                    .foregroundStyle(MixtapePalette.ink)
                    .frame(width: 26, height: 26)
                    .background(MixtapePalette.lilac, in: .circle)
                Text("O UNIVERSO DE MARINA")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .tracking(1.6)
                    .foregroundStyle(MixtapePalette.lilac)
            }
            Text("Histórias que ficam com você.")
                .font(.system(.title2, design: .serif))
            HStack {
                Text("3 Boxes · um pouco de tudo que eu amo")
                    .font(.footnote)
                    .foregroundStyle(MixtapePalette.cream.opacity(0.65))
                Spacer(minLength: 0)
            }
        }
    }

    private var otherBoxes: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("OUTROS PEDACINHOS DE MIM")
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .tracking(1.5)
                .foregroundStyle(MixtapePalette.lilac)
            MixtapeShelfRow(title: "Conforto em episódios", subtitle: "8 episódios · para dias compridos", kind: .office, number: "02")
            MixtapeShelfRow(title: "Mundos que ficam", subtitle: "5 filmes · ainda pensando neles", kind: .arrival, number: "03")
        }
    }
}

private enum MixtapePalette {
    static let ink = Color(red: 0.085, green: 0.066, blue: 0.105)
    static let paper = Color(red: 0.17, green: 0.12, blue: 0.19)
    static let cream = Color(red: 0.96, green: 0.92, blue: 0.83)
    static let coral = Color(red: 1, green: 0.53, blue: 0.43)
    static let lilac = Color(red: 0.77, green: 0.68, blue: 0.90)
}

private struct MixtapeFeaturedBox: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("BOX 001")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .tracking(2)
                Spacer()
                Label("Só meu", systemImage: "lock")
                    .font(.caption2)
                    .foregroundStyle(MixtapePalette.cream.opacity(0.65))
            }
            .foregroundStyle(MixtapePalette.lilac)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Além do tempo")
                        .font(.system(.largeTitle, design: .serif).weight(.medium))
                    Text("Para quando duas horas não bastam.")
                        .font(.footnote)
                        .foregroundStyle(MixtapePalette.cream.opacity(0.7))
                }
                Spacer(minLength: 8)
                Image(systemName: "sparkle")
                    .font(.title)
                    .foregroundStyle(MixtapePalette.coral)
                    .rotationEffect(.degrees(12))
                    .accessibilityHidden(true)
            }
            MixtapeCollage()
            VStack(alignment: .leading, spacing: 8) {
                Text("“Gosto quando o fim me faz\nquerer voltar ao começo.”")
                    .font(.system(.callout, design: .serif).italic())
                    .fixedSize(horizontal: false, vertical: true)
                Text("anotação da Marina")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(MixtapePalette.ink.opacity(0.6))
            }
            .foregroundStyle(MixtapePalette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(MixtapePalette.cream, in: .rect(cornerRadius: 3))
            .rotationEffect(.degrees(-1))
            HStack {
                Text("2 filmes · 1 episódio · 3 extras")
                    .font(.caption2)
                    .foregroundStyle(MixtapePalette.cream.opacity(0.65))
                Spacer(minLength: 4)
                Image(systemName: "arrow.up.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(MixtapePalette.coral)
            }
            .padding(.top, 4)
        }
        .padding(22)
        .background(MixtapePalette.paper.gradient, in: .rect(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .strokeBorder(MixtapePalette.lilac.opacity(0.15), lineWidth: 1)
        }
    }
}

private struct MixtapeCollage: View {
    var body: some View {
        GeometryReader { geometry in
            let unit = min(geometry.size.width / 2.85, 114)
            ZStack {
                MixtapePoster(kind: .arrival, title: "A CHEGADA", width: unit)
                    .rotationEffect(.degrees(-10))
                    .offset(x: -unit * 0.82, y: -12)
                MixtapePoster(kind: .dark, title: "DARK", width: unit)
                    .rotationEffect(.degrees(9))
                    .offset(x: unit * 0.83, y: -10)
                MixtapePoster(kind: .space, title: "INTERSTELLAR", width: unit * 1.08)
                    .rotationEffect(.degrees(-2))
                    .offset(y: -22)
                soundtrack
                    .rotationEffect(.degrees(4))
                    .offset(x: unit * 0.28, y: 82)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: 238)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Interstellar, A Chegada e Dark. Trilha: Cornfield Chase, de Hans Zimmer.")
    }

    private var soundtrack: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform")
                .font(.title3)
                .frame(width: 32, height: 32)
                .background(MixtapePalette.ink.opacity(0.09), in: .rect(cornerRadius: 7))
            VStack(alignment: .leading, spacing: 3) {
                Text("Cornfield Chase").font(.system(size: 12, weight: .semibold))
                Text("Hans Zimmer · trilha sonora").font(.system(size: 9))
            }
        }
        .padding(11)
        .foregroundStyle(MixtapePalette.ink)
        .background(MixtapePalette.lilac, in: .rect(cornerRadius: 10))
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
    }
}

private struct MixtapePoster: View {
    let kind: BoxesArtworkKind
    let title: String
    let width: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            BoxesArtwork(kind: kind)
                .frame(width: width, height: width * 1.34)
                .clipped()
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(MixtapePalette.ink)
                .frame(width: width, height: 24)
        }
        .padding(4)
        .background(MixtapePalette.cream)
        .shadow(color: .black.opacity(0.3), radius: 8, y: 7)
    }
}

private struct MixtapeShelfRow: View {
    let title: String
    let subtitle: String
    let kind: BoxesArtworkKind
    let number: String

    var body: some View {
        HStack(spacing: 15) {
            BoxesArtwork(kind: kind)
                .frame(width: 52, height: 64)
                .clipShape(.rect(cornerRadius: 4))
                .rotationEffect(.degrees(-5))
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.system(.headline, design: .serif))
                Text(subtitle).font(.caption).foregroundStyle(MixtapePalette.cream.opacity(0.6))
            }
            Spacer(minLength: 0)
            Text(number).font(.system(.caption, design: .monospaced)).foregroundStyle(MixtapePalette.lilac)
        }
        .padding(14)
        .background(MixtapePalette.paper.opacity(0.55), in: .rect(cornerRadius: 14))
        .accessibilityElement(children: .combine)
    }
}

#Preview("C · Mixtape") { BoxesMixtapePreview() }
#endif
