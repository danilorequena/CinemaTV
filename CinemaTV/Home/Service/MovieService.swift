//
//  MovieService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/03/22.
//

import Foundation

protocol MovieServiceProtocol: AnyObject {
    func fetchDiscoverMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovies, MovieError>) -> ())
    func fetchTopMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<TopVotedMovies, MovieError>) -> ())
    func fetchUpcomingMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<UpcomingMovies, MovieError>) -> ())
    func fetchNowMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<NowPlayingMovies, MovieError>) -> ())
    func fetchPopularMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<PopularMovies, MovieError>) -> ())
    func fetchDetail(from ID: Int, completion: @escaping (Result<DetailMoviesModel, MovieError>) -> ())
    func fetchCast(from endpoint: String, completion: @escaping (Result<CastModel, MovieError>) -> ())
    func fetchTrailer(from endpoint: String, completion: @escaping (Result<VideoModel, MovieError>) -> ())
}
