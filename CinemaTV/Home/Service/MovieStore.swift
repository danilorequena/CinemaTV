//
//  MovieStore.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/03/22.
//

import Foundation

final class MovieStore: MovieServiceProtocol {
    static let shared = MovieStore()
    
    init() {}
    
    private let urlSession = URLSession.shared
    private let jsonDecoder = Utils.jsonDecoder
    
    func fetchDiscoverMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovies, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchUpcomingMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<UpcomingMovies, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchTopMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<TopVotedMovies, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchNowMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<NowPlayingMovies, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchPopularMovies(from endpoint: MoviesEndpoint, completion: @escaping (Result<PopularMovies, RequestError>) -> ()) {
        guard let url = URL(string: "\(Constants.baseUrl)\(endpoint.path())") else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchDetail(from endpoint: String, completion: @escaping (Result<DetailMoviesModel, RequestError>) -> ()) {
        guard let url = URL(string: Constants.baseUrl + endpoint) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchTVShowDetail(from endpoint: String, completion: @escaping (Result<DetailTVShow, RequestError>) -> ()) {
        guard let url = URL(string: Constants.baseUrl + endpoint) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchCast(from endpoint: String, completion: @escaping (Result<CastModel, RequestError>) -> ()) {
        guard let url = URL(string: Constants.baseUrl + endpoint) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchRecommendations(from endpoint: MoviesEndpoint, completion: @escaping (Result<DiscoverMovies, RequestError>) -> Void) {
        guard let url = URL(string: Constants.baseUrl + endpoint.path()) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchTrailer(from endpoint: String, completion: @escaping (Result<VideoModel, RequestError>) -> ()) {
        guard let url = URL(string: Constants.baseUrl + endpoint) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        
        loadURLAndDecode(url: url, completion: completion)
    }
    
    func fetchSearch(from endpoint: String, query: String, completion: @escaping (Result<SearchModel, RequestError>) -> Void) {
        guard let url = URL(string: Constants.baseUrl + endpoint) else {
            completion(.failure(.invalidEndpoint))
            return
        }
        let queryItem = ["query" : query]
        
        loadURLAndDecode(url: url, params: queryItem, completion: completion)
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
            URLQueryItem(name: "region", value: region),
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
