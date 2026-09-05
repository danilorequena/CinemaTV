//
//  WatchlistStoreTests.swift
//  CinemaTVKit
//

import Foundation
import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct WatchlistStoreTests {
    // O container precisa ficar retido: o mainContext não o segura, e um
    // context órfão trapa no primeiro fetch.
    private let container: ModelContainer
    private let store: WatchlistStore

    init() throws {
        container = try ModelContainerFactory.makeInMemory()
        store = WatchlistStore(container: container)
    }

    private var matrix: MediaItem {
        MediaItem(
            id: 603,
            title: "The Matrix",
            overview: "A hacker...",
            posterPath: "/matrix.jpg",
            backdropPath: nil,
            voteAverage: 8.2,
            releaseDate: "1999-03-31",
            mediaType: .movie
        )
    }

    @Test func addsToWatchlistOnce() throws {
        try store.addToWatchlist(matrix)
        try store.addToWatchlist(matrix)

        let pending = try store.moviesToWatch()
        #expect(pending.count == 1)
        #expect(pending.first?.name == "The Matrix")
        #expect(store.isInWatchlist(movieID: 603))
        #expect(!store.isWatched(movieID: 603))
    }

    @Test func markWatchedMovesItem() throws {
        try store.addToWatchlist(matrix)
        try store.markWatched(matrix)

        #expect(!store.isInWatchlist(movieID: 603))
        #expect(store.isWatched(movieID: 603))
        #expect(try store.moviesToWatch().isEmpty)
        #expect(try store.moviesWatched().count == 1)
    }

    @Test func unreleasedMovieCannotBeMarkedWatched() throws {
        let upcoming = MediaItem(
            id: 604,
            title: "The Matrix 5",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: "2999-12-31",
            mediaType: .movie
        )
        try store.addToWatchlist(upcoming)
        try store.markWatched(upcoming)

        // Antes da estreia o mark é no-op: continua na fila, não vira visto.
        #expect(!store.isWatched(movieID: 604))
        #expect(store.isInWatchlist(movieID: 604))
    }

    @Test func removeFromWatchlist() throws {
        try store.addToWatchlist(matrix)
        try store.removeFromWatchlist(movieID: 603)

        #expect(try store.moviesToWatch().isEmpty)
    }

    @Test func storesAndBackfillsReleaseDate() throws {
        try store.addToWatchlist(matrix)
        let pending = try #require(try store.moviesToWatch().first)
        #expect(pending.releaseDate == "1999-03-31")

        // Backfill (itens antigos): atualização idempotente via detalhe.
        try store.updateReleaseDate(movieID: 603, releaseDate: "1999-04-01")
        #expect(try store.moviesToWatch().first?.releaseDate == "1999-04-01")

        // Fora da watchlist: no-op, sem erro.
        try store.updateReleaseDate(movieID: 999, releaseDate: "2026-01-01")
    }

    @Test func stampsDatesOnAddAndMarkWatched() throws {
        try store.addToWatchlist(matrix)
        let pending = try #require(try store.moviesToWatch().first)
        #expect(pending.dateAdded != nil)

        try store.markWatched(matrix)
        let watched = try #require(try store.moviesWatched().first)
        #expect(watched.watchedAt != nil)
    }

    @Test func reorderPersistsSortIndexes() throws {
        let items = (1...3).map { index in
            MediaItem(
                id: index,
                title: "Movie \(index)",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                voteAverage: 0,
                releaseDate: nil,
                mediaType: .movie
            )
        }
        for item in items {
            try store.addToWatchlist(item)
        }

        let reversed = try store.moviesToWatch().reversed()
        try store.reorderToWatch(Array(reversed))

        let names = try store.moviesToWatch().map(\.name)
        #expect(names == ["Movie 3", "Movie 2", "Movie 1"])
    }

    @Test func importedWatchedMovieMovesExistingWatchlistItemWithoutDuplication() throws {
        try store.addToWatchlist(matrix)
        let traktDate = Date(timeIntervalSince1970: 1_700_000_000)

        try store.importWatched(matrix, watchedAt: traktDate)
        try store.importWatched(matrix, watchedAt: traktDate)

        #expect(try store.moviesToWatch().isEmpty)
        let imported = try store.moviesWatched()
        #expect(imported.count == 1)
        #expect(imported.first?.id == 603)
        #expect(imported.first?.watchedAt == traktDate)
    }

    @Test func importedWatchlistMovieDoesNotRegressWatchedState() throws {
        try store.markWatched(matrix)

        try store.importToWatchlist(matrix, listedAt: Date(timeIntervalSince1970: 1_600_000_000))

        #expect(try store.moviesToWatch().isEmpty)
        #expect(try store.moviesWatched().count == 1)
    }
}
