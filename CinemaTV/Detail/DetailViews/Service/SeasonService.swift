//
//  SeasonService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import Foundation

final class SeasonService: Service {
    private let urlSession = URLSession.shared
    private let jsonDecoder = Utils.jsonDecoder
    
    func fetchSeasonDetail(from endpoint: TVShowsEndpoint, completion: @escaping (Result<SeasonModel, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
}
