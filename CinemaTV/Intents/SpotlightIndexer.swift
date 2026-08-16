//
//  SpotlightIndexer.swift
//  CinemaTV
//
//  Mantém o índice do Spotlight alinhado com a watchlist. Taps no Spotlight
//  resolvem via MovieEntity → OpenMovieIntent.
//

import Foundation
import CoreSpotlight
import CinemaTVCore

enum SpotlightIndexer {
    static func index(_ entity: MovieEntity) {
        Task {
            try? await CSSearchableIndex.default().indexAppEntities([entity])
        }
    }

    static func index(_ item: MediaItem) {
        index(MovieEntity(item: item))
    }

    static func deindex(movieID: Int) {
        Task {
            try? await CSSearchableIndex.default().deleteAppEntities(
                identifiedBy: [movieID],
                ofType: MovieEntity.self
            )
        }
    }
}
