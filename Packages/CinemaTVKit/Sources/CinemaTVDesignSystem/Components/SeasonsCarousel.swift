//
//  SeasonsCarousel.swift
//  CinemaTVKit
//
//  Rail de temporadas do detalhe de série. Navegação por closure porque o
//  destino (Route.season) é um tipo do app, não do package.
//

import SwiftUI
import CinemaTVCore

public struct SeasonCard: View {
    private let season: SeasonSummary
    /// nil quando a série não está sendo acompanhada (sem barra).
    private let progress: WatchProgress?

    public init(season: SeasonSummary, progress: WatchProgress? = nil) {
        self.season = season
        self.progress = progress
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            PosterImage(path: season.posterPath, kind: .poster)
                .clipShape(.rect(cornerRadius: DSRadius.poster))
            Text(verbatim: season.name)
                .font(.dsCardTitle)
                .lineLimit(1)
            if let count = season.episodeCount {
                Text("\(count) episodes", bundle: .module)
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
            }
            if let progress {
                DSProgressBar(progress: progress.fraction)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

public struct SeasonsCarousel: View {
    // Mesma razão do MediaCarousel: largura fixa truncava o nome da
    // temporada em tamanhos de acessibilidade.
    @ScaledMetric(relativeTo: .subheadline) private var cardWidth: CGFloat = 120
    @Environment(\.mediaZoomNamespace) private var zoomNamespace

    private let title: Text
    private let seasons: [SeasonSummary]
    private let progress: (SeasonSummary) -> WatchProgress?
    /// Recebe também o sourceID da zoom transition (nil sem zoomScope),
    /// para o app repassar ao Route sem duplicar a convenção do id.
    private let onSelect: (SeasonSummary, String?) -> Void
    private let zoomScope: String?

    public init(
        title: LocalizedStringKey,
        seasons: [SeasonSummary],
        progress: @escaping (SeasonSummary) -> WatchProgress? = { _ in nil },
        zoomScope: String? = nil,
        onSelect: @escaping (SeasonSummary, String?) -> Void
    ) {
        self.title = Text(title)
        self.seasons = seasons
        self.progress = progress
        self.zoomScope = zoomScope
        self.onSelect = onSelect
    }

    private func sourceID(for season: SeasonSummary) -> String? {
        zoomScope.map { "\($0)-\(season.id)" }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            SectionHeader(text: title)
            ScrollView(.horizontal) {
                LazyHStack(spacing: DSSpacing.md) {
                    ForEach(seasons) { season in
                        Button {
                            onSelect(season, sourceID(for: season))
                        } label: {
                            SeasonCard(season: season, progress: progress(season))
                                .frame(width: cardWidth)
                                .modifier(ZoomSourceModifier(id: sourceID(for: season), namespace: zoomNamespace))
                        }
                        .buttonStyle(.plain)
                        .scrollTransition(.interactive) { content, phase in
                            content
                                .scaleEffect(phase.isIdentity ? 1 : 0.92)
                                .opacity(phase.isIdentity ? 1 : 0.65)
                        }
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, DSSpacing.lg)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollClipDisabled()
        }
    }
}

#Preview {
    ScrollView {
        SeasonsCarousel(
            title: "Seasons",
            seasons: (1...5).map { i in
                SeasonSummary(
                    id: i,
                    name: "Season \(i)",
                    overview: nil,
                    posterPath: nil,
                    seasonNumber: i,
                    episodeCount: 8 + i,
                    airDate: "202\(i)-01-01"
                )
            },
            progress: { season in
                season.seasonNumber < 3
                    ? WatchProgress(watched: season.seasonNumber == 1 ? 9 : 4, total: 8 + season.seasonNumber)
                    : nil
            },
            onSelect: { _, _ in }
        )
    }
}
