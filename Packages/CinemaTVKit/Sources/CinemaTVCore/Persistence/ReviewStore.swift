//
//  ReviewStore.swift
//  CinemaTVKit
//
//  Regras de negócio dos reviews pessoais. Mesmo shape do WatchlistStore:
//  uma única implementação para views e futuros intents/widgets.
//

import Foundation
import SwiftData

@MainActor
public final class ReviewStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public convenience init(container: ModelContainer) {
        self.init(context: container.mainContext)
    }

    // MARK: - Queries

    public func review(forMovieID movieID: Int) throws -> MovieReview? {
        try firstReview(movieID: movieID)
    }

    public func hasReview(movieID: Int) -> Bool {
        (try? firstReview(movieID: movieID)) != nil
    }

    // MARK: - Mutations

    /// Upsert por movieID; a nota é normalizada para estrelas inteiras
    /// (1...5). createdAt só no insert, updatedAt sempre.
    @discardableResult
    public func saveReview(for item: MediaItem, rating: Double, text: String) throws -> MovieReview {
        let normalized = Self.normalizedRating(rating)
        let now = Date()

        if let existing = try firstReview(movieID: item.id) {
            existing.rating = normalized
            existing.reviewText = text
            existing.movieTitle = item.title
            existing.posterPath = item.posterPath
            existing.updatedAt = now
            try context.save()
            return existing
        }

        let review = MovieReview(
            movieID: Int64(item.id),
            rating: normalized,
            reviewText: text,
            movieTitle: item.title,
            posterPath: item.posterPath,
            createdAt: now,
            updatedAt: now
        )
        context.insert(review)
        try context.save()
        return review
    }

    public func deleteReview(movieID: Int) throws {
        guard let review = try firstReview(movieID: movieID) else { return }
        context.delete(review)
        try context.save()
    }

    /// Arredonda para a estrela inteira mais próxima e clampa em 1...5.
    public static func normalizedRating(_ value: Double) -> Double {
        min(max(value.rounded(), 1.0), 5.0)
    }

    // MARK: - Helpers

    private func firstReview(movieID: Int) throws -> MovieReview? {
        // Optional dos dois lados: comparar Int64? com Int64 crasha o
        // avaliador de #Predicate do SwiftData.
        let id: Int64? = Int64(movieID)
        var descriptor = FetchDescriptor<MovieReview>(predicate: #Predicate { $0.movieID == id })
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }
}
