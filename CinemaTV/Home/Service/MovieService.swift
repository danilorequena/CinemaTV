//
//  MovieService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/03/22.
//

import Foundation

protocol MovieServiceProtocol: AnyObject {
    func fetchMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovie, MovieError>) -> ())
    func fetchDetail(from ID: Int, completion: @escaping (Result<DetailMoviesModel, MovieError>) -> ())
    func fetchCast(from endpoint: String, completion: @escaping (Result<CastModel, MovieError>) -> ())
    func fetchTrailer(from endpoint: String, completion: @escaping (Result<VideoModel, MovieError>) -> ())
}
