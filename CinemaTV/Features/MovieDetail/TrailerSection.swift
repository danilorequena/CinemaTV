//
//  TrailerSection.swift
//  CinemaTV
//
//  Rail de trailers com thumbnail do YouTube + play. Substitui
//  TrailersView/VideosView.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct TrailerSection: View {
    let videos: [Video]
    let onPlay: (Video) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            SectionHeader("Trailers")
            ScrollView(.horizontal) {
                LazyHStack(spacing: DSSpacing.md) {
                    ForEach(videos) { video in
                        Button {
                            onPlay(video)
                        } label: {
                            thumbnail(for: video)
                        }
                        .buttonStyle(.plain)
                        // O botão abre o player: avisa o VoiceOver para
                        // pausar a própria fala durante a mídia.
                        .accessibilityAddTraits(.startsMediaSession)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, DSSpacing.lg)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
    }

    private func thumbnail(for video: Video) -> some View {
        ZStack {
            AsyncImage(url: video.youTubeThumbnailURL) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle().fill(.quaternary)
            }
            .frame(width: 240, height: 135)
            .clipShape(.rect(cornerRadius: DSRadius.poster))

            Image(systemName: "play.fill")
                .font(.title2)
                .padding(DSSpacing.md)
                .glassEffect(.regular.interactive(), in: .circle)
        }
        .accessibilityLabel(Text(verbatim: video.name))
    }
}
