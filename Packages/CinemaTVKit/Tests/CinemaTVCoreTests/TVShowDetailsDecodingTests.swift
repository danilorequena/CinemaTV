//
//  TVShowDetailsDecodingTests.swift
//  CinemaTVKit
//

import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct TVShowDetailsDecodingTests {
    private func decode<T: Decodable>(_ json: String, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: Data(json.utf8))
    }

    @Test func decodesShowDetailPayload() throws {
        let json = """
        {
            "id": 1399,
            "name": "Game of Thrones",
            "overview": "Seven noble families...",
            "poster_path": "/got.jpg",
            "backdrop_path": "/got-back.jpg",
            "first_air_date": "2011-04-17",
            "number_of_seasons": 8,
            "number_of_episodes": 73,
            "vote_average": 8.4,
            "status": "Ended",
            "genres": [{"id": 10765, "name": "Sci-Fi & Fantasy"}],
            "seasons": [
                {
                    "id": 3624,
                    "name": "Season 1",
                    "overview": "Winter is coming.",
                    "poster_path": "/s1.jpg",
                    "season_number": 1,
                    "episode_count": 10,
                    "air_date": "2011-04-17"
                },
                {
                    "id": 3627,
                    "name": "Specials",
                    "overview": null,
                    "poster_path": null,
                    "season_number": 0,
                    "episode_count": 55,
                    "air_date": "2010-12-05"
                }
            ]
        }
        """
        let show = try decode(json, as: TVShowDetails.self)
        #expect(show.id == 1399)
        #expect(show.numberOfSeasons == 8)
        #expect(show.numberOfEpisodes == 73)
        #expect(show.status == "Ended")
        #expect(show.genres?.first?.name == "Sci-Fi & Fantasy")
        #expect(show.seasons?.count == 2)
        #expect(show.seasons?.first?.episodeCount == 10)
        #expect(show.mediaItem.mediaType == .tvShow)
        #expect(show.mediaItem.title == "Game of Thrones")
    }

    @Test func decodesSeasonDetailPayload() throws {
        let json = """
        {
            "_id": "5256c89f19c2956ff6046d47",
            "id": 3624,
            "name": "Season 1",
            "overview": "Winter is coming.",
            "season_number": 1,
            "episodes": [
                {
                    "id": 63056,
                    "name": "Winter Is Coming",
                    "overview": "Jon Arryn is dead.",
                    "episode_number": 1,
                    "season_number": 1,
                    "air_date": "2011-04-17",
                    "runtime": 62,
                    "still_path": "/e1.jpg",
                    "vote_average": 8.0
                },
                {
                    "id": 63057,
                    "name": "The Kingsroad",
                    "overview": null,
                    "episode_number": 2,
                    "season_number": 1,
                    "air_date": null,
                    "runtime": null,
                    "still_path": null,
                    "vote_average": null
                }
            ]
        }
        """
        let season = try decode(json, as: SeasonDetails.self)
        #expect(season.id == "5256c89f19c2956ff6046d47")
        #expect(season.seasonNumber == 1)
        #expect(season.episodes.count == 2)

        let first = try #require(season.episodes.first)
        #expect(first.episodeNumber == 1)
        #expect(first.airDate == "2011-04-17")
        #expect(first.formattedRuntime != nil)
        #expect(first.stillURL?.absoluteString.hasSuffix("/e1.jpg") == true)

        let second = try #require(season.episodes.last)
        #expect(second.airDate == nil)
        #expect(second.formattedRuntime == nil)
    }
}
