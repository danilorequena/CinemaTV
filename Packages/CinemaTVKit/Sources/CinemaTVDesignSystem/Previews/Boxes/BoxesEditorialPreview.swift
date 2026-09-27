#if DEBUG && os(iOS)
import SwiftUI

/// An editorial collection study, isolated from the production Boxes experience.
public struct BoxesEditorialPreview: View {
    @State private var isComposing = false
    @State private var showsReceived = false

    private let paper = Color(red: 0.96, green: 0.94, blue: 0.89)
    private let ink = Color(red: 0.16, green: 0.16, blue: 0.14)
    private let amber = Color(red: 0.73, green: 0.40, blue: 0.12)

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    masthead
                    introduction
                    collectionPicker
                    if showsReceived {
                        receivedCollection
                    } else {
                        featuredCollection
                        otherCollections
                    }
                    Text("BONS FILMES PEDEM BOA COMPANHIA.")
                        .font(.system(size: 9, weight: .medium))
                        .tracking(1.8)
                        .foregroundStyle(ink.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 24)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
            .background(paper.ignoresSafeArea())
            .foregroundStyle(ink)
            .toolbarVisibility(.hidden, for: .navigationBar)
            .sheet(isPresented: $isComposing) {
                BoxesComposerPreview(direction: .editorial)
            }
        }
        .tint(amber)
        .preferredColorScheme(.light)
    }

    private var masthead: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "square.stack.3d.up")
                    .font(.system(size: 18, weight: .light))
                Text("CINEMATV")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.4)
            }
            Spacer()
            Button {
                isComposing = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .regular))
                    .frame(width: 44, height: 44)
                    .background(amber.opacity(0.12), in: .circle)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Criar um Box")
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("SUA BIBLIOTECA PESSOAL")
                .font(.system(size: 9, weight: .semibold))
                .tracking(2.4)
                .foregroundStyle(amber)
            Text("Meus Boxes")
                .font(.system(size: 43, weight: .regular, design: .serif))
                .tracking(-1.6)
                .accessibilityAddTraits(.isHeader)
            Text("Histórias que conversam entre si.")
                .font(.system(size: 14))
                .foregroundStyle(ink.opacity(0.62))
        }
    }

    private var collectionPicker: some View {
        HStack(spacing: 26) {
            collectionTab("Criados por mim", count: "03", received: false)
            collectionTab("Recebidos", count: "01", received: true)
            Spacer(minLength: 0)
        }
        .overlay(alignment: .bottom) {
            Rectangle().fill(ink.opacity(0.15)).frame(height: 0.5)
        }
    }

    private func collectionTab(_ title: String, count: String, received: Bool) -> some View {
        Button {
            showsReceived = received
        } label: {
            HStack(spacing: 6) {
                Text(title).font(.system(size: 12, weight: .medium))
                Text(count).font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(amber)
            }
            .foregroundStyle(ink.opacity(showsReceived == received ? 1 : 0.5))
            .padding(.vertical, 14)
            .overlay(alignment: .bottom) {
                Rectangle().fill(showsReceived == received ? amber : .clear).frame(height: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(showsReceived == received ? .isSelected : [])
    }

    private var featuredCollection: some View {
        NavigationLink {
            BoxesDetailPreview(direction: .editorial, received: false)
        } label: {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    eyebrow("VOL. 001")
                    Spacer()
                    Label("EM DESTAQUE", systemImage: "bookmark.fill")
                        .font(.system(size: 8, weight: .semibold))
                        .tracking(1.2)
                        .foregroundStyle(amber)
                }
                HStack(alignment: .top, spacing: 5) {
                    artwork(.space, title: "INTERSTELLAR")
                    artwork(.arrival, title: "ARRIVAL")
                    artwork(.dark, title: "DARK")
                }
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    Text("Além do tempo")
                        .font(.system(size: 31, weight: .regular, design: .serif))
                        .tracking(-0.9)
                    Spacer(minLength: 0)
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 18, weight: .light))
                        .foregroundStyle(amber)
                }
                Text("Sobre o que fica, mesmo quando\no tempo passa.")
                    .font(.system(size: 15, weight: .regular, design: .serif))
                    .italic()
                    .foregroundStyle(ink.opacity(0.7))
                    .lineSpacing(3)
                HStack(spacing: 8) {
                    Text("M")
                        .font(.system(size: 10, weight: .medium, design: .serif))
                        .frame(width: 23, height: 23)
                        .background(amber.opacity(0.13), in: .circle)
                    Text("Curadoria de Marina").font(.system(size: 11))
                    Spacer()
                    Image(systemName: "film")
                    Image(systemName: "tv")
                    Image(systemName: "music.note")
                    Image(systemName: "text.alignleft")
                }
                .font(.system(size: 11))
                .foregroundStyle(ink.opacity(0.58))
                Rectangle().fill(ink.opacity(0.2)).frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Abrir coleção com filmes, episódios, trilha sonora e notas")
    }

    private func artwork(_ kind: BoxesArtworkKind, title: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            BoxesArtwork(kind: kind)
                .aspectRatio(0.65, contentMode: .fill)
                .frame(maxWidth: .infinity)
                .frame(height: 160)
                .clipped()
                .accessibilityHidden(true)
            Text(title)
                .font(.system(size: 7, weight: .semibold))
                .tracking(1)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var otherCollections: some View {
        VStack(alignment: .leading, spacing: 20) {
            eyebrow("OUTROS CAPÍTULOS")
            collectionRow("02", title: "Para rir de novo", subtitle: "Episódios que são um lugar seguro.", kind: .office)
            Rectangle().fill(ink.opacity(0.15)).frame(height: 0.5)
            collectionRow("03", title: "Quando a noite cai", subtitle: "Mistérios para ver com a luz acesa.", kind: .dark)
        }
    }

    private var receivedCollection: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("De quem conhece\no seu gosto.")
                .font(.system(size: 31, weight: .regular, design: .serif))
            collectionRow("01", title: "Um domingo sem pressa", subtitle: "Um Box de Lucas, escolhido para você.", kind: .arrival)
        }
    }

    private func collectionRow(_ number: String, title: String, subtitle: String, kind: BoxesArtworkKind) -> some View {
        HStack(alignment: .center, spacing: 14) {
            BoxesArtwork(kind: kind)
                .aspectRatio(0.78, contentMode: .fill)
                .frame(width: 58, height: 76)
                .clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                eyebrow("VOL. \(number)")
                Text(title).font(.system(size: 20, weight: .regular, design: .serif))
                Text(subtitle).font(.system(size: 11)).foregroundStyle(ink.opacity(0.58))
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private func eyebrow(_ value: String) -> some View {
        Text(value).font(.system(size: 8, weight: .medium)).tracking(1.8).foregroundStyle(ink.opacity(0.55))
    }
}

#Preview("B · Editorial") {
    BoxesEditorialPreview()
}
#endif
