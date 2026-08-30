//
//  SoundtrackFinderTests.swift
//  CinemaTVTests
//
//  Heurísticas de busca/ranking de trilha sonora e regras do cache local.
//

import Foundation
import Testing
@testable import CinemaTV
import CinemaTVCore

private func candidate(
    id: String = UUID().uuidString,
    title: String,
    artist: String = "Various Artists",
    year: Int? = nil
) -> SoundtrackCandidate {
    SoundtrackCandidate(
        id: id,
        title: title,
        artistName: artist,
        releaseYear: year,
        trackCount: 12,
        artworkURL: nil,
        url: nil
    )
}

struct SoundtrackFinderTests {
    // MARK: - Termos de busca

    @Test func movieTermsStartWithThePreciseOne() {
        let terms = SoundtrackFinder.searchTerms(title: "Titanic", originalTitle: nil, kind: .movie)
        #expect(terms.first == "Titanic Original Motion Picture Soundtrack")
        #expect(terms.contains("Titanic soundtrack"))
    }

    @Test func localizedTitleAddsOriginalTitleTerm() {
        let terms = SoundtrackFinder.searchTerms(
            title: "A Origem",
            originalTitle: "Inception",
            kind: .movie
        )
        #expect(terms.contains("Inception soundtrack"))
    }

    @Test func identicalOriginalTitleAddsNoExtraTerm() {
        let terms = SoundtrackFinder.searchTerms(title: "Titanic", originalTitle: "Titanic", kind: .movie)
        #expect(terms.count == 2)
    }

    // MARK: - Compositores

    @Test func composersComeFromKnownJobs() {
        let crew = [
            CrewMember(id: 1, name: "James Horner", job: "Original Music Composer", department: "Sound", profilePath: nil),
            CrewMember(id: 2, name: "James Cameron", job: "Director", department: "Directing", profilePath: nil),
            CrewMember(id: 3, name: "Ramin Djawadi", job: "Music", department: "Sound", profilePath: nil),
            CrewMember(id: 4, name: "Ramin Djawadi", job: "Main Title Theme Composer", department: "Sound", profilePath: nil),
        ]
        let composers = SoundtrackFinder.composers(in: crew)
        #expect(composers == ["James Horner", "Ramin Djawadi"])
    }

    // MARK: - Ranking

    @Test func officialSoundtrackBeatsKaraokePollution() {
        let official = candidate(
            id: "official",
            title: "Titanic: Music from the Motion Picture",
            artist: "James Horner",
            year: 1997
        )
        let karaoke = candidate(
            id: "karaoke",
            title: "Titanic Karaoke Hits",
            artist: "Karaoke Band",
            year: 2005
        )
        let tribute = candidate(
            id: "tribute",
            title: "Tribute to Titanic",
            artist: "String Quartet",
            year: 2012
        )
        let scored = SoundtrackFinder.rank(
            [karaoke, tribute, official],
            title: "Titanic",
            releaseYear: 1997,
            composers: ["James Horner"]
        )
        #expect(scored.first?.candidate.id == "official")
        #expect(SoundtrackFinder.confidentPick(scored)?.id == "official")
    }

    @Test func composerMatchBoostsScore() {
        let byComposer = candidate(id: "composer", title: "Interstellar (Original Motion Picture Soundtrack)", artist: "Hans Zimmer", year: 2014)
        let unrelated = candidate(id: "other", title: "Interstellar Soundtrack", artist: "Random Orchestra", year: 2014)
        let scored = SoundtrackFinder.rank(
            [unrelated, byComposer],
            title: "Interstellar",
            releaseYear: 2014,
            composers: ["Hans Zimmer"]
        )
        #expect(scored.first?.candidate.id == "composer")
    }

    @Test func ambiguousTopTwoIsNotAConfidentPick() {
        let first = candidate(id: "a", title: "Dune (Original Motion Picture Soundtrack)", artist: "Hans Zimmer", year: 2021)
        let second = candidate(id: "b", title: "Dune (Original Motion Picture Soundtrack)", artist: "Hans Zimmer", year: 2021)
        let scored = SoundtrackFinder.rank(
            [first, second],
            title: "Dune",
            releaseYear: 2021,
            composers: ["Hans Zimmer"]
        )
        #expect(SoundtrackFinder.confidentPick(scored) == nil)
    }

    @Test func shortlistDropsNegativeScoresAndCaps() {
        let good = candidate(id: "good", title: "Rocky Original Motion Picture Soundtrack", year: 1976)
        let junk = candidate(id: "junk", title: "Rocky Karaoke Party")
        let scored = SoundtrackFinder.rank(
            [good, junk],
            title: "Rocky",
            releaseYear: 1976,
            composers: []
        )
        let shortlist = SoundtrackFinder.shortlist(scored, limit: 5)
        #expect(shortlist.map(\.id) == ["good"])
    }

    @Test func normalizationIsCaseAndDiacriticInsensitive() {
        #expect(SoundtrackFinder.normalize("Amélie") == "amelie")
        #expect(SoundtrackFinder.normalize("  TITANIC ") == "titanic")
    }
}

struct SoundtrackCacheTests {
    private static let suite = "SoundtrackCacheTests"

    private func makeCache() -> SoundtrackCache {
        UserDefaults(suiteName: Self.suite)?.removePersistentDomain(forName: Self.suite)
        return SoundtrackCache(suiteName: Self.suite)
    }

    @Test func roundTripsAnEntry() {
        let cache = makeCache()
        let entry = SoundtrackCache.Entry(albumID: "123", about: "text", storefront: "br", savedAt: .now)
        cache.store(entry, kind: .movie, tmdbID: 597)
        let loaded = cache.entry(kind: .movie, tmdbID: 597, storefront: "br")
        #expect(loaded == entry)
    }

    @Test func negativeCacheRoundTrips() {
        let cache = makeCache()
        cache.store(SoundtrackCache.Entry(albumID: nil, about: nil, storefront: "br", savedAt: .now), kind: .tv, tmdbID: 1399)
        let loaded = cache.entry(kind: .tv, tmdbID: 1399, storefront: "br")
        #expect(loaded != nil)
        #expect(loaded?.albumID == nil)
    }

    @Test func expiredEntryIsDropped() {
        let old = Date(timeIntervalSinceNow: -SoundtrackCache.timeToLive - 60)
        let entry = SoundtrackCache.Entry(albumID: "123", about: nil, storefront: nil, savedAt: old)
        #expect(!SoundtrackCache.isFresh(entry, storefront: nil, now: .now))
    }

    @Test func storefrontChangeInvalidates() {
        let entry = SoundtrackCache.Entry(albumID: "123", about: nil, storefront: "br", savedAt: .now)
        #expect(!SoundtrackCache.isFresh(entry, storefront: "us", now: .now))
        #expect(SoundtrackCache.isFresh(entry, storefront: "br", now: .now))
        // Storefront desconhecido de um lado não invalida.
        #expect(SoundtrackCache.isFresh(entry, storefront: nil, now: .now))
    }

    @Test func movieAndTVKeysDoNotCollide() {
        #expect(SoundtrackCache.key(kind: .movie, tmdbID: 42) != SoundtrackCache.key(kind: .tv, tmdbID: 42))
    }
}
