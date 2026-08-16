//
//  HeroCarousel.swift
//  CinemaTVKit
//
//  Destaque full-bleed paginado do topo da Home, com parallax no backdrop
//  via visualEffect.
//

import SwiftUI
import CinemaTVCore

public struct HeroCarousel: View {
    private let items: [MediaItem]

    public init(items: [MediaItem]) {
        self.items = items
    }

    public var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(items) { item in
                    let selection = MediaSelection(item: item, scope: "hero")
                    NavigationLink(value: selection) {
                        HeroCard(item: item)
                            .matchedTransitionSourceIfAvailable(id: selection.sourceID)
                    }
                    .buttonStyle(.plain)
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        // Sombra e tilt (rotation3D) extravasam o frame de 400pt; sem isso
        // o viewport clipa o card inclinado reto no topo.
        .scrollClipDisabled()
        // Mesma altura do HeroCard: folga aqui vira espaçamento assimétrico
        // entre o hero e a primeira rail.
        .frame(height: 400)
    }
}

extension View {
    /// matchedTransitionSource condicionado ao namespace injetado por
    /// environment (previews e widgets não injetam).
    @ViewBuilder
    func matchedTransitionSourceIfAvailable(id: String) -> some View {
        modifier(ZoomSourceIfAvailableModifier(id: id))
    }
}

private struct ZoomSourceIfAvailableModifier: ViewModifier {
    @Environment(\.mediaZoomNamespace) private var namespace
    let id: String

    func body(content: Content) -> some View {
        if let namespace {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

private struct HeroCard: View {
    @Environment(\.dsTilt) private var tilt
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let item: MediaItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // clipsContent: false — o parallax precisa da sobra do
            // aspect-fill; quem clipa é o clipShape do card, depois do offset.
            PosterImage(path: item.backdropPath ?? item.posterPath, kind: .backdrop, fillsContainer: true, clipsContent: false)
                // Overscan vertical: o fill 16:9 casa exato na altura do
                // card, sem sobra pro offset do pitch (± 6pt).
                .scaleEffect(1.04)
                // Parallax de scroll + micro-parallax do tilt: a imagem se
                // move um pouco mais que o card, dando profundidade.
                // Em repouso o minX do card é o próprio padding horizontal,
                // então ele é subtraído pro offset zerar com a página parada.
                .visualEffect { [roll = tilt.roll, pitch = tilt.pitch, reduceMotion, restingInset = DSSpacing.lg] content, proxy in
                    content.offset(
                        x: -(proxy.frame(in: .scrollView).minX - restingInset) * 0.3
                            + (reduceMotion ? 0 : roll * 14),
                        y: reduceMotion ? 0 : pitch * 10
                    )
                }
                // Banda holográfica percorre o backdrop conforme o tilt.
                .dsHoloEffect(angle: reduceMotion ? 0 : tilt.roll)

            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(verbatim: item.title)
                    .font(.dsHeroTitle)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                HStack(spacing: DSSpacing.sm) {
                    if let year = item.releaseYear {
                        Text(verbatim: year)
                    }
                    if item.voteAverage > 0 {
                        Label(
                            title: { Text(item.voteAverage, format: .number.precision(.fractionLength(1))) },
                            icon: { Image(systemName: "star.fill") }
                        )
                    }
                }
                .font(.dsCaption)
                .foregroundStyle(.white.secondary)
            }
            .padding(DSSpacing.xl)
        }
        // Altura própria: com fillsContainer o backdrop expandiria além do
        // frame do carousel e a base sairia clipada reta, sem corners.
        .frame(height: 400)
        .clipShape(.rect(cornerRadius: DSRadius.card))
        // Tilt no card inteiro (depois do clip: os corners giram junto).
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : tilt.roll * 5),
            axis: (x: 0, y: 1, z: 0),
            perspective: 0.35
        )
        .rotation3DEffect(
            .degrees(reduceMotion ? 0 : tilt.pitch * 3.5),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.35
        )
        .shadow(color: .black.opacity(0.3), radius: 16, y: 10)
        .padding(.horizontal, DSSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: item.title))
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            HeroCarousel(items: [.dsPreview])
        }
    }
}
