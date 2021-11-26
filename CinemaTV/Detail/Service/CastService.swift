//
//  CastService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 26/11/21.
//

import Foundation

final class CastService: ObservableObject {
    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 40
        return config
    }()
    
    private static let session = URLSession(configuration: configuration)
    
    class func loadCast(from endpoint: String) async throws -> Result<CastModel, APIServiceError> {
        
        let url = URL(string: Constants.baseUrl + endpoint)!
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Constants.apiKey)
        ]
        
        var request = URLRequest(url: (components?.url)!)
        request.httpMethod = "GET"
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            let result = try decoder.decode(CastModel.self, from: data)
            return .success(result)
        } catch {
            return .failure(.invalidJSON)
        }
    }
}

