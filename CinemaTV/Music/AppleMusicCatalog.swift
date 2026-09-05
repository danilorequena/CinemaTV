//
//  AppleMusicCatalog.swift
//  CinemaTV
//
//  Ponte com o MusicKit no molde do TMDBClient: struct Sendable + typed
//  throws. Busca álbuns no catálogo e hidrata um álbum com as faixas.
//

import Foundation
import MusicKit

enum AppleMusicError: Error, Sendable {
    case notAuthorized
    case albumNotFound
    case searchFailed(description: String)
}

extension AppleMusicError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notAuthorized:
            String(localized: "CinemaTV doesn't have access to Apple Music.")
        case .albumNotFound:
            String(localized: "Album not found in the Apple Music catalog.")
        case .searchFailed(let description):
            description
        }
    }
}

/// Álbum hidratado para UI e playback. Mantém os valores do MusicKit
/// (Album/Song) porque o ApplicationMusicPlayer consome os itens reais.
struct SoundtrackAlbum: Sendable {
    let candidate: SoundtrackCandidate
    let album: Album
    let tracks: [SoundtrackTrack]
}

struct SoundtrackTrack: Identifiable, Sendable {
    let id: String
    let title: String
    let artistName: String
    let duration: TimeInterval?
    /// Preview de ~30s tocável sem assinatura (AVPlayer).
    let previewURL: URL?
    /// Item real para a queue do player no modo assinante.
    let song: Song?
    /// Álbum de origem — contexto para o modelo julgar se a canção
    /// pertence ao título (fallback de canções avulsas).
    var albumTitle: String? = nil
}

struct AppleMusicCatalog: Sendable {
    init() {}

    /// Pede consentimento uma única vez; depois só reflete o status.
    func requestAuthorizationIfNeeded() async -> Bool {
        switch MusicAuthorization.currentStatus {
        case .authorized:
            return true
        case .notDetermined:
            return await MusicAuthorization.request() == .authorized
        default:
            return false
        }
    }

    /// Storefront do usuário (invalida cache quando muda de país).
    func currentStorefront() async -> String? {
        try? await MusicDataRequest.currentCountryCode
    }

    func searchAlbums(term: String, limit: Int = 10) async throws(AppleMusicError) -> [SoundtrackCandidate] {
        guard MusicAuthorization.currentStatus == .authorized else {
            throw AppleMusicError.notAuthorized
        }
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Album.self])
            request.limit = limit
            let response = try await request.response()
            return response.albums.map(Self.candidate(from:))
        } catch {
            throw AppleMusicError.searchFailed(description: String(describing: error))
        }
    }

    func album(id: String) async throws(AppleMusicError) -> SoundtrackAlbum {
        guard MusicAuthorization.currentStatus == .authorized else {
            throw AppleMusicError.notAuthorized
        }
        do {
            let request = MusicCatalogResourceRequest<Album>(matching: \.id, equalTo: MusicItemID(id))
            let response = try await request.response()
            guard let album = response.items.first else {
                throw AppleMusicError.albumNotFound
            }
            let detailed = try await album.with([.tracks])
            let tracks = (detailed.tracks ?? []).map(Self.track(from:))
            return SoundtrackAlbum(
                candidate: Self.candidate(from: detailed),
                album: detailed,
                tracks: tracks
            )
        } catch let error as AppleMusicError {
            throw error
        } catch {
            throw AppleMusicError.searchFailed(description: String(describing: error))
        }
    }

    /// Busca canções avulsas no catálogo — fallback quando o título não
    /// tem álbum de canções no Apple Music (caso Awesome Mix, removido do
    /// catálogo) mas as canções originais continuam lá.
    func searchSongs(term: String, limit: Int = 5) async throws(AppleMusicError) -> [SoundtrackTrack] {
        guard MusicAuthorization.currentStatus == .authorized else {
            throw AppleMusicError.notAuthorized
        }
        do {
            var request = MusicCatalogSearchRequest(term: term, types: [Song.self])
            request.limit = limit
            let response = try await request.response()
            return response.songs.map(Self.track(from:))
        } catch {
            throw AppleMusicError.searchFailed(description: String(describing: error))
        }
    }

    /// Hidrata canções avulsas por id preservando a ordem pedida (cache
    /// hit do fallback de canções).
    func songs(ids: [String]) async throws(AppleMusicError) -> [SoundtrackTrack] {
        guard MusicAuthorization.currentStatus == .authorized else {
            throw AppleMusicError.notAuthorized
        }
        do {
            let request = MusicCatalogResourceRequest<Song>(matching: \.id, memberOf: ids.map { MusicItemID($0) })
            let response = try await request.response()
            var byID: [String: Song] = [:]
            for song in response.items where byID[song.id.rawValue] == nil {
                byID[song.id.rawValue] = song
            }
            return ids.compactMap { byID[$0] }.map(Self.track(from:))
        } catch {
            throw AppleMusicError.searchFailed(description: String(describing: error))
        }
    }

    // MARK: - Mapeamento framework → domínio

    private static func candidate(from album: Album) -> SoundtrackCandidate {
        SoundtrackCandidate(
            id: album.id.rawValue,
            title: album.title,
            artistName: album.artistName,
            releaseYear: album.releaseDate.map { Calendar.current.component(.year, from: $0) },
            trackCount: album.trackCount,
            artworkURL: album.artwork?.url(width: 600, height: 600),
            url: album.url
        )
    }

    private static func track(from song: Song) -> SoundtrackTrack {
        SoundtrackTrack(
            id: song.id.rawValue,
            title: song.title,
            artistName: song.artistName,
            duration: song.duration,
            previewURL: song.previewAssets?.first?.url,
            song: song,
            albumTitle: song.albumTitle
        )
    }

    private static func track(from track: Track) -> SoundtrackTrack {
        switch track {
        case .song(let song):
            SoundtrackTrack(
                id: song.id.rawValue,
                title: song.title,
                artistName: song.artistName,
                duration: song.duration,
                previewURL: song.previewAssets?.first?.url,
                song: song
            )
        default:
            SoundtrackTrack(
                id: track.id.rawValue,
                title: track.title,
                artistName: track.artistName,
                duration: nil,
                previewURL: nil,
                song: nil
            )
        }
    }
}
