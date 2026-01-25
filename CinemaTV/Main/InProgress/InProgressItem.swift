//
//  InProgressItem.swift
//  CinemaTV
//
//  Created by Danilo Requena on 25/01/26.
//

import Foundation

enum InProgressItemType {
    case tvShow(seasonNumber: Int, episodeNumber: Int, episodeName: String)
    case movie
}

struct InProgressItem: Identifiable {
    let id: String
    let tmdbId: Int
    let type: InProgressItemType
    let imageURL: URL?
    let title: String
    let subtitle: String
    let progress: Double?
    let lastUpdated: Date

    var episodeInfo: String? {
        if case .tvShow(let season, let episode, let name) = type {
            return "T\(season) E\(episode) - \(name)"
        }
        return nil
    }

    var isMovie: Bool {
        if case .movie = type {
            return true
        }
        return false
    }
}
