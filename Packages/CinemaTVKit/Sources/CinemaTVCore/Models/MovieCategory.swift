//
//  MovieCategory.swift
//  CinemaTVKit
//
//  Categorias de listagem de filmes — usadas por rotas, telas, App Intents
//  e configuração de widget.
//

import Foundation

public enum MovieCategory: String, CaseIterable, Hashable, Sendable, Codable {
    case nowPlaying
    case upcoming
    case popular
    case topRated
    case discover

    public var endpoint: TMDBEndpoint {
        switch self {
        case .nowPlaying: .nowPlayingMovies
        case .upcoming: .upcomingMovies
        case .popular: .popularMovies
        case .topRated: .topRatedMovies
        case .discover: .discoverMovies
        }
    }

    public var displayName: LocalizedStringResource {
        // O bundle do módulo é necessário: LocalizedStringResource resolve em
        // Bundle.main por padrão, mas estas strings vivem no catálogo do package.
        switch self {
        case .nowPlaying: LocalizedStringResource("Now Playing", bundle: .atURL(Bundle.module.bundleURL))
        case .upcoming: LocalizedStringResource("Upcoming", bundle: .atURL(Bundle.module.bundleURL))
        case .popular: LocalizedStringResource("Popular", bundle: .atURL(Bundle.module.bundleURL))
        case .topRated: LocalizedStringResource("Top Rated", bundle: .atURL(Bundle.module.bundleURL))
        case .discover: LocalizedStringResource("Discover", bundle: .atURL(Bundle.module.bundleURL))
        }
    }
}
