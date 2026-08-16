//
//  MediaItemDecodingTests.swift
//  CinemaTVKit
//

import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct MediaItemDecodingTests {
    private func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: Data(json.utf8))
    }

    @Test func decodesMoviePayload() throws {
        let json = """
        {
            "id": 603,
            "title": "The Matrix",
            "overview": "A hacker...",
            "poster_path": "/matrix.jpg",
            "backdrop_path": "/matrix-back.jpg",
            "vote_average": 8.2,
            "release_date": "1999-03-31"
        }
        """
        let item = try decode(json, as: MediaItem.self)
        #expect(item.id == 603)
        #expect(item.title == "The Matrix")
        #expect(item.mediaType == .movie)
        #expect(item.releaseYear == "1999")
        #expect(item.posterURL?.absoluteString == "https://image.tmdb.org/t/p/w500/matrix.jpg")
    }

    @Test func decodesTVShowPayload() throws {
        let json = """
        {
            "id": 1399,
            "name": "Game of Thrones",
            "overview": "Seven noble families...",
            "poster_path": "/got.jpg",
            "vote_average": 8.4,
            "first_air_date": "2011-04-17"
        }
        """
        let item = try decode(json, as: MediaItem.self)
        #expect(item.title == "Game of Thrones")
        #expect(item.mediaType == .tvShow)
        #expect(item.releaseYear == "2011")
    }

    @Test func decodesMultiSearchWithExplicitMediaType() throws {
        let json = """
        {
            "id": 31,
            "name": "Tom Hanks",
            "profile_path": "/hanks.jpg",
            "media_type": "person"
        }
        """
        let item = try decode(json, as: MediaItem.self)
        #expect(item.mediaType == .person)
        #expect(item.posterPath == "/hanks.jpg")
    }

    @Test func decodesPagedResponse() throws {
        let json = """
        {
            "page": 1,
            "results": [{"id": 1, "title": "A", "vote_average": 5.0}],
            "total_pages": 3,
            "total_results": 60
        }
        """
        let page = try decode(json, as: PagedResponse<MediaItem>.self)
        #expect(page.results.count == 1)
        #expect(page.hasMorePages)
    }
}
