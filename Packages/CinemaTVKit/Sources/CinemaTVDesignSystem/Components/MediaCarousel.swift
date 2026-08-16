//
//  MediaCarousel.swift
//  CinemaTVKit
//
//  A rail horizontal única do app — substitui DefaultCarouselView,
//  CarouselInDetailView e SeasonsCarouselView. Cards navegam por
//  NavigationLink(value: MediaItem); o app resolve o destino com
//  navigationDestination(for: MediaItem.self).
//

import SwiftUI
import CinemaTVCore

public struct MediaCarousel: View {
    // Card escala com o título (dsCardTitle = subheadline): largura fixa
    // truncava títulos reais em tamanhos de acessibilidade.
    @ScaledMetric(relativeTo: .subheadline) private var posterWidth: CGFloat = 140
    @ScaledMetric(relativeTo: .subheadline) private var wideWidth: CGFloat = 280

    private let title: LocalizedStringKey?
    private let items: [MediaItem]
    private let size: MediaCard.Size
    private let zoomScope: String
    private let onSeeAll: (() -> Void)?

    public init(
        title: LocalizedStringKey? = nil,
        items: [MediaItem],
        size: MediaCard.Size = .poster,
        zoomScope: String = "rail",
        onSeeAll: (() -> Void)? = nil
    ) {
        self.title = title
        self.items = items
        self.size = size
        self.zoomScope = zoomScope
        self.onSeeAll = onSeeAll
    }

    private var cardWidth: CGFloat {
        size == .poster ? posterWidth : wideWidth
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            if let title {
                SectionHeader(title, onSeeAll: onSeeAll)
            }
            ScrollView(.horizontal) {
                LazyHStack(spacing: DSSpacing.md) {
                    ForEach(items) { item in
                        let selection = MediaSelection(item: item, scope: zoomScope)
                        NavigationLink(value: selection) {
                            MediaCard(item: item, size: size, zoomSourceID: selection.sourceID)
                                .frame(width: cardWidth)
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
    NavigationStack {
        ScrollView {
            MediaCarousel(
                title: "Popular",
                items: (1...8).map { i in
                    MediaItem(
                        id: i,
                        title: "Movie \(i)",
                        overview: "",
                        posterPath: nil,
                        backdropPath: nil,
                        voteAverage: Double(i),
                        releaseDate: "2026-01-0\(i % 9 + 1)",
                        mediaType: .movie
                    )
                },
                onSeeAll: {}
            )
        }
    }
}
