//
//  SoundtrackPlayerModel.swift
//  CinemaTV
//
//  Reprodução da trilha: assinantes tocam faixas completas via
//  ApplicationMusicPlayer; sem assinatura, previews de ~30s num AVPlayer
//  privado. O preview morre com a tela; o player do sistema continua
//  (comportamento padrão do MusicKit).
//

import Foundation
import MusicKit
import AVFoundation
import Observation

@MainActor
@Observable
final class SoundtrackPlayerModel {
    enum PlaybackMode: Equatable {
        case undetermined
        case fullPlayback
        case previewOnly
    }

    private(set) var mode: PlaybackMode = .undetermined
    private(set) var nowPlayingTrackID: String?
    private(set) var isPlaying = false
    /// Posição atual da faixa em segundos (atualizada a ~2Hz enquanto toca).
    private(set) var elapsed: TimeInterval = 0
    /// Duração do que está tocando de fato: a faixa completa no modo
    /// assinante, ou os ~30s do preview (a duração da faixa enganaria).
    private(set) var playbackDuration: TimeInterval?

    @ObservationIgnored private var previewPlayer: AVPlayer?
    @ObservationIgnored private var previewEndObserver: (any NSObjectProtocol)?
    @ObservationIgnored private var progressTask: Task<Void, Never>?
    /// true quando a faixa atual toca no ApplicationMusicPlayer.
    @ObservationIgnored private var usingSystemPlayer = false

    func determineMode() async {
        let subscription = try? await MusicSubscription.current
        mode = (subscription?.canPlayCatalogContent ?? false) ? .fullPlayback : .previewOnly
    }

    func togglePlay(track: SoundtrackTrack, in album: SoundtrackAlbum) async {
        if nowPlayingTrackID == track.id {
            isPlaying ? pause() : await resume()
            return
        }
        switch mode {
        case .fullPlayback:
            await playFull(track: track, in: album)
        case .previewOnly, .undetermined:
            playPreview(track: track)
        }
    }

    /// Chamado no onDisappear da tela: encerra o preview local.
    func stop() {
        stopPreview()
        stopProgressPolling()
        if !usingSystemPlayer {
            nowPlayingTrackID = nil
            isPlaying = false
            elapsed = 0
            playbackDuration = nil
        }
    }

    // MARK: - Assinante (faixa completa)

    private func playFull(track: SoundtrackTrack, in album: SoundtrackAlbum) async {
        guard let song = track.song else {
            playPreview(track: track)
            return
        }
        stopPreview()
        let player = ApplicationMusicPlayer.shared
        let songs = album.tracks.compactMap(\.song)
        player.queue = ApplicationMusicPlayer.Queue(for: songs, startingAt: song)
        do {
            try await player.play()
            usingSystemPlayer = true
            nowPlayingTrackID = track.id
            isPlaying = true
            elapsed = 0
            playbackDuration = track.duration
            startProgressPolling()
        } catch {
            // Sem playback completo (ex.: restrições da conta): preview.
            playPreview(track: track)
        }
    }

    // MARK: - Preview (30s, sem assinatura)

    private func playPreview(track: SoundtrackTrack) {
        guard let url = track.previewURL else { return }
        stopPreview()
        if usingSystemPlayer {
            ApplicationMusicPlayer.shared.pause()
            usingSystemPlayer = false
        }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)

        let item = AVPlayerItem(url: url)
        let player = AVPlayer(playerItem: item)
        previewEndObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: item,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.previewDidFinish()
            }
        }
        previewPlayer = player
        player.play()
        nowPlayingTrackID = track.id
        isPlaying = true
        elapsed = 0
        // Duração real do preview (~30s) chega no polling quando o item
        // carrega; a duração da faixa completa aqui seria mentirosa.
        playbackDuration = nil
        startProgressPolling()
    }

    private func previewDidFinish() {
        stopPreview()
        stopProgressPolling()
        nowPlayingTrackID = nil
        isPlaying = false
        elapsed = 0
        playbackDuration = nil
    }

    private func stopPreview() {
        previewPlayer?.pause()
        previewPlayer = nil
        if let previewEndObserver {
            NotificationCenter.default.removeObserver(previewEndObserver)
            self.previewEndObserver = nil
        }
    }

    // MARK: - Pause/resume da faixa corrente

    private func pause() {
        if usingSystemPlayer {
            ApplicationMusicPlayer.shared.pause()
        } else {
            previewPlayer?.pause()
        }
        isPlaying = false
        stopProgressPolling()
    }

    private func resume() async {
        if usingSystemPlayer {
            try? await ApplicationMusicPlayer.shared.play()
        } else if let previewPlayer {
            previewPlayer.play()
        } else {
            return
        }
        isPlaying = true
        startProgressPolling()
    }

    // MARK: - Progresso (posição a ~2Hz enquanto toca)

    private func startProgressPolling() {
        progressTask?.cancel()
        progressTask = Task { [weak self] in
            while let self, !Task.isCancelled, self.isPlaying {
                self.refreshProgress()
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func stopProgressPolling() {
        progressTask?.cancel()
        progressTask = nil
    }

    private func refreshProgress() {
        if usingSystemPlayer {
            elapsed = ApplicationMusicPlayer.shared.playbackTime
        } else if let previewPlayer {
            let time = previewPlayer.currentTime().seconds
            elapsed = time.isFinite ? max(time, 0) : 0
            if playbackDuration == nil, let item = previewPlayer.currentItem {
                let duration = item.duration.seconds
                if duration.isFinite, duration > 0 {
                    playbackDuration = duration
                }
            }
        }
    }
}
