//
//  MovieStore.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/03/22.
//

import Foundation

final class MovieStore: MovieServiceProtocol {
    static let shared = MovieStore()
    
    private init() {}
    
    private let urlSession = URLSession.shared
    private let jsonDecoder = Utils.jsonDecoder
    
    func fetchMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovie, MovieError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        self.loadURLAndDecode(url: url, completion: completion)
    }
    
    private func loadURLAndDecode<D: Decodable>(url: URL, params: [String : String]? = nil, completion: @escaping (Result<D, MovieError>) -> ()) {
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        var queryItems = [URLQueryItem(name: "api_key", value: Constants.apiKey)]
        if let params = params {
            queryItems.append(contentsOf: params.map {URLQueryItem(name: $0.key, value: $0.value)})
        }
        
        urlComponents.queryItems = queryItems
        
        guard let finalURL = urlComponents.url else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        urlSession.dataTask(with: finalURL) { [weak self] data, response, error in
            guard let self = self else { return }
            if error != nil {
                self.executeCompletionHandler(with: .failure(.apiError), completion: completion)
                return
            }
            
            guard let response = response as? HTTPURLResponse, 200..<300 ~= response.statusCode else {
                self.executeCompletionHandler(with: .failure(.invalidResponse), completion: completion)
                return
            }
            
            guard let data = data else {
                self.executeCompletionHandler(with: .failure(.noData), completion: completion)
                return
            }
            
            do {
                let decodedResponse = try self.jsonDecoder.decode(D.self, from: data)
                self.executeCompletionHandler(with: .success(decodedResponse), completion: completion)
            } catch {
                self.executeCompletionHandler(with: .failure(.serializationError), completion: completion)
            }
        }.resume()
    }
    
    private func executeCompletionHandler<D: Decodable>(with result: Result<D, MovieError>, completion: @escaping (Result<D, MovieError>) -> ()) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
