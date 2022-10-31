//
//  TVShowService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/09/22.
//

import Foundation

protocol TVShowServiceProtocol: AnyObject {
    func fetchDiscoverTVShows(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> Void)
    func fetchPopTVShows(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> ())
    func fetchRecommendations(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> Void)
    func fetchSimilars(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> Void)
}
