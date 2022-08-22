//
//  MoviesListService.swift
//  CinemaTV
//
//  Created by Danilo Requena on 23/02/22.
//

import Foundation

final class MoviesListService {
    private static let configuration: URLSessionConfiguration = {
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 40
        return config
    }()
    
    private static let session = URLSession(configuration: configuration)
    
    class func loadMovies<T: Decodable>(
        page: String,
        endPoint: MoviesEndpoint,
        complitionHandler: @escaping (Result<T, APIServiceError>) -> ()
    ) {
        guard let url = URL(string: Constants.baseUrl + endPoint.path()) else {
            return
        }
        
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        
        components?.queryItems = [
            URLQueryItem(name: "api_key", value: Constants.apikey),
            URLQueryItem(name: "language", value: Locale.preferredLanguages[0]),
            URLQueryItem(name: "region", value: Locale.current.regionCode),
            URLQueryItem(name: "include_adult", value: "false"),
            URLQueryItem(name: "include_video", value: "true"),
            URLQueryItem(name: "watch_region", value: Locale.current.regionCode),
            URLQueryItem(name: "page", value: page)
        ]
        var request = URLRequest(url: (components?.url)!)
        request.httpMethod = "GET"

        let dataTask = session.dataTask(with: request) { (data: Data?, response: URLResponse?, error: Error?) in
            if error == nil {
                guard let response = response as? HTTPURLResponse else {
                    complitionHandler(.failure(.noResponse))
                    print("No Error")
                    return
                }
                if response.statusCode == 200 {
                    guard let data = data else { return }
                    do {
                        let movies = try Utils.jsonDecoder.decode(T.self, from: data)
                        complitionHandler(.success(movies))
                        print("FetchOK")
                    } catch let jsonErr {
                        complitionHandler(.failure(.invalidJSON))
                        print("Error serializing json:", jsonErr)
                    }
                } else {
                    complitionHandler(.failure(.responseStatusCode(code: response.statusCode)))
                    print("Algo deu Errado no servidor dos Movies")
                }
            } else {
                complitionHandler(.failure(.taskError(error: error!)))
                print("Algo errado")
            }
        }
        dataTask.resume()
    }
}
