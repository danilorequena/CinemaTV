//
//  MovieStub.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

extension MoviesTVShowResult {
    static func stubbedMovies() -> [MoviesTVShowResult] {
        [
            MoviesTVShowResult(
                adult: false,
                backdropPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                genreIDS: [1,2,3],
                id: 200,
                originalTitle: "Steve Jobs",
                overview: "Steve Jobs",
                popularity: 1.0,
                posterPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                releaseDate: "02/02/2023",
                title: "Steve Jobs",
                video: true,
                voteAverage: 2.2,
                voteCount: 2,
                name: "Steve Jobs",
                originalName: "Steve Jobs"
            ),
            MoviesTVShowResult(
                adult: false,
                backdropPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                genreIDS: [1,2,3],
                id: 200,
                originalTitle: "Steve Jobs",
                overview: "Steve Jobs",
                popularity: 1.0,
                posterPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                releaseDate: "02/02/2023",
                title: "Steve Jobs",
                video: true,
                voteAverage: 2.2,
                voteCount: 2,
                name: "Steve Jobs",
                originalName: "Steve Jobs"
            ),
            MoviesTVShowResult(
                adult: false,
                backdropPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                genreIDS: [1,2,3],
                id: 200,
                originalTitle: "Steve Jobs",
                overview: "Steve Jobs",
                popularity: 1.0,
                posterPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                releaseDate: "02/02/2023",
                title: "Steve Jobs",
                video: true,
                voteAverage: 2.2,
                voteCount: 2,
                name: "Steve Jobs",
                originalName: "Steve Jobs"
            ),
            MoviesTVShowResult(
                adult: false,
                backdropPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                genreIDS: [1,2,3],
                id: 200,
                originalTitle: "Steve Jobs",
                overview: "Steve Jobs",
                popularity: 1.0,
                posterPath: "/7gKI9hpEMcZUQpNgKrkDzJpbnNS.jpg",
                releaseDate: "02/02/2023",
                title: "Steve Jobs",
                video: true,
                voteAverage: 2.2,
                voteCount: 2,
                name: "Steve Jobs",
                originalName: "Steve Jobs"
            )
        ]
    }
    static var stubbedJsonsMovies: [MoviesTVShowResult] {
        let response: DiscoverMovies? = try? Bundle.main.loadAndDecodeJSON(fileName: "discover")
        return response!.results
    }
}

extension Bundle {
    func loadAndDecodeJSON<D: Decodable>(fileName: String) throws -> D? {
        guard let url =  self.url(forResource: fileName, withExtension: "json") else {
            return nil
        }
        let data = try Data(contentsOf: url)
        let jsonDecoder = Utils.jsonDecoder
        let decodedModel = try jsonDecoder.decode(D.self, from: data)
        return decodedModel
    }
}
