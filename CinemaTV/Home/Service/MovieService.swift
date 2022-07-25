//
//  MovieService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/03/22.
//

import Foundation

protocol MovieServiceProtocol: AnyObject {
    func fetchDiscoverMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovies, MovieError>) -> Void)
    func fetchTopMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<TopVotedMovies, MovieError>) -> Void)
    func fetchUpcomingMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<UpcomingMovies, MovieError>) -> Void)
    func fetchNowMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<NowPlayingMovies, MovieError>) -> Void)
    func fetchPopularMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<PopularMovies, MovieError>) -> Void)
    func fetchDetail(from ID: Int, completion: @escaping (Result<DetailMoviesModel, MovieError>) -> Void)
    func fetchCast(from endpoint: String, completion: @escaping (Result<CastModel, MovieError>) -> Void)
    func fetchTrailer(from endpoint: String, completion: @escaping (Result<VideoModel, MovieError>) -> Void)
    func fetchSearch(from endpoint: String, query: String, completion: @escaping (Result<SearchModel, MovieError>) -> Void)
}
