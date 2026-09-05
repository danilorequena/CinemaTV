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
    let about: String?
    /// Canções (vocais) e instrumental, cada grupo com o álbum de origem.
    /// Mesmo álbum nos dois = header único com fileiras rotuladas; álbuns
    /// distintos = header compacto por grupo; um grupo só = fileira única.
    let songs: SoundtrackGroup?
    let instrumental: SoundtrackGroup?
    let mode: SoundtrackPlayerModel.PlaybackMode
    let nowPlayingTrackID: String?
    let isPlaying: Bool
    /// Posição atual da faixa tocando, em segundos.
    let elapsed: TimeInterval
    /// Duração do que está tocando (faixa completa ou preview de ~30s).
    let playbackDuration: TimeInterval?
    /// A fila é o grupo de onde a faixa veio: a reprodução segue no álbum.
    let onPlayTrack: (SoundtrackTrack, [SoundtrackTrack]) -> Void
    let onOpenInAppleMusic: (SoundtrackCandidate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            SectionHeader("Soundtrack")

            if let songs, let instrumental, songs.album.id != instrumental.album.id {
                aboutText
                groupSection(songs, label: "Songs")
                groupSection(instrumental, label: "Instrumental")
            } else if let primary = instrumental ?? songs {
                albumHeader(primary.album)
                    .padding(.horizontal, DSSpacing.lg)
                aboutText
                if let songs, let instrumental {
                    subheader("Songs")
                    trackRow(songs)
                    subheader("Instrumental")
                    trackRow(instrumental)
                } else {
                    trackRow(primary)
                }
            }

            if mode == .previewOnly {
                openInAppleMusicButton
            }
        }
    }

    @ViewBuilder
    private var aboutText: some View {
        if let about {
            Text(verbatim: about)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DSSpacing.lg)
        }
    }

    /// Sub-título de grupo no mesmo padrão dos rótulos do ProviderRow.
    private func subheader(_ title: LocalizedStringKey) -> some View {
        Text(title)
            .font(.dsCaption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, DSSpacing.lg)
    }

    /// Grupo com álbum próprio (modo dois álbuns): rótulo + header compacto
    /// tocável + fileira de faixas.
    private func groupSection(_ group: SoundtrackGroup, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            subheader(label)
            compactAlbumHeader(group.album)
            trackRow(group)
        }
    }

    private var primaryAlbum: SoundtrackCandidate? {
        (instrumental ?? songs)?.album
    }

    private var openInAppleMusicButton: some View {
        // Trailing closure de propósito: `Button(action: closureArmazenada)`
        // quebra o thunk incremental do preview (__designTimeSelection).
        Button {
            if let primaryAlbum {
                onOpenInAppleMusic(primaryAlbum)
            }
        } label: {
            Label("Open in Apple Music", systemImage: "arrow.up.forward")
        }
        .buttonStyle(.glass)
        .padding(.horizontal, DSSpacing.lg)
    }

    // MARK: - Album headers

    private func albumHeader(_ album: SoundtrackCandidate) -> some View {
        HStack(spacing: DSSpacing.md) {
            artwork(album.artworkURL, size: 88)
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text(verbatim: album.title)
                    .font(.dsCardTitle)
                    .lineLimit(2)
                Text(verbatim: album.artistName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(verbatim: albumMetadata(album))
                    .font(.dsCaption)
                    .foregroundStyle(.tertiary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }

    /// Header compacto do modo dois álbuns; tocá-lo abre o álbum no Apple
    /// Music (o botão grande de preview segue apontando para o primário).
    private func compactAlbumHeader(_ album: SoundtrackCandidate) -> some View {
        Button {
            onOpenInAppleMusic(album)
        } label: {
            HStack(spacing: DSSpacing.sm) {
                artwork(album.artworkURL, size: 44)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: album.title)
                        .font(.dsCaption.weight(.medium))
                        .lineLimit(1)
                    Text(verbatim: album.artistName)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Image(systemName: "arrow.up.forward")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, DSSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityHint(Text("Open in Apple Music"))
    }

    private func albumMetadata(_ album: SoundtrackCandidate) -> String {
        var parts: [String] = []
        if let releaseYear = album.releaseYear {
            parts.append(String(releaseYear))
        }
        let total = (songs?.tracks.count ?? 0) + (instrumental?.tracks.count ?? 0)
        parts.append("\(total) tracks")
        return parts.joined(separator: " · ")
    }

    private func artwork(_ url: URL?, size: CGFloat) -> some View {
        AsyncImage(url: url) { image in
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
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: DSRadius.poster))
        .accessibilityHidden(true)
    }

    // MARK: - Track cards

    private func trackRow(_ group: SoundtrackGroup) -> some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: DSSpacing.md) {
                ForEach(group.tracks) { track in
                    trackCard(track, queue: group.tracks)
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
    }

    /// Card único para os dois estados — identidade estável de todas as
    /// views para o morph ser natural: só a largura cresce e os elementos
    /// internos (título, linha de legenda) acompanham o layout. O que
    /// aparece/some (barra, minutagem total) anima dentro da mesma linha;
    /// o tempo à esquerda é o MESMO Text (duração ↔ decorrido) trocando
    /// via .numericText().
    private func trackCard(_ track: SoundtrackTrack, queue: [SoundtrackTrack]) -> some View {
        let isNowPlaying = nowPlayingTrackID == track.id
        let isPlayable = mode != .previewOnly || track.previewURL != nil
        let leadingTime: TimeInterval? = isNowPlaying ? elapsed : track.duration

        return Button {
            onPlayTrack(track, queue)
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

// MARK: - Loading skeleton

/// Skeleton exibido enquanto o pipeline (busca no catálogo + IA) roda —
/// sem ele a seção "pipocava" pronta segundos depois da tela carregar.
/// Se a busca termina sem trilha, o skeleton some; sinalizar e recolher é
/// melhor do que nunca dar feedback de que a busca acontece.
struct SoundtrackLoadingSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            SectionHeader("Soundtrack")

            HStack(spacing: DSSpacing.sm) {
                ProgressView()
                    .controlSize(.small)
                Text("Searching Apple Music…")
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DSSpacing.lg)

            // Silhueta do layout final (header do álbum + fileira de cards);
            // textos verbatim: viram barras redacted, não chaves no catálogo.
            LoadingStateView {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    HStack(spacing: DSSpacing.md) {
                        RoundedRectangle(cornerRadius: DSRadius.poster)
                            .fill(.quaternary)
                            .frame(width: 88, height: 88)
                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text(verbatim: "Album title placeholder")
                                .font(.dsCardTitle)
                            Text(verbatim: "Album artist")
                                .font(.subheadline)
                            Text(verbatim: "Year · tracks")
                                .font(.dsCaption)
                        }
                        Spacer(minLength: 0)
                    }
                    HStack(spacing: DSSpacing.md) {
                        RoundedRectangle(cornerRadius: DSRadius.card)
                            .fill(.quaternary.opacity(0.5))
                            .frame(width: 150, height: 132)
                        RoundedRectangle(cornerRadius: DSRadius.card)
                            .fill(.quaternary.opacity(0.5))
                            .frame(width: 150, height: 132)
                    }
                }
                .padding(.horizontal, DSSpacing.lg)
            }
        }
    }
}

// MARK: - Previews (dados mockados do Titanic e Guardiões)

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

    static let songs = SoundtrackGroup(album: album, tracks: [
        .init(id: "5", title: "My Heart Will Go On (Love Theme from \"Titanic\")", artistName: "Céline Dion", duration: 311, previewURL: URL(string: "https://example.com/5.m4a"), song: nil),
    ])

    static let instrumental = SoundtrackGroup(album: album, tracks: [
        .init(id: "1", title: "Never an Absolution", artistName: "James Horner", duration: 183, previewURL: URL(string: "https://example.com/1.m4a"), song: nil),
        .init(id: "2", title: "Southampton", artistName: "James Horner", duration: 242, previewURL: URL(string: "https://example.com/2.m4a"), song: nil),
        .init(id: "3", title: "Rose", artistName: "James Horner", duration: 172, previewURL: nil, song: nil),
        .init(id: "4", title: "Hymn to the Sea", artistName: "James Horner", duration: 386, previewURL: URL(string: "https://example.com/4.m4a"), song: nil),
    ])

    static let about = "Composta por James Horner, a trilha de Titanic combina vocais célticos etéreos com orquestra sinfônica para acompanhar o romance e a tragédia do transatlântico. O álbum se tornou uma das trilhas sonoras mais vendidas de todos os tempos, impulsionado por \"My Heart Will Go On\", interpretada por Céline Dion."

    // Dois álbuns distintos (molde Guardiões da Galáxia).
    static let mixAlbum = SoundtrackCandidate(
        id: "901",
        title: "Guardians of the Galaxy: Awesome Mix Vol. 1",
        artistName: "Various Artists",
        releaseYear: 2014,
        trackCount: 2,
        artworkURL: nil,
        url: nil
    )

    static let scoreAlbum = SoundtrackCandidate(
        id: "902",
        title: "Guardians of the Galaxy (Original Score)",
        artistName: "Tyler Bates",
        releaseYear: 2014,
        trackCount: 2,
        artworkURL: nil,
        url: nil
    )

    static let mixSongs = SoundtrackGroup(album: mixAlbum, tracks: [
        .init(id: "10", title: "Hooked on a Feeling", artistName: "Blue Swede", duration: 173, previewURL: URL(string: "https://example.com/10.m4a"), song: nil),
        .init(id: "11", title: "Come and Get Your Love", artistName: "Redbone", duration: 205, previewURL: URL(string: "https://example.com/11.m4a"), song: nil),
    ])

    static let scoreTracks = SoundtrackGroup(album: scoreAlbum, tracks: [
        .init(id: "20", title: "Morag", artistName: "Tyler Bates", duration: 130, previewURL: URL(string: "https://example.com/20.m4a"), song: nil),
        .init(id: "21", title: "The Kyln", artistName: "Tyler Bates", duration: 154, previewURL: URL(string: "https://example.com/21.m4a"), song: nil),
    ])
}

#Preview("Assinante — tocando") {
    ScrollView {
        SoundtrackSection(
            about: SoundtrackPreviewData.about,
            songs: SoundtrackPreviewData.songs,
            instrumental: SoundtrackPreviewData.instrumental,
            mode: .fullPlayback,
            nowPlayingTrackID: "2",
            isPlaying: true,
            elapsed: 97,
            playbackDuration: 242,
            onPlayTrack: { _, _ in },
            onOpenInAppleMusic: { _ in }
        )
        .padding(.vertical, DSSpacing.lg)
    }
}

#Preview("Dois álbuns — canções + score") {
    ScrollView {
        SoundtrackSection(
            about: nil,
            songs: SoundtrackPreviewData.mixSongs,
            instrumental: SoundtrackPreviewData.scoreTracks,
            mode: .fullPlayback,
            nowPlayingTrackID: nil,
            isPlaying: false,
            elapsed: 0,
            playbackDuration: nil,
            onPlayTrack: { _, _ in },
            onOpenInAppleMusic: { _ in }
        )
        .padding(.vertical, DSSpacing.lg)
    }
}

#Preview("Sem assinatura — previews de 30s") {
    ScrollView {
        SoundtrackSection(
            about: SoundtrackPreviewData.about,
            songs: SoundtrackPreviewData.songs,
            instrumental: SoundtrackPreviewData.instrumental,
            mode: .previewOnly,
            nowPlayingTrackID: "1",
            isPlaying: true,
            elapsed: 12,
            playbackDuration: 30,
            onPlayTrack: { _, _ in },
            onOpenInAppleMusic: { _ in }
        )
        .padding(.vertical, DSSpacing.lg)
    }
}

#Preview("Sem IA — só instrumental (fileira única)") {
    ScrollView {
        SoundtrackSection(
            about: nil,
            songs: nil,
            instrumental: SoundtrackPreviewData.instrumental,
            mode: .fullPlayback,
            nowPlayingTrackID: nil,
            isPlaying: false,
            elapsed: 0,
            playbackDuration: nil,
            onPlayTrack: { _, _ in },
            onOpenInAppleMusic: { _ in }
        )
        .padding(.vertical, DSSpacing.lg)
    }
}

#Preview("Carregando") {
    ScrollView {
        SoundtrackLoadingSection()
            .padding(.vertical, DSSpacing.lg)
    }
}
