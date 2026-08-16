//
//  DetailModelsDecodingTests.swift
//  CinemaTVKit
//
//  Decode dos campos novos das telas de detalhe (rodada "usar melhor a API").
//  O decoder replica o do TMDBClient (convertFromSnakeCase).
//

import Foundation
import Testing
@testable import CinemaTVCore

@Suite("Detail models decoding")
struct DetailModelsDecodingTests {
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }

    @Test func movieDecodesVoteCountAndTagline() throws {
        let json = Data("""
        {"id": 603, "title": "The Matrix", "vote_average": 8.2, "vote_count": 26214,
         "tagline": "The fight for the future begins.",
         "genres": [{"id": 28, "name": "Action"}, {"id": 878, "name": "Science Fiction"}]}
        """.utf8)
        let movie = try decoder.decode(MovieDetails.self, from: json)
        #expect(movie.voteCount == 26214)
        #expect(movie.tagline == "The fight for the future begins.")
        #expect(movie.genres?.count == 2)
    }

    @Test func creditsDecodeCrewAndStayValidWithoutIt() throws {
        let withCrew = Data("""
        {"id": 603, "cast": [], "crew": [
            {"id": 9339, "name": "Lana Wachowski", "job": "Director", "department": "Directing", "profile_path": null},
            {"id": 9340, "name": "Lilly Wachowski", "job": "Writer", "department": "Writing", "profile_path": null}
        ]}
        """.utf8)
        let credits = try decoder.decode(CreditsResponse.self, from: withCrew)
        #expect(credits.crew?.first?.job == "Director")
        #expect(credits.crew?.last?.department == "Writing")

        let withoutCrew = Data(#"{"id": 603, "cast": []}"#.utf8)
        let legacy = try decoder.decode(CreditsResponse.self, from: withoutCrew)
        #expect(legacy.crew == nil)
    }

    @Test func tvShowDecodesCreatorsNetworksAndNextEpisode() throws {
        let json = Data("""
        {"id": 1399, "name": "Game of Thrones", "tagline": "Winter is coming.",
         "vote_count": 21857,
         "created_by": [{"id": 9813, "name": "David Benioff"}],
         "networks": [{"id": 49, "name": "HBO", "logo_path": "/hbo.png"}],
         "next_episode_to_air": {"id": 999, "name": "The Long Night", "episode_number": 3,
                                 "season_number": 8, "air_date": "2026-09-01"}}
        """.utf8)
        let show = try decoder.decode(TVShowDetails.self, from: json)
        #expect(show.tagline == "Winter is coming.")
        #expect(show.voteCount == 21857)
        #expect(show.createdBy?.first?.name == "David Benioff")
        #expect(show.networks?.first?.name == "HBO")
        #expect(show.nextEpisodeToAir?.episodeNumber == 3)
        #expect(show.nextEpisodeToAir?.airDate == "2026-09-01")
    }

    @Test func seasonDecodesPosterAirDateAndEpisodeCredits() throws {
        let json = Data("""
        {"_id": "5256c89f19c2956ff6046d47", "name": "Season 1", "season_number": 1,
         "poster_path": "/season1.jpg", "air_date": "2011-04-17",
         "episodes": [
            {"id": 63056, "name": "Winter Is Coming", "episode_number": 1, "season_number": 1,
             "guest_stars": [{"id": 946696, "name": "Ian Whyte", "character": "White Walker",
                              "profile_path": null, "order": 46}],
             "crew": [{"id": 44797, "name": "Tim Van Patten", "job": "Director",
                       "department": "Directing", "profile_path": null}]}
         ]}
        """.utf8)
        let season = try decoder.decode(SeasonDetails.self, from: json)
        #expect(season.posterPath == "/season1.jpg")
        #expect(season.airYear == "2011")
        let episode = try #require(season.episodes.first)
        #expect(episode.guestStars?.first?.character == "White Walker")
        #expect(episode.crew?.first?.job == "Director")
    }

    @Test func personDecodesDeathday() throws {
        let json = Data("""
        {"id": 3084, "name": "Marlon Brando", "birthday": "1924-04-03",
         "deathday": "2004-07-01", "place_of_birth": "Omaha, Nebraska, USA"}
        """.utf8)
        let person = try decoder.decode(PersonDetails.self, from: json)
        #expect(person.deathday == "2004-07-01")
        #expect(person.birthday == "1924-04-03")
    }

    @Test func mediaItemDecodesCharacterFromCredits() throws {
        let json = Data("""
        {"id": 603, "title": "The Matrix", "character": "Neo",
         "release_date": "1999-03-31", "media_type": "movie"}
        """.utf8)
        let item = try decoder.decode(MediaItem.self, from: json)
        #expect(item.character == "Neo")

        let noCharacter = Data(#"{"id": 604, "title": "Reloaded"}"#.utf8)
        #expect(try decoder.decode(MediaItem.self, from: noCharacter).character == nil)
    }
}
