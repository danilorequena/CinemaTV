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
                backdropPath: "/2RSirqZG949GuRwN38MYCIGG4Od.jpg",
                genreIDS: [53],
                id: 985939,
                originalTitle: "Fall",
                overview: "For best friends Becky and Hunter, life is all about conquering fears and pushing limits. But after they climb 2,000 feet to the top of a remote, abandoned radio tower, they find themselves stranded with no way down. Now Becky and Hunter’s expert climbing skills will be put to the ultimate test as they desperately fight to survive the elements, a lack of supplies, and vertigo-inducing heights",
                popularity: 9320.962,
                posterPath: "9f5sIJEgvUpFv0ozfA6TurG4j22.jpg",
                releaseDate: "2022-08-11",
                title: "Fall",
                video: false,
                voteAverage: 7.4,
                voteCount: 658,
                name: "",
                originalName: ""
            ),
            MoviesTVShowResult(
                adult: false,
                backdropPath: "/2RSirqZG949GuRwN38MYCIGG4Od.jpg",
                genreIDS: [53],
                id: 985939,
                originalTitle: "Fall",
                overview: "For best friends Becky and Hunter, life is all about conquering fears and pushing limits. But after they climb 2,000 feet to the top of a remote, abandoned radio tower, they find themselves stranded with no way down. Now Becky and Hunter’s expert climbing skills will be put to the ultimate test as they desperately fight to survive the elements, a lack of supplies, and vertigo-inducing heights",
                popularity: 9320.962,
                posterPath: "9f5sIJEgvUpFv0ozfA6TurG4j22.jpg",
                releaseDate: "2022-08-11",
                title: "Fall",
                video: false,
                voteAverage: 7.4,
                voteCount: 658,
                name: "",
                originalName: ""
            ),
            MoviesTVShowResult(
                adult: false,
                backdropPath: "/2RSirqZG949GuRwN38MYCIGG4Od.jpg",
                genreIDS: [53],
                id: 985939,
                originalTitle: "Fall",
                overview: "For best friends Becky and Hunter, life is all about conquering fears and pushing limits. But after they climb 2,000 feet to the top of a remote, abandoned radio tower, they find themselves stranded with no way down. Now Becky and Hunter’s expert climbing skills will be put to the ultimate test as they desperately fight to survive the elements, a lack of supplies, and vertigo-inducing heights",
                popularity: 9320.962,
                posterPath: "9f5sIJEgvUpFv0ozfA6TurG4j22.jpg",
                releaseDate: "2022-08-11",
                title: "Fall",
                video: false,
                voteAverage: 7.4,
                voteCount: 658,
                name: "",
                originalName: ""
            )
        ]
    }
//    static var stubbedMovies: [MovieResult] {
//        let response: DiscoverMovies? = try? Bundle.main.loadAndDecodeJSON(fileName: "discover")
//        return response!.results
//    }
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
