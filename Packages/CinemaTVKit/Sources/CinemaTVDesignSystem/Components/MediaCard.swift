//
//  MediaCard.swift
//  CinemaTVKit
//
//  O card único do app — substitui MovieCell, MoviesListCell e as células
//  inline dos três carousels legados. Aplica matchedTransitionSource quando
//  o app injeta o namespace de zoom via environment.
//

import SwiftUI
import CinemaTVCore

public struct MediaCard: View {
    public enum Size {
        /// Poster vertical para rails e grids.
        case poster
        /// Card largo (backdrop) para destaques secundários.
        case wide
        /// Linha horizontal para listas (watchlist, resultados).
        case row
    }

    @Environment(\.mediaZoomNamespace) private var zoomNamespace
    // O gauge contém texto (dsCaption): frame fixo cortava a nota em
    // tamanhos de acessibilidade.
    @ScaledMetric(relativeTo: .caption) private var gaugeSize: CGFloat = 36

    private let item: MediaItem
    private let size: Size
    private let zoomSourceID: String?

    /// zoomSourceID: opt-in explícito da zoom transition. Deve ser único na
    /// tela (o mesmo filme pode aparecer em duas rails) — use
    /// MediaSelection para gerar id e valor de navegação pareados.
    public init(item: MediaItem, size: Size = .poster, zoomSourceID: String? = nil) {
        self.item = item
        self.size = size
        self.zoomSourceID = zoomSourceID
    }

    public var body: some View {
        content
            .modifier(ZoomSourceModifier(id: zoomSourceID, namespace: zoomNamespace))
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(verbatim: item.title))
    }

    @ViewBuilder
    private var content: some View {
        switch size {
        case .poster: posterLayout
        case .wide: wideLayout
        case .row: rowLayout
        }
    }

    private var posterLayout: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            PosterImage(path: item.posterPath, kind: .poster)
                .clipShape(.rect(cornerRadius: DSRadius.poster))
            Text(verbatim: item.title)
                .font(.dsCardTitle)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.leading)
        }
    }

    private var wideLayout: some View {
        ZStack(alignment: .bottomLeading) {
            PosterImage(path: item.backdropPath ?? item.posterPath, kind: .backdrop)
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .center,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(verbatim: item.title)
                    .font(.dsCardTitle)
                    .foregroundStyle(.white)
                if let year = item.releaseYear {
                    Text(verbatim: year)
                        .font(.dsCaption)
                        .foregroundStyle(.white.secondary)
                }
            }
            .padding(DSSpacing.md)
        }
        .clipShape(.rect(cornerRadius: DSRadius.card))
    }

    private var rowLayout: some View {
        HStack(spacing: DSSpacing.md) {
            PosterImage(path: item.posterPath, kind: .thumbnail)
                .frame(width: 60)
                .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(verbatim: item.title)
                    .font(.dsCardTitle)
                    .lineLimit(1)
                Text(verbatim: item.overview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            if item.voteAverage > 0 {
                RatingGauge(value: item.voteAverage)
                    .frame(width: gaugeSize, height: gaugeSize)
            }
        }
        .contentShape(.rect)
    }
}

/// Valor de navegação que pareia o item com o sourceID da zoom transition,
/// permitindo que o destino saiba exatamente de qual card o zoom parte.
public struct MediaSelection: Hashable, Sendable {
    public let item: MediaItem
    public let sourceID: String

    public init(item: MediaItem, scope: String) {
        self.item = item
        self.sourceID = "\(scope)-\(item.id)"
    }
}

/// matchedTransitionSource só quando namespace e id existem (previews e
/// widgets não injetam namespace). Público: cards fora do DS (PersonResultCard,
/// páginas do Discover) aplicam o mesmo padrão.
public struct ZoomSourceModifier: ViewModifier {
    private let id: String?
    private let namespace: Namespace.ID?

    public init(id: String?, namespace: Namespace.ID?) {
        self.id = id
        self.namespace = namespace
    }

    public func body(content: Content) -> some View {
        if let namespace, let id {
            content.matchedTransitionSource(id: id, in: namespace)
        } else {
            content
        }
    }
}

#Preview("Poster", traits: .sizeThatFitsLayout) {
    MediaCard(item: .dsPreview)
        .frame(width: 140)
        .padding()
}

#Preview("Row", traits: .sizeThatFitsLayout) {
    MediaCard(item: .dsPreview, size: .row)
        .padding()
}

extension MediaItem {
    /// Item de exemplo para previews do design system.
    public static let dsPreview = MediaItem(
        id: 603,
        title: "The Matrix",
        overview: "A computer hacker learns from mysterious rebels about the true nature of his reality.",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 8.2,
        releaseDate: "1999-03-31",
        mediaType: .movie
    )
}
