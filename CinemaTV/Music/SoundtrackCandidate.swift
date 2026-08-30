//
//  SoundtrackCandidate.swift
//  CinemaTV
//
//  Espelho livre de MusicKit de um Album do catálogo: o ranking heurístico
//  e o prompt do agente trabalham só com isto (puros e testáveis). A ponte
//  com o framework mora no AppleMusicCatalog.
//

import Foundation

struct SoundtrackCandidate: Identifiable, Sendable, Equatable, Codable {
    /// MusicItemID.rawValue do álbum no catálogo do Apple Music.
    let id: String
    let title: String
    let artistName: String
    let releaseYear: Int?
    let trackCount: Int?
    /// URL de artwork já resolvida em tamanho fixo.
    let artworkURL: URL?
    /// Link do álbum no Apple Music (fallback "Open in Apple Music").
    let url: URL?
}
