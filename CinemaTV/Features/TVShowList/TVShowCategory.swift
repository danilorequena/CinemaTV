//
//  TVShowCategory.swift
//  CinemaTV
//
//  Categorias das listas paginadas de séries exibidas no Discover.
//

import Foundation
import CinemaTVCore

enum TVShowCategory: String, Hashable {
    case airingToday
    case onTheAir
    case popular

    var endpoint: TMDBEndpoint {
        switch self {
        case .airingToday: .airingTodayTVShows
        case .onTheAir: .onTheAirTVShows
        case .popular: .popularTVShows
        }
    }

    var displayName: LocalizedStringResource {
        switch self {
        case .airingToday: "Airing Today"
        case .onTheAir: "On the Air"
        case .popular: "Popular"
        }
    }
}
