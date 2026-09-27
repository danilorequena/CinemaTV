#if DEBUG && os(iOS)
import SwiftUI

struct CollectorSharePreview: View {
    let edition: CollectorEdition
    var onSave: ((CollectorEdition) -> Void)? = nil

    private var title: String { edition.title }
    private var author: String { edition.author }
    private var cover: BoxesArtworkKind { edition.cover }
    private var inspiredBy: String? { edition.inspiredBy }

    @Environment(\.dismiss) private var dismiss
    @State private var format = Format.story
    @State private var showsReceivedBox = false

    private enum Format: String, CaseIterable, Identifiable {
        case story = "Story · 9:16"
        case feed = "Feed · 4:5"
        var id: Self { self }
        var ratio: CGFloat { self == .story ? 9.0 / 16.0 : 4.0 / 5.0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Uma edição para passar adiante.")
                            .font(.system(.title3, design: .serif))
                        Picker("Formato da arte", selection: $format) {
                            ForEach(Format.allCases) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    artifact
                        .frame(maxWidth: format == .story ? 280 : 352)
                        .frame(maxWidth: .infinity)

                    editionExplanation
                }
                .padding(24)
                .frame(maxWidth: 440)
                .frame(maxWidth: .infinity)
            }
            .background(BoxesDirection.collector.background)
            .navigationTitle("Compartilhar edição")
            .toolbarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) { receivePreviewAction }
            .sheet(isPresented: $showsReceivedBox) {
                NavigationStack { CollectorBoxDetailPreview(received: true, edition: edition, onSave: onSave) }
            }
        }
        .preferredColorScheme(.dark)
        .tint(DSColor.accent)
    }

    private var artifact: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let isStory = format == .story
            VStack(spacing: width * 0.045) {
                HStack(spacing: 7) {
                    Image(systemName: "shippingbox")
                    Text("CINEMATV BOXES").tracking(2.4)
                }
                .font(.system(size: width * 0.03, weight: .semibold))
                .foregroundStyle(DSColor.accent)

                Spacer(minLength: 0)
                BoxesCover(
                    title: title.uppercased(),
                    subtitle: edition.coverSignature,
                    kind: cover,
                    spine: true
                )
                .frame(width: width * (isStory ? 0.59 : 0.45), height: width * (isStory ? 0.78 : 0.59))
                .rotation3DEffect(.degrees(-12), axis: (x: 0, y: 1, z: 0))
                .rotationEffect(.degrees(-4))
                .shadow(color: .black.opacity(0.75), radius: 16, x: 12, y: 16)
                .padding(.vertical, width * 0.025)

                VStack(spacing: width * 0.022) {
                    Text(title)
                        .font(.system(size: width * 0.075, weight: .medium, design: .serif))
                        .lineLimit(2).minimumScaleFactor(0.7)
                    Text(edition.byline)
                        .font(.system(size: width * 0.034))
                        .foregroundStyle(.white.opacity(0.7))
                    if let inspiredBy {
                        Text("Inspirado no box de \(inspiredBy)")
                            .font(.system(size: width * 0.028))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                .multilineTextAlignment(.center)
                Spacer(minLength: 0)

                Rectangle().fill(DSColor.accent.opacity(0.45)).frame(height: 1)
                HStack {
                    Text("HISTÓRIAS QUE FICAM").tracking(1.4)
                    Spacer(minLength: 4)
                    Image(systemName: "arrow.up.right")
                }
                .font(.system(size: width * 0.025, weight: .medium))
                .foregroundStyle(.white.opacity(0.6))
            }
            .padding(width * 0.085)
            .frame(width: width, height: geometry.size.height)
            .background {
                LinearGradient(
                    colors: [Color(red: 0.25, green: 0.23, blue: 0.19), Color(white: 0.055)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
            }
            .clipShape(.rect(cornerRadius: 8))
            .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(.white.opacity(0.12)) }
        }
        .aspectRatio(format.ratio, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Arte de \(title), uma edição de \(author). Formato \(format.rawValue).")
    }

    private var editionExplanation: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "shippingbox").foregroundStyle(DSColor.accent)
                .font(.title3).padding(.top, 2)
            VStack(alignment: .leading, spacing: 6) {
                Text("O seu olhar, nesta edição.").font(.subheadline.weight(.semibold))
                Text("Quem receber guarda a seleção, a ordem e as impressões como estão. Mudanças futuras ficam no seu box.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var receivePreviewAction: some View {
        VStack(spacing: 10) {
            Button { showsReceivedBox = true } label: {
                Label("Ver como chega", systemImage: "envelope.open")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 15)
                    .foregroundStyle(.black)
                    .background(DSColor.accent, in: .capsule)
            }
            .buttonStyle(.plain)
            Text("Prévia de compartilhamento").font(.caption2).foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24).padding(.top, 12).padding(.bottom, 8)
        .frame(maxWidth: 440).frame(maxWidth: .infinity)
        .background(BoxesDirection.collector.background)
    }
}

#Preview("Colecionador · Compartilhar") {
    CollectorSharePreview(edition: .sample)
}
#endif
