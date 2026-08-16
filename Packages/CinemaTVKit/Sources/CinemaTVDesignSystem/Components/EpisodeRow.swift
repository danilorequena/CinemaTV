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

            Button(action: onToggle) {
                // Círculo glass no lugar do símbolo nu: vazio convida ao tap;
                // assistido preenche com o tint accent.
                Image(systemName: "checkmark")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(isWatched ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                    .opacity(isWatched ? 1 : 0.3)
                    .symbolEffect(.bounce, value: isWatched)
                    .padding(DSSpacing.sm)
                    .glassEffect(
                        isWatched ? .regular.tint(DSColor.accent).interactive() : .regular.interactive(),
                        in: .circle
                    )
                    // O tint só anima se a mudança de isWatched chegar
                    // animada; o toggle vem de fora sem withAnimation.
                    .animation(DSMotion.respecting(reduceMotion, DSMotion.snappy), value: isWatched)
            }
            .buttonStyle(.plain)
            .disabled(!isToggleEnabled)
            .sensoryFeedback(.impact(weight: .light), trigger: isWatched)
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
