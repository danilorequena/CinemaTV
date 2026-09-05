import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct TraktModelsTests {
    @Test func decodesMovieUsingTMDBAsCanonicalIdentity() throws {
        let data = Data("""
        {
          "listed_at": "2023-11-14T22:13:20.000Z",
          "movie": {
            "title": "Titanic",
            "year": 1997,
            "ids": { "trakt": 122, "slug": "titanic-1997", "imdb": "tt0120338", "tmdb": 597 }
          }
        }
        """.utf8)

        let item = try JSONDecoder.trakt.decode(TraktWatchlistItem.self, from: data)

        #expect(item.movie?.ids.tmdb == 597)
        #expect(item.canonicalTMDBID == 597)
        #expect(item.listedAt == Date(timeIntervalSince1970: 1_700_000_000))
    }

    @Test func itemWithoutTMDBIDHasNoCanonicalIdentity() throws {
        let data = Data("""
        {
          "listed_at": "2023-11-14T22:13:20.000Z",
          "movie": {
            "title": "Unknown",
            "year": 2020,
            "ids": { "trakt": 999, "slug": "unknown-2020", "imdb": null, "tmdb": null }
          }
        }
        """.utf8)

        let item = try JSONDecoder.trakt.decode(TraktWatchlistItem.self, from: data)

        #expect(item.canonicalTMDBID == nil)
    }
}
