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

    // MARK: - Pick do álbum de canções

    @Test func songsPickPrefersVocalCompilationOverScore() {
        let score = candidate(id: "score", title: "Guardians of the Galaxy (Original Score)", artist: "Tyler Bates", year: 2014)
        let mix = candidate(id: "mix", title: "Guardians of the Galaxy: Awesome Mix Vol. 1 (Original Motion Picture Soundtrack)", artist: "Various Artists", year: 2014)
        let scored = SoundtrackFinder.rank(
            [score, mix],
            title: "Guardians of the Galaxy",
            releaseYear: 2014,
            composers: ["Tyler Bates"]
        )
        #expect(SoundtrackFinder.songsPick(scored, composers: ["Tyler Bates"])?.id == "mix")
    }

    @Test func songsPickIsNilWhenOnlyScoreAlbumsExist() {
        let score = candidate(id: "score", title: "Interstellar (Original Motion Picture Soundtrack)", artist: "Hans Zimmer", year: 2014)
        let scored = SoundtrackFinder.rank(
            [score],
            title: "Interstellar",
            releaseYear: 2014,
            composers: ["Hans Zimmer"]
        )
        #expect(SoundtrackFinder.songsPick(scored, composers: ["Hans Zimmer"]) == nil)
    }

    @Test func composerAlbumIsNeverASongsCompilation() {
        // "Music from..." no título não basta: o artista é o compositor.
        let horner = candidate(id: "a", title: "Titanic: Music from the Motion Picture", artist: "James Horner", year: 1997)
        #expect(!SoundtrackFinder.isSongsCompilation(horner, composers: ["James Horner"]))
    }

    @Test func localizedVariousArtistsCountsAsSongsCompilation() {
        // Storefront BR devolve "Vários intérpretes" no lugar de "Various
        // Artists"; es devolve "Varios artistas".
        let br = candidate(id: "br", title: "Guardians of the Galaxy: Awesome Mix Vol. 1 (Original Motion Picture Soundtrack)", artist: "Vários intérpretes", year: 2014)
        let es = candidate(id: "es", title: "Guardians of the Galaxy: Awesome Mix Vol. 1", artist: "Varios artistas", year: 2014)
        #expect(SoundtrackFinder.isSongsCompilation(br, composers: ["Tyler Bates"]))
        #expect(SoundtrackFinder.isSongsCompilation(es, composers: ["Tyler Bates"]))
    }

    @Test func inspiredByCompilationCountsAsSongs() {
        let inspired = candidate(id: "b", title: "Barbie: Music from and Inspired By the Motion Picture", artist: "Barbie the Album", year: 2023)
        #expect(SoundtrackFinder.isSongsCompilation(inspired, composers: ["Mark Ronson"]))
    }

    // MARK: - Canções vs. instrumental

    private func track(id: String = UUID().uuidString, title: String, artist: String) -> SoundtrackTrack {
        SoundtrackTrack(id: id, title: title, artistName: artist, duration: 200, previewURL: nil, song: nil)
    }

    // MARK: - Canções avulsas (verificação no catálogo)

    @Test func bestSongMatchRequiresTitleAndArtist() {
        let candidates = [
            track(id: "cover", title: "Hooked on a Feeling", artist: "Piano Dreamers"),
            track(id: "original", title: "Hooked on a Feeling", artist: "Blue Swede"),
            track(id: "other", title: "Feeling Good", artist: "Blue Swede"),
        ]
        let match = SoundtrackFinder.bestSongMatch(title: "Hooked on a Feeling", artist: "Blue Swede", in: candidates)
        #expect(match?.id == "original")
    }

    @Test func bestSongMatchToleratesParentheticalsAndDiacritics() {
        let candidates = [
            track(id: "1", title: "My Heart Will Go On (Love Theme from \"Titanic\")", artist: "Céline Dion"),
        ]
        let match = SoundtrackFinder.bestSongMatch(title: "My Heart Will Go On", artist: "Celine Dion", in: candidates)
        #expect(match?.id == "1")
    }

    @Test func hallucinatedSongFindsNoMatch() {
        let candidates = [
            track(id: "1", title: "Come and Get Your Love", artist: "Redbone"),
        ]
        #expect(SoundtrackFinder.bestSongMatch(title: "Galaxy Anthem", artist: "Star Band", in: candidates) == nil)
    }

    @Test func junkSongsAreFilteredFromThePool() {
        let pool = [
            track(id: "real", title: "Come and Get Your Love", artist: "Redbone"),
            track(id: "karaoke", title: "Come and Get Your Love (Karaoke Version)", artist: "Karaoke Hits"),
            track(id: "lullaby", title: "Hooked on a Feeling", artist: "Bedtime Stars"),
            track(id: "style", title: "Hooked on a Feeling (In the Style of Blue Swede)", artist: "Cover Band"),
        ]
        var withAlbum = pool
        withAlbum[2] = SoundtrackTrack(id: "lullaby", title: "Hooked on a Feeling", artistName: "Bedtime Stars", duration: 100, previewURL: nil, song: nil, albumTitle: "Lullaby Versions of Guardians")
        let plausible = SoundtrackFinder.plausibleSongCandidates(withAlbum)
        #expect(plausible.map(\.id) == ["real"])
    }

    @Test func guestVocalistCreditedWithComposerIsASong() {
        // O álbum do Titanic credita a Céline como "James Horner & Céline
        // Dion"; as demais faixas como "James Horner & Orchestra".
        let split = SoundtrackFinder.splitTracks(
            [
                track(title: "My Heart Will Go On (Love Theme from \"Titanic\")", artist: "James Horner & Céline Dion"),
                track(title: "Southampton", artist: "James Horner & Orchestra"),
                track(title: "Rose (Instrumental)", artist: "James Horner & Titanic Orchestra"),
            ],
            albumArtist: "James Horner",
            composers: ["James Horner"]
        )
        #expect(split.songs.map(\.artistName) == ["James Horner & Céline Dion"])
        #expect(split.instrumental.count == 2)
    }

    @Test func vocalGuestSplitsFromComposerScore() {
        let split = SoundtrackFinder.splitTracks(
            [
                track(title: "Never an Absolution", artist: "James Horner"),
                track(title: "My Heart Will Go On", artist: "Céline Dion"),
                track(title: "Southampton", artist: "James Horner"),
            ],
            albumArtist: "James Horner",
            composers: ["James Horner"]
        )
        #expect(split.songs.map(\.title) == ["My Heart Will Go On"])
        #expect(split.instrumental.count == 2)
    }

    @Test func pureScoreAlbumHasNoSongs() {
        let split = SoundtrackFinder.splitTracks(
            [
                track(title: "Cornfield Chase", artist: "Hans Zimmer"),
                track(title: "No Time for Caution", artist: "Hans Zimmer"),
            ],
            albumArtist: "Hans Zimmer",
            composers: ["Hans Zimmer"]
        )
        #expect(split.songs.isEmpty)
        #expect(split.instrumental.count == 2)
    }

    @Test func albumArtistIsTheReferenceWhenComposersAreUnknown() {
        let split = SoundtrackFinder.splitTracks(
            [
                track(title: "Main Theme", artist: "John Williams"),
                track(title: "Somewhere in My Memory", artist: "The Children's Choir"),
            ],
            albumArtist: "John Williams",
            composers: []
        )
        #expect(split.instrumental.map(\.artistName) == ["John Williams"])
        #expect(split.songs.count == 1)
    }

    @Test func variousArtistsWithoutComposersStaysUnsplit() {
        let split = SoundtrackFinder.splitTracks(
            [
                track(title: "Hooked on a Feeling", artist: "Blue Swede"),
                track(title: "Come and Get Your Love", artist: "Redbone"),
            ],
            albumArtist: "Various Artists",
            composers: []
        )
        #expect(split.songs.count == 2)
        #expect(split.instrumental.isEmpty)
    }

    @Test func orchestrasAndInstrumentalTitlesCountAsScore() {
        let split = SoundtrackFinder.splitTracks(
            [
                track(title: "Titanic Suite", artist: "London Symphony Orchestra"),
                track(title: "My Heart Will Go On (Instrumental)", artist: "Kenny G"),
                track(title: "I Will Always Love You", artist: "Whitney Houston"),
            ],
            albumArtist: "Various Artists",
            composers: ["Alan Silvestri"]
        )
        #expect(split.songs.map(\.artistName) == ["Whitney Houston"])
        #expect(split.instrumental.count == 2)
    }

    @Test func composerCreditedWithOrchestraStillCountsAsScore() {
        let split = SoundtrackFinder.splitTracks(
            [track(title: "The Imperial March", artist: "John Williams & London Symphony Orchestra")],
            albumArtist: "John Williams",
            composers: ["John Williams"]
        )
        #expect(split.instrumental.count == 1)
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

    @Test func distinctSongsAlbumRoundTrips() {
        let cache = makeCache()
        let entry = SoundtrackCache.Entry(albumID: "score", songsAlbumID: "mix", about: nil, storefront: "br", savedAt: .now)
        cache.store(entry, kind: .movie, tmdbID: 118340)
        let loaded = cache.entry(kind: .movie, tmdbID: 118340, storefront: "br")
        #expect(loaded?.songsAlbumID == "mix")
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
