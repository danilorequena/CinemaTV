//
//  ShowProgressCard.swift
//  CinemaTVKit
//
//  Linha da seção "Watching" da tab Tracking: poster + progresso da série +
//  próximo episódio. Base visual do MediaCard.row com a barra no lugar da
//  sinopse.
//

import SwiftUI
import CinemaTVCore

public struct ShowProgressCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mediaZoomNamespace) private var zoomNamespace

    private let item: MediaItem
    private let progress: WatchProgress
    /// "Up next: S2 E5 · Name"; nil quando a série está completa.
    private let upNextLabel: Text?
    /// Mesma convenção do MediaCard: opt-in explícito da zoom transition,
    /// pareado com o MediaSelection de navegação.
    private let zoomSourceID: String?

    public init(
        item: MediaItem,
        progress: WatchProgress,
        upNextLabel: Text? = nil,
        zoomSourceID: String? = nil
    ) {
        self.item = item
        self.progress = progress
        self.upNextLabel = upNextLabel
        self.zoomSourceID = zoomSourceID
    }

    public var body: some View {
        HStack(spacing: DSSpacing.md) {
            PosterImage(path: item.posterPath, kind: .thumbnail)
                .frame(width: 60)
                .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(verbatim: item.title)
                    .font(.dsCardTitle)
                    .lineLimit(1)
                if progress.total > 0 {
                    Text("\(progress.watched) of \(progress.total) episodes", bundle: .module)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(progress.watched)))
                        .animation(DSMotion.respecting(reduceMotion, DSMotion.snappy), value: progress.watched)
                    DSProgressBar(progress: progress.fraction)
                }
                if let upNextLabel {
                    upNextLabel
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else if progress.isComplete {
                    Label {
                        Text("Complete", bundle: .module)
                    } icon: {
                        Image(systemName: "checkmark.seal.fill")
                    }
                    .font(.dsCaption)
                    .foregroundStyle(DSColor.accent)
                }
            }
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .modifier(ZoomSourceModifier(id: zoomSourceID, namespace: zoomNamespace))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: item.title))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: DSSpacing.lg) {
        ShowProgressCard(
            item: .dsPreview,
            progress: WatchProgress(watched: 12, total: 62),
            upNextLabel: Text(verbatim: "Up next: S2 E5 · The Kingsroad")
        )
        ShowProgressCard(
            item: .dsPreview,
            progress: WatchProgress(watched: 62, total: 62)
        )
    }
    .padding()
}
