//
//  LibraryRefresher.swift
//  CinemaTV
//
//  Refresh silencioso da Library: no máximo 1x/dia, revalida o
//  next_episode_to_air/status das séries seguidas (via refreshMetadata) e
//  as datas de estreia dos filmes da fila. Falha/offline é silencioso —
//  o cache atual continua valendo.
//

import Foundation
import SwiftData
import CinemaTVCore

@MainActor
enum LibraryRefresher {
    private static let throttleKey = "libraryRefreshedAt"
    /// ~1x/dia, com folga para o usuário que abre sempre no mesmo horário.
    private static let throttleInterval: TimeInterval = 20 * 3600

    static func refreshIfNeeded(client: TMDBClient, context: ModelContext) async {
        if let last = UserDefaults.standard.object(forKey: throttleKey) as? Date,
           Date.now.timeIntervalSince(last) < throttleInterval {
            return
        }

        let tracking = TVShowTrackingStore(context: context)
        let watchlist = WatchlistStore(context: context)

        // Séries seguidas: o refreshMetadata reconcilia temporadas e grava
        // upcoming*/status — a agenda e a promoção Watching↔Watched ficam
        // corretas sem depender de visita ao detalhe.
        for show in (try? tracking.watchingShows()) ?? [] {
            guard let showID = show.id else { continue }
            guard let details: TVShowDetails = try? await client.fetch(.tvShowDetail(id: showID)) else {
                continue
            }
            try? tracking.refreshMetadata(from: details)
        }

        // Filmes da fila: revalida a data de quem ainda não estreou (datas
        // mudam) ou nunca teve data gravada (itens legados).
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = .gmt
        let today = gmtCalendar.startOfDay(for: .now)

        for movie in (try? watchlist.moviesToWatch()) ?? [] {
            guard let movieID = movie.id else { continue }
            let releaseDate = movie.releaseDate.flatMap {
                try? Date($0, strategy: .iso8601.year().month().day())
            }
            let needsRefresh = releaseDate.map { $0 >= today } ?? true
            guard needsRefresh else { continue }
            guard let details: MovieDetails = try? await client.fetch(.movieDetail(id: Int(movieID))) else {
                continue
            }
            try? watchlist.updateReleaseDate(movieID: Int(movieID), releaseDate: details.releaseDate)
        }

        UserDefaults.standard.set(Date.now, forKey: throttleKey)
    }

    #if DEBUG
    /// Testes/depuração: zera o throttle.
    static func resetThrottle() {
        UserDefaults.standard.removeObject(forKey: throttleKey)
    }
    #endif
}
