//
//  TVShowTrackingStoreTests.swift
//  CinemaTVKit
//

import Foundation
import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct TVShowTrackingStoreTests {
    // O container precisa ficar retido: o mainContext não o segura, e um
    // context órfão trapa no primeiro fetch.
    private let container: ModelContainer
    private let store: TVShowTrackingStore

    init() throws {
        container = try ModelContainerFactory.makeInMemory()
        store = TVShowTrackingStore(container: container)
    }

    // MARK: - Fixtures

    private var gameOfThrones: TVShowDetails {
        TVShowDetails(
            id: 1399,
            name: "Game of Thrones",
            overview: "Seven noble families...",
            posterPath: "/got.jpg",
            backdropPath: nil,
            firstAirDate: "2011-04-17",
            numberOfSeasons: 2,
            numberOfEpisodes: 13,
            voteAverage: 8.4,
            genres: nil,
            status: "Ended",
            seasons: [
                SeasonSummary(id: 999, name: "Specials", overview: nil, posterPath: nil, seasonNumber: 0, episodeCount: 5, airDate: nil),
                SeasonSummary(id: 3624, name: "Season 1", overview: nil, posterPath: "/s1.jpg", seasonNumber: 1, episodeCount: 3, airDate: "2011-04-17"),
                SeasonSummary(id: 3625, name: "Season 2", overview: nil, posterPath: "/s2.jpg", seasonNumber: 2, episodeCount: 2, airDate: "2012-04-01")
            ]
        )
    }

    private func episode(_ number: Int, season: Int = 1) -> EpisodeSummary {
        EpisodeSummary(
            id: season * 100 + number,
            name: "S\(season)E\(number)",
            overview: nil,
            episodeNumber: number,
            seasonNumber: season,
            airDate: "2011-04-17",
            runtime: 60,
            stillPath: "/e\(number).jpg",
            voteAverage: 8.0
        )
    }

    private func seasonDetails(_ season: Int, episodes: Int) -> SeasonDetails {
        SeasonDetails(
            id: "season-\(season)",
            name: "Season \(season)",
            overview: nil,
            seasonNumber: season,
            episodes: (1...episodes).map { episode($0, season: season) }
        )
    }

    // MARK: - Follow

    @Test func followCreatesSkeletonWithoutSpecials() throws {
        try store.follow(gameOfThrones)
        try store.follow(gameOfThrones)

        let shows = try store.watchingShows()
        #expect(shows.count == 1)
        #expect(store.isFollowing(showID: 1399))

        let show = try #require(shows.first)
        #expect(show.name == "Game of Thrones")
        #expect(show.totalEpisodes == 5)
        #expect((show.seasons ?? []).count == 2)
        #expect(!(show.seasons ?? []).contains { $0.seasonNumber == 0 })

        // Up Next inicial é S1E1, sem nome (temporada não carregada).
        let upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.seasonNumber == 1)
        #expect(upNext.episodeNumber == 1)
        #expect(upNext.name == nil)
    }

    @Test func unfollowCascadesEverything() throws {
        try store.follow(gameOfThrones)
        try store.markEpisodeWatched(episode(1), showID: 1399)
        try store.unfollow(showID: 1399)

        #expect(!store.isFollowing(showID: 1399))
        #expect(try store.watchingShows().isEmpty)
        #expect(store.watchedEpisodeNumbers(showID: 1399, seasonNumber: 1).isEmpty)
    }

    // MARK: - Próxima estreia (next_episode_to_air)

    @Test func followAndRefreshTrackUpcomingEpisode() throws {
        var details = gameOfThrones
        details = TVShowDetails(
            id: details.id,
            name: details.name,
            overview: details.overview,
            posterPath: details.posterPath,
            firstAirDate: details.firstAirDate,
            numberOfSeasons: details.numberOfSeasons,
            numberOfEpisodes: details.numberOfEpisodes,
            voteAverage: details.voteAverage,
            status: details.status,
            nextEpisodeToAir: EpisodeSummary(
                id: 999,
                name: "The Long Night",
                episodeNumber: 1,
                seasonNumber: 3,
                airDate: "2026-09-01"
            ),
            seasons: details.seasons
        )

        try store.follow(details)
        let show = try #require(try store.show(id: 1399))
        #expect(show.upcomingAirDate == "2026-09-01")
        #expect(show.upcomingSeason == 3)
        #expect(show.upcomingEpisode == 1)
        #expect(show.upcomingEpisodeName == "The Long Night")

        // Sem next_episode_to_air no refresh: o cache limpa.
        try store.refreshMetadata(from: gameOfThrones)
        #expect(show.upcomingAirDate == nil)
        #expect(show.upcomingSeason == nil)
    }

    // MARK: - Última atividade

    @Test func lastActivityFollowsMarksAndUnmarks() throws {
        try store.follow(gameOfThrones)
        let show = try #require(try store.show(id: 1399))
        #expect(show.lastActivityAt == nil)

        try store.markEpisodeWatched(episode(1), showID: 1399)
        let afterFirst = try #require(show.lastActivityAt)

        try store.markEpisodeWatched(episode(2), showID: 1399)
        let afterSecond = try #require(show.lastActivityAt)
        #expect(afterSecond >= afterFirst)

        // Desmarcar o mais recente recua a atividade para o restante...
        try store.unmarkEpisodeWatched(showID: 1399, seasonNumber: 1, episodeNumber: 2)
        #expect(show.lastActivityAt != nil)

        // ...e desmarcar tudo zera o cache.
        try store.unmarkEpisodeWatched(showID: 1399, seasonNumber: 1, episodeNumber: 1)
        #expect(show.lastActivityAt == nil)
    }

    @Test func backfillRestoresLegacyActivityCache() throws {
        try store.follow(gameOfThrones)
        try store.markEpisodeWatched(episode(1), showID: 1399)

        // Simula o dado legado: episódio assistido, cache nunca preenchido.
        let show = try #require(try store.show(id: 1399))
        show.lastActivityAt = nil

        try store.backfillActivityCaches()
        #expect(show.lastActivityAt != nil)
    }

    @Test func bulkSeasonMarkSetsLastActivity() throws {
        try store.follow(gameOfThrones)
        try store.markSeasonWatched(seasonDetails(1, episodes: 3), showID: 1399)

        let show = try #require(try store.show(id: 1399))
        #expect(show.lastActivityAt != nil)

        try store.unmarkSeasonWatched(showID: 1399, seasonNumber: 1)
        #expect(show.lastActivityAt == nil)
    }

    // MARK: - Episódios

    @Test func markAndUnmarkEpisode() throws {
        try store.follow(gameOfThrones)
        try store.markEpisodeWatched(episode(1), showID: 1399)
        try store.markEpisodeWatched(episode(1), showID: 1399) // idempotente

        #expect(store.isEpisodeWatched(showID: 1399, seasonNumber: 1, episodeNumber: 1))
        #expect(store.watchedEpisodeNumbers(showID: 1399, seasonNumber: 1) == [1])
        #expect(store.seasonProgress(showID: 1399, seasonNumber: 1) == WatchProgress(watched: 1, total: 3))
        #expect(store.showProgress(showID: 1399) == WatchProgress(watched: 1, total: 5))

        try store.unmarkEpisodeWatched(showID: 1399, seasonNumber: 1, episodeNumber: 1)
        #expect(!store.isEpisodeWatched(showID: 1399, seasonNumber: 1, episodeNumber: 1))
        #expect(store.showProgress(showID: 1399) == WatchProgress(watched: 0, total: 5))
    }

    @Test func unairedEpisodeCannotBeMarked() throws {
        try store.follow(gameOfThrones)
        let unaired = EpisodeSummary(
            id: 103,
            name: "S1E3",
            overview: nil,
            episodeNumber: 3,
            seasonNumber: 1,
            airDate: "2999-12-31"
        )
        try store.markEpisodeWatched(unaired, showID: 1399)

        #expect(!store.isEpisodeWatched(showID: 1399, seasonNumber: 1, episodeNumber: 3))
    }

    @Test func markSeasonSkipsUnairedEpisodes() throws {
        try store.follow(gameOfThrones)
        let details = SeasonDetails(
            id: "season-1",
            name: "Season 1",
            overview: nil,
            seasonNumber: 1,
            episodes: [
                episode(1),
                episode(2),
                EpisodeSummary(
                    id: 103,
                    name: "S1E3",
                    overview: nil,
                    episodeNumber: 3,
                    seasonNumber: 1,
                    airDate: "2999-12-31"
                )
            ]
        )
        try store.markSeasonWatched(details, showID: 1399)

        #expect(store.watchedEpisodeNumbers(showID: 1399, seasonNumber: 1) == [1, 2])
    }

    @Test func upNextAdvancesAndRegresses() throws {
        try store.follow(gameOfThrones)

        // Marcar E1 avança para E2; nome vem do EpisodeSummary em mãos?
        // Não: o cache só guarda números até updateUpNextCache preencher.
        try store.markEpisodeWatched(episode(1), showID: 1399)
        var upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.seasonNumber == 1)
        #expect(upNext.episodeNumber == 2)

        // Buraco no meio: assistir E3 mantém o próximo em E2.
        try store.markEpisodeWatched(episode(3), showID: 1399)
        upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.episodeNumber == 2)

        // Fechar S1 pula para S2E1.
        try store.markEpisodeWatched(episode(2), showID: 1399)
        upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.seasonNumber == 2)
        #expect(upNext.episodeNumber == 1)

        // Desmarcar regride.
        try store.unmarkEpisodeWatched(showID: 1399, seasonNumber: 1, episodeNumber: 2)
        upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.seasonNumber == 1)
        #expect(upNext.episodeNumber == 2)
    }

    @Test func upNextCacheEnrichment() throws {
        try store.follow(gameOfThrones)
        try store.updateUpNextCache(showID: 1399, from: seasonDetails(1, episodes: 3))

        let upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.name == "S1E1")
        #expect(upNext.stillPath == "/e1.jpg")

        // Temporada errada não sobrescreve.
        try store.markEpisodeWatched(episode(1), showID: 1399)
        try store.updateUpNextCache(showID: 1399, from: seasonDetails(2, episodes: 2))
        let next = try #require(store.upNext(showID: 1399))
        #expect(next.episodeNumber == 2)
        #expect(next.name == nil)
    }

    // MARK: - Temporadas

    @Test func markSeasonWatchedBulk() throws {
        try store.follow(gameOfThrones)
        try store.markEpisodeWatched(episode(2), showID: 1399)
        try store.markSeasonWatched(seasonDetails(1, episodes: 3), showID: 1399)

        #expect(store.watchedEpisodeNumbers(showID: 1399, seasonNumber: 1) == [1, 2, 3])
        #expect(store.seasonProgress(showID: 1399, seasonNumber: 1).isComplete)

        let upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.seasonNumber == 2)

        try store.unmarkSeasonWatched(showID: 1399, seasonNumber: 1)
        #expect(store.watchedEpisodeNumbers(showID: 1399, seasonNumber: 1).isEmpty)
        #expect(store.upNext(showID: 1399)?.seasonNumber == 1)
    }

    @Test func seasonDetailsReconcileEpisodeCount() throws {
        try store.follow(gameOfThrones)
        // A lista real tem 4 episódios, o summary dizia 3.
        try store.markSeasonWatched(seasonDetails(1, episodes: 4), showID: 1399)

        #expect(store.seasonProgress(showID: 1399, seasonNumber: 1) == WatchProgress(watched: 4, total: 4))
        #expect(store.showProgress(showID: 1399) == WatchProgress(watched: 4, total: 6))
    }

    @Test func completedShowHasNoUpNext() throws {
        try store.follow(gameOfThrones)
        try store.markSeasonWatched(seasonDetails(1, episodes: 3), showID: 1399)
        try store.markSeasonWatched(seasonDetails(2, episodes: 2), showID: 1399)

        #expect(store.upNext(showID: 1399) == nil)
        #expect(store.showProgress(showID: 1399).isComplete)
    }

    // MARK: - Reconciliação

    @Test func refreshMetadataPicksUpNewSeasonsAndEpisodes() throws {
        try store.follow(gameOfThrones)
        try store.markSeasonWatched(seasonDetails(1, episodes: 3), showID: 1399)
        try store.markSeasonWatched(seasonDetails(2, episodes: 2), showID: 1399)
        #expect(store.upNext(showID: 1399) == nil)

        // A série ganhou uma S3 e a S2 ganhou um episódio extra.
        let updated = TVShowDetails(
            id: 1399,
            name: "Game of Thrones",
            overview: "Updated",
            posterPath: "/got-v2.jpg",
            backdropPath: nil,
            firstAirDate: "2011-04-17",
            numberOfSeasons: 3,
            numberOfEpisodes: 16,
            voteAverage: 8.5,
            genres: nil,
            status: "Returning Series",
            seasons: [
                SeasonSummary(id: 3624, name: "Season 1", overview: nil, posterPath: "/s1.jpg", seasonNumber: 1, episodeCount: 3, airDate: nil),
                SeasonSummary(id: 3625, name: "Season 2", overview: nil, posterPath: "/s2.jpg", seasonNumber: 2, episodeCount: 3, airDate: nil),
                SeasonSummary(id: 3626, name: "Season 3", overview: nil, posterPath: "/s3.jpg", seasonNumber: 3, episodeCount: 10, airDate: nil)
            ]
        )
        try store.refreshMetadata(from: updated)

        let show = try #require(try store.show(id: 1399))
        #expect(show.overview == "Updated")
        #expect(show.imagePath == "/got-v2.jpg")
        #expect((show.seasons ?? []).count == 3)
        #expect(show.totalEpisodes == 16)

        let upNext = try #require(store.upNext(showID: 1399))
        #expect(upNext.seasonNumber == 2)
        #expect(upNext.episodeNumber == 3)
        #expect(store.showProgress(showID: 1399) == WatchProgress(watched: 5, total: 16))
    }
}
