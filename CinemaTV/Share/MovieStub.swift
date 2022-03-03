//
//  MovieStub.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

extension MoviesResult {
    static var stubbedMovies: [MoviesResult] {
        let response: DiscoverMovie? = try? Bundle.main.loadAndDecodeJSON(fileName: "discover")
        return response!.results
    }
}

extension Bundle {
    func loadAndDecodeJSON<D: Decodable>(fileName: String) throws -> D? {
        guard let url =  self.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        let data = try Data(contentsOf: url)
        let jsonDecoder = JSONDecoder()
        let decodedModel = try jsonDecoder.decode(D.self, from: data)
        return decodedModel
    }
}
