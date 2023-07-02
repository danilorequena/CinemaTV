//
//  TVShowStore.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/09/22.
//

import Foundation

final class TVShowStore: TVShowServiceProtocol {
    static let shared = TVShowStore()
    
    init() {}
    
    private let urlSession = URLSession.shared
    private let jsonDecoder = Utils.jsonDecoder
    
    func fetchDiscoverTVShows(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchPopTVShows(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchRecommendations(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> Void) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchSimilars(from endpoint: TVShowsEndpoint, completion: @escaping (Result<DiscoverTVShow, RequestError>) -> Void) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    private func loadURLAndDecode<D: Decodable>(url: URL, params: [String : String]? = nil, completion: @escaping (Result<D, RequestError>) -> ()) {
        guard let language = Locale.current.language.languageCode?.identifier else { return }
        guard let region = Locale.current.language.region?.identifier else { return }
        guard var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        var queryItems = [
            URLQueryItem(name: "api_key", value: Constants.apikey),
            URLQueryItem(name: "language", value: "\(language)-\(region)"),
            URLQueryItem(name: "timezone", value: region),
            URLQueryItem(name: "with_origin_country", value: "US"),
            URLQueryItem(name: "include_adult", value: "false")
        ]
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
    
    private func executeCompletionHandler<D: Decodable>(with result: Result<D, RequestError>, completion: @escaping (Result<D, RequestError>) -> ()) {
        DispatchQueue.main.async {
            completion(result)
        }
    }
}
