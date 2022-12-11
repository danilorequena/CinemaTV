//
//  MovieService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/03/22.
//

import Foundation

protocol MovieServiceProtocol: AnyObject {
    func fetchDiscoverMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovies, RequestError>) -> Void)
    func fetchTopMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<TopVotedMovies, RequestError>) -> Void)
    func fetchUpcomingMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<UpcomingMovies, RequestError>) -> Void)
    func fetchNowMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<NowPlayingMovies, RequestError>) -> Void)
    func fetchPopularMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<PopularMovies, RequestError>) -> Void)
    func fetchDetail(from endpoint: String, completion: @escaping (Result<DetailMoviesModel, RequestError>) -> ())
    func fetchTVShowDetail(from endpoint: String, completion: @escaping (Result<DetailTVShow, RequestError>) -> ())
    func fetchCast(from endpoint: String, completion: @escaping (Result<CastModel, RequestError>) -> Void)
    func fetchRecommendations(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovies, RequestError>) -> Void)
    func fetchSimilars(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovies, RequestError>) -> Void)
    func fetchTrailer(from endpoint: String, completion: @escaping (Result<VideoModel, RequestError>) -> Void)
    func fetchSearch(from endpoint: String, query: String, completion: @escaping (Result<SearchModel, RequestError>) -> Void)
    func fetchMultiSearch(from endpoint: String, query: String, completion: @escaping (Result<MultiSearch, RequestError>) -> Void)
    func fetchDetailWatchProviders(from endpoint: String, completion: @escaping (Result<WatchProviders, RequestError>) -> ())
}
