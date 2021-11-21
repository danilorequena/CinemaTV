//
//  MoviesRequest.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

final class MoviesService: ObservableObject {
    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 40
        return config
    }()
    
    private static let session = URLSession(configuration: configuration)
    
    class func newloadMovies(from endpoint: String) async throws -> Result<Movie, APIServiceError> {
        
        let url = URL(string: Constants.baseUrl + endpoint)!
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Constants.apiKey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0]),
            URLQueryItem(name: "region", value: Locale.current.regionCode),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "true"),
            URLQueryItem(name: "watch_region", value: Locale.current.regionCode),
            URLQueryItem(name: "page", value: "1")
        ]
        
        var request = URLRequest(url: (components?.url)!)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let result = try decoder.decode(Movie.self, from: data)
            return .success(result)
        } catch {
            return .failure(.invalidJSON)
        }
    }
    
    class func loadDetail(from endpoint: String) async throws -> Result<DetailMoviesModel, APIServiceError> {
        
        let url = URL(string: Constants.baseUrl + endpoint)!
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Constants.apiKey),
            URLQueryItem(name: "language", value: "pt-BR"),
            URLQueryItem(name: "region", value: Locale.current.regionCode),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "true"),
            URLQueryItem(name: "watch_region", value: Locale.current.regionCode),
            URLQueryItem(name: "page", value: "1")
        ]
        
        var request = URLRequest(url: (components?.url)!)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let result = try decoder.decode(DetailMoviesModel.self, from: data)
            return .success(result)
        } catch {
            return .failure(.invalidJSON)
        }
    }
}

