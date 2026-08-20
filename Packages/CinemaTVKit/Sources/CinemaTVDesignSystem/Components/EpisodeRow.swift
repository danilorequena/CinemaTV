//
//  EpisodeRow.swift
//  CinemaTVKit
//
//  Linha de episódio da tela de temporada: still + metadados + checkbox de
//  assistido. A row inteira navega para o detalhe do episódio (quem embrulha
//  em NavigationLink é o app); o toggle é o único outro controle.
//

import SwiftUI
import CinemaTVCore

public struct EpisodeRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mediaZoomNamespace) private var zoomNamespace
    @ScaledMetric(relativeTo: .subheadline) private var stillWidth: CGFloat = 110
    @State private var bounceTrigger = 0

    private let episode: EpisodeSummary
    private let isWatched: Bool
    /// Sem follow o check não tem onde gravar; a navegação continua livre.
    private let isToggleEnabled: Bool
    private let zoomSourceID: String?
    private let onToggle: () -> Void

    public init(
        episode: EpisodeSummary,
        isWatched: Bool,
        isToggleEnabled: Bool = true,
        zoomSourceID: String? = nil,
        onToggle: @escaping () -> Void
    ) {
        self.episode = episode
        self.isWatched = isWatched
        self.isToggleEnabled = isToggleEnabled
        self.zoomSourceID = zoomSourceID
        self.onToggle = onToggle
    }

    public var body: some View {
        let revealScale = DSMotion.ratingRevealScale
        let maskScale = reduceMotion ? revealScale : (isWatched ? revealScale : 0.01)

        HStack(alignment: .top, spacing: DSSpacing.md) {
            // Em tamanhos AX o still (decorativo) esmagava a coluna de texto.
            if !dynamicTypeSize.isAccessibilitySize {
                PosterImage(path: episode.stillPath, kind: .backdrop)
                    .frame(width: stillWidth)
                    .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
                    .modifier(ZoomSourceModifier(id: zoomSourceID, namespace: zoomNamespace))
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(verbatim: "\(episode.episodeNumber) · \(episode.name)")
                    .font(.dsCardTitle)
                    .lineLimit(2)
                if let metadata {
                    Text(verbatim: metadata)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
                if let overview = episode.overview, !overview.isEmpty {
                    // Sem tap-expand: a row navega para o detalhe, que mostra
                    // a sinopse completa.
                    Text(verbatim: overview)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 0)

            Button(action: toggleWatched) {
                ZStack {
                    Image(systemName: "circle")
                        .foregroundStyle(.tertiary)

                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(DSColor.accent)
                        .mask {
                            Circle()
                                .scaleEffect(maskScale)
                        }
                        .opacity(isWatched ? 1 : 0)
                        .shadow(
                            color: DSColor.accent.opacity(isWatched ? 0.4 : 0),
                            radius: isWatched ? DSMotion.ratingGlowRadius : 0
                        )
                        .animation(selectionAnimation, value: isWatched)
                }
                .font(.title2)
                .frame(width: 44, height: 44)
                .contentShape(.circle)
                .symbolEffect(
                    .bounce.up.wholeSymbol,
                    options: .nonRepeating,
                    value: bounceTrigger
                )
                .symbolEffectsRemoved(reduceMotion)
            }
            .buttonStyle(.plain)
            .disabled(!isToggleEnabled)
            .sensoryFeedback(.selection, trigger: isWatched)
            .onChange(of: isWatched) { previousValue, currentValue in
                guard currentValue, !previousValue, !reduceMotion else { return }
                bounceTrigger += 1
            }
            .accessibilityLabel(Text("Mark as Watched", bundle: .module))
            .accessibilityValue(
                isWatched
                    ? Text("Watched", bundle: .module)
                    : Text("Unwatched", bundle: .module)
            )
            // O símbolo checkmark herda o trait Selected e o VoiceOver
            // anunciaria "selecionado" duas vezes.
            .accessibilityRemoveTraits(.isSelected)
        }
        .contentShape(.rect)
    }

    private var selectionAnimation: Animation {
        if reduceMotion {
            return DSMotion.subtleFade
        }
        return isWatched ? DSMotion.ratingSelection : DSMotion.snappy
    }

    private func toggleWatched() {
        if reduceMotion {
            onToggle()
        } else {
            withAnimation(DSMotion.ratingSelection) {
                onToggle()
            }
        }
    }

    private var metadata: String? {
        var parts: [String] = []
        if let runtime = episode.formattedRuntime {
            parts.append(runtime)
        }
        if let airDate = formattedAirDate {
            parts.append(airDate)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    private var formattedAirDate: String? {
        guard let airDate = episode.airDate,
              let date = try? Date(airDate, strategy: .iso8601.year().month().day())
        else { return nil }
        // O parse ISO cai em meia-noite UTC; formatar em GMT evita a data
        // regredir um dia em fusos negativos.
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: .gmt))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: DSSpacing.lg) {
        EpisodeRow(
            episode: EpisodeSummary(
                id: 1,
                name: "Winter Is Coming",
                overview: "Lord Eddard Stark is torn between his family and an old friend when asked to serve at the side of King Robert Baratheon.",
                episodeNumber: 1,
                seasonNumber: 1,
                airDate: "2011-04-17",
                runtime: 62,
                stillPath: nil,
                voteAverage: 8.0
            ),
            isWatched: true,
            onToggle: {}
        )
        EpisodeRow(
            episode: EpisodeSummary(
                id: 2,
                name: "The Kingsroad",
                overview: nil,
                episodeNumber: 2,
                seasonNumber: 1,
                airDate: nil,
                runtime: nil,
                stillPath: nil,
                voteAverage: nil
            ),
            isWatched: false,
            onToggle: {}
        )
    }
    .padding()
}
