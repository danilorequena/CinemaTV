//
//  TMDBEndpoint.swift
//  CinemaTVKit
//
//  Unifica os antigos MoviesEndpoint e TVShowsEndpoint. Os casos de TV já
//  existem para a V2, mas só a área de Movies os consome na V1.
//

import Foundation

public enum TMDBEndpoint: Equatable, Sendable {
    // MARK: Movies
    case discoverMovies
    case upcomingMovies
    case nowPlayingMovies
    case popularMovies
    case topRatedMovies
    case movieDetail(id: Int)
    case movieCredits(id: Int)
    case movieVideos(id: Int)
    case movieRecommendations(id: Int)
    case similarMovies(id: Int)
    case movieWatchProviders(id: Int)
    case searchMovies
    case multiSearch

    // MARK: Trending (sugestões da busca: filmes + séries + pessoas)
    case trendingAll

    // MARK: People
    case person(id: Int)
    case personCredits(id: Int)

    // MARK: TV Shows (V2)
    case discoverTVShows
    case airingTodayTVShows
    case onTheAirTVShows
    case popularTVShows
    case tvShowDetail(id: Int)
    case tvShowSeason(id: Int, season: Int)
    case tvShowCredits(id: Int)
    case tvShowVideos(id: Int)
    case tvShowWatchProviders(id: Int)
    case tvShowRecommendations(id: Int)
    case similarTVShows(id: Int)
    case searchTVShows

    public var path: String {
        switch self {
        case .discoverMovies: "discover/movie"
        case .upcomingMovies: "movie/upcoming"
        case .nowPlayingMovies: "movie/now_playing"
        case .popularMovies: "movie/popular"
        case .topRatedMovies: "movie/top_rated"
        case .movieDetail(let id): "movie/\(id)"
        case .movieCredits(let id): "movie/\(id)/credits"
        case .movieVideos(let id): "movie/\(id)/videos"
        case .movieRecommendations(let id): "movie/\(id)/recommendations"
        case .similarMovies(let id): "movie/\(id)/similar"
        case .movieWatchProviders(let id): "movie/\(id)/watch/providers"
        case .searchMovies: "search/movie"
        case .multiSearch: "search/multi"
        case .trendingAll: "trending/all/week"
        case .person(let id): "person/\(id)"
        case .personCredits(let id): "person/\(id)/combined_credits"
        case .discoverTVShows: "discover/tv"
        case .airingTodayTVShows: "tv/airing_today"
        case .onTheAirTVShows: "tv/on_the_air"
        case .popularTVShows: "tv/popular"
        case .tvShowDetail(let id): "tv/\(id)"
        case .tvShowSeason(let id, let season): "tv/\(id)/season/\(season)"
        case .tvShowCredits(let id): "tv/\(id)/credits"
        case .tvShowVideos(let id): "tv/\(id)/videos"
        case .tvShowWatchProviders(let id): "tv/\(id)/watch/providers"
        case .tvShowRecommendations(let id): "tv/\(id)/recommendations"
        case .similarTVShows(let id): "tv/\(id)/similar"
        case .searchTVShows: "search/tv"
        }
    }
}
