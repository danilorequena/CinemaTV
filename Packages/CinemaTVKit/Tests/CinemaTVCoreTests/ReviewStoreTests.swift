//
//  ReviewStoreTests.swift
//  CinemaTVKit
//

import Foundation
import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct ReviewStoreTests {
    private let container: ModelContainer
    private let store: ReviewStore

    init() throws {
        container = try ModelContainerFactory.makeInMemory()
        store = ReviewStore(container: container)
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

    @Test func saveReviewCreatesRow() throws {
        try store.saveReview(for: matrix, rating: 4, text: "Loved it")

        let review = try store.review(forMovieID: 603)
        #expect(review?.rating == 4)
        #expect(review?.reviewText == "Loved it")
        #expect(review?.movieTitle == "The Matrix")
        #expect(review?.posterPath == "/matrix.jpg")
        #expect(review?.createdAt != nil)
        #expect(store.hasReview(movieID: 603))
    }

    @Test func saveReviewUpsertsByMovieID() throws {
        let first = try store.saveReview(for: matrix, rating: 3, text: "Good")
        let createdAt = first.createdAt
        try store.saveReview(for: matrix, rating: 5, text: "Great")

        let all = try container.mainContext.fetch(FetchDescriptor<MovieReview>())
        #expect(all.count == 1)

        let review = try store.review(forMovieID: 603)
        #expect(review?.rating == 5)
        #expect(review?.reviewText == "Great")
        #expect(review?.createdAt == createdAt)
    }

    @Test func ratingSnapsToWholeStepsAndClamps() throws {
        try store.saveReview(for: matrix, rating: 4.7, text: "")
        #expect(try store.review(forMovieID: 603)?.rating == 5.0)

        try store.saveReview(for: matrix, rating: 6, text: "")
        #expect(try store.review(forMovieID: 603)?.rating == 5.0)

        try store.saveReview(for: matrix, rating: 0.2, text: "")
        #expect(try store.review(forMovieID: 603)?.rating == 1.0)
    }

    @Test func deleteReviewRemovesRow() throws {
        try store.saveReview(for: matrix, rating: 4, text: "x")
        try store.deleteReview(movieID: 603)

        #expect(!store.hasReview(movieID: 603))

        // Delete de review inexistente é no-op.
        try store.deleteReview(movieID: 603)
    }

    @Test func reviewSurvivesUnmarkWatched() throws {
        let watchlist = WatchlistStore(container: container)
        try watchlist.markWatched(matrix)
        try store.saveReview(for: matrix, rating: 4, text: "Loved it")

        try watchlist.unmarkWatched(movieID: 603)

        #expect(!watchlist.isWatched(movieID: 603))
        #expect(store.hasReview(movieID: 603))
    }

    @Test func lookupHandlesLargeMovieIDs() throws {
        // Regressão do gotcha do #Predicate (Int64? vs Int64?): id acima
        // de Int32.max precisa buscar sem crashar.
        let item = MediaItem(
            id: 3_000_000_000,
            title: "Big ID",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: nil,
            mediaType: .movie
        )
        try store.saveReview(for: item, rating: 3, text: "")
        #expect(store.hasReview(movieID: 3_000_000_000))
    }
}
