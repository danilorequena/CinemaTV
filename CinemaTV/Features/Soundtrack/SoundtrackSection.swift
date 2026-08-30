//
//  SoundtrackSection.swift
//  CinemaTV
//
//  Seção de trilha sonora no detail (filme/série). View burra no molde do
//  TrailerSection: dados + closures, sem environment. Alimentada pelo
//  SoundtrackModel (MusicKit + AgentEngine) e pelo SoundtrackPlayerModel.
//

import SwiftUI
import CinemaTVDesignSystem

struct SoundtrackSection: View {
    let album: SoundtrackCandidate
    let about: String?
    let tracks: [SoundtrackTrack]
    let mode: SoundtrackPlayerModel.PlaybackMode
    let nowPlayingTrackID: String?
    let isPlaying: Bool
    /// Posição atual da faixa tocando, em segundos.
    let elapsed: TimeInterval
    /// Duração do que está tocando (faixa completa ou preview de ~30s).
    let playbackDuration: TimeInterval?
    let onPlayTrack: (SoundtrackTrack) -> Void
    let onOpenInAppleMusic: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            SectionHeader("Soundtrack")

            albumHeader
                .padding(.horizontal, DSSpacing.lg)

            if let about {
                Text(verbatim: about)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)
            }

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: DSSpacing.md) {
                    ForEach(tracks) { track in
                        trackCard(track)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, DSSpacing.lg)
                // No container (não no card): a largura do card em morph e o
                // deslocamento dos vizinhos animam na mesma transação.
                .animation(.smooth(duration: 0.35), value: nowPlayingTrackID)
                // Play↔pause na mesma faixa (symbol replace + numericText).
                .animation(.default, value: isPlaying)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)

            if mode == .previewOnly {
                openInAppleMusicButton
            }
        }
    }

    private var openInAppleMusicButton: some View {
        // Trailing closure de propósito: `Button(action: closureArmazenada)`
        // quebra o thunk incremental do preview (__designTimeSelection).
        Button {
            onOpenInAppleMusic()
        } label: {
            Label("Open in Apple Music", systemImage: "arrow.up.forward")
        }
        .buttonStyle(.glass)
        .padding(.horizontal, DSSpacing.lg)
    }

    // MARK: - Album header

    private var albumHeader: some View {
        HStack(spacing: DSSpacing.md) {
            artwork
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(verbatim: album.title)
                    .font(.dsCardTitle)
                    .lineLimit(2)
                Text(verbatim: album.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(verbatim: albumMetadata)
                    .font(.dsCaption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    private var albumMetadata: String {
        var parts: [String] = []
        if let releaseYear = album.releaseYear {
            parts.append(String(releaseYear))
        }
        parts.append("\(tracks.count) tracks")
        return parts.joined(separator: " · ")
    }

    private var artwork: some View {
        AsyncImage(url: album.artworkURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } placeholder: {
            ZStack {
                Rectangle().fill(.quaternary)
                Image(systemName: "music.note")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 88, height: 88)
        .clipShape(.rect(cornerRadius: DSRadius.poster))
        .accessibilityHidden(true)
    }

    // MARK: - Track cards

    /// Card único para os dois estados — identidade estável de todas as
    /// views para o morph ser natural: só a largura cresce e os elementos
    /// internos (título, linha de legenda) acompanham o layout. O que
    /// aparece/some (barra, minutagem total) anima dentro da mesma linha;
    /// o tempo à esquerda é o MESMO Text (duração ↔ decorrido) trocando
    /// via .numericText().
    private func trackCard(_ track: SoundtrackTrack) -> some View {
        let isNowPlaying = nowPlayingTrackID == track.id
        let isPlayable = mode != .previewOnly || track.previewURL != nil
        let leadingTime: TimeInterval? = isNowPlaying ? elapsed : track.duration

        return Button {
            onPlayTrack(track)
        } label: {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Image(systemName: isNowPlaying && isPlaying ? "pause.fill" : "play.fill")
                    .font(.body)
                    .padding(DSSpacing.sm)
                    .glassEffect(.regular.interactive(), in: .circle)
                    .contentTransition(.symbolEffect(.replace))

                Text(verbatim: track.title)
                    .font(.dsCardTitle)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2, reservesSpace: true)

                HStack(spacing: DSSpacing.xs) {
                    if let leadingTime {
                        Text(Duration.seconds(leadingTime), format: .time(pattern: .minuteSecond))
                            .contentTransition(.numericText())
                    }
                    if isNowPlaying {
                        ProgressView(value: progressFraction(for: track))
                            .progressViewStyle(.linear)
                            .tint(DSColor.accent)
                        if let total = playbackDuration ?? track.duration {
                            Text(Duration.seconds(total), format: .time(pattern: .minuteSecond))
                        }
                    }
                    if mode == .previewOnly {
                        Text("Preview")
                    }
                }
                .font(.dsCaption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
            }
            .padding(DSSpacing.md)
            .frame(width: isNowPlaying ? 248 : 150, alignment: .leading)
            .background(.quaternary.opacity(0.5), in: .rect(cornerRadius: DSRadius.card))
        }
        .buttonStyle(.plain)
        .disabled(!isPlayable)
        .opacity(isPlayable ? 1 : 0.4)
        // O botão inicia áudio: avisa o VoiceOver para pausar a fala.
        .accessibilityAddTraits(.startsMediaSession)
        .accessibilityLabel(Text(verbatim: track.title))
    }

    private func progressFraction(for track: SoundtrackTrack) -> Double {
        let total = playbackDuration ?? track.duration ?? 0
        guard total > 0 else { return 0 }
        return min(max(elapsed / total, 0), 1)
    }
}

// MARK: - Previews (dados mockados do Titanic)

private enum SoundtrackPreviewData {
    static let album = SoundtrackCandidate(
        id: "294609",
        title: "Titanic: Music from the Motion Picture",
        artistName: "James Horner",
        releaseYear: 1997,
        trackCount: 5,
        artworkURL: nil,
        url: nil
    )

    static let tracks: [SoundtrackTrack] = [
        .init(id: "1", title: "Never an Absolution", artistName: "James Horner", duration: 183, previewURL: URL(string: "https://example.com/1.m4a"), song: nil),
        .init(id: "2", title: "Southampton", artistName: "James Horner", duration: 242, previewURL: URL(string: "https://example.com/2.m4a"), song: nil),
        .init(id: "3", title: "Rose", artistName: "James Horner", duration: 172, previewURL: nil, song: nil),
        .init(id: "4", title: "Hymn to the Sea", artistName: "James Horner", duration: 386, previewURL: URL(string: "https://example.com/4.m4a"), song: nil),
        .init(id: "5", title: "My Heart Will Go On (Love Theme from \"Titanic\")", artistName: "Céline Dion", duration: 311, previewURL: URL(string: "https://example.com/5.m4a"), song: nil),
    ]

    static let about = "Composta por James Horner, a trilha de Titanic combina vocais célticos etéreos com orquestra sinfônica para acompanhar o romance e a tragédia do transatlântico. O álbum se tornou uma das trilhas sonoras mais vendidas de todos os tempos, impulsionado por \"My Heart Will Go On\", interpretada por Céline Dion."
}

#Preview("Assinante — tocando") {
    ScrollView {
        SoundtrackSection(
            album: SoundtrackPreviewData.album,
            about: SoundtrackPreviewData.about,
            tracks: SoundtrackPreviewData.tracks,
            mode: .fullPlayback,
            nowPlayingTrackID: "2",
            isPlaying: true,
            elapsed: 97,
            playbackDuration: 242,
            onPlayTrack: { _ in },
            onOpenInAppleMusic: {}
        )
        .padding(.vertical, DSSpacing.lg)
    }
}

#Preview("Sem assinatura — previews de 30s") {
    ScrollView {
        SoundtrackSection(
            album: SoundtrackPreviewData.album,
            about: SoundtrackPreviewData.about,
            tracks: SoundtrackPreviewData.tracks,
            mode: .previewOnly,
            nowPlayingTrackID: "1",
            isPlaying: true,
            elapsed: 12,
            playbackDuration: 30,
            onPlayTrack: { _ in },
            onOpenInAppleMusic: {}
        )
        .padding(.vertical, DSSpacing.lg)
    }
}

#Preview("Sem IA — sem parágrafo") {
    ScrollView {
        SoundtrackSection(
            album: SoundtrackPreviewData.album,
            about: nil,
            tracks: SoundtrackPreviewData.tracks,
            mode: .fullPlayback,
            nowPlayingTrackID: nil,
            isPlaying: false,
            elapsed: 0,
            playbackDuration: nil,
            onPlayTrack: { _ in },
            onOpenInAppleMusic: {}
        )
        .padding(.vertical, DSSpacing.lg)
    }
}
