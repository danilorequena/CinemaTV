//
//  WatchlistStore.swift
//  CinemaTVKit
//
//  Regras de negócio da watchlist, extraídas do DetailCoreView e
//  WantWatchView legados. Uma única implementação para views, App Intents
//  e widgets.
//

import Foundation
import SwiftData

@MainActor
public final class WatchlistStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public convenience init(container: ModelContainer) {
        self.init(context: container.mainContext)
    }

    // MARK: - Queries

    public func moviesToWatch() throws -> [MoviesToWatch] {
        var descriptor = FetchDescriptor<MoviesToWatch>()
        descriptor.sortBy = [SortDescriptor(\.sortIndex), SortDescriptor(\.name)]
        return try context.fetch(descriptor)
    }

    public func moviesWatched() throws -> [MoviesWatched] {
        var descriptor = FetchDescriptor<MoviesWatched>()
        descriptor.sortBy = [SortDescriptor(\.name)]
        return try context.fetch(descriptor)
    }

    public func isInWatchlist(movieID: Int) -> Bool {
        (try? firstToWatch(movieID: movieID)) != nil
    }

    public func isWatched(movieID: Int) -> Bool {
        (try? firstWatched(movieID: movieID)) != nil
    }

    // MARK: - Mutations

    /// Adiciona à lista "quero assistir" (no fim da ordenação manual).
    public func addToWatchlist(_ item: MediaItem) throws {
        guard !isInWatchlist(movieID: item.id) else { return }
        let nextIndex = (try moviesToWatch().compactMap(\.sortIndex).max() ?? -1) + 1
        let movie = MoviesToWatch(item: item, sortIndex: nextIndex)
        movie.dateAdded = .now
        movie.releaseDate = item.releaseDate
        context.insert(movie)
        try context.save()
    }

    /// Backfill da data de estreia (itens antigos não a persistiam): o
    /// detalhe do filme chama ao carregar; no-op fora da watchlist.
    public func updateReleaseDate(movieID: Int, releaseDate: String?) throws {
        guard let movie = try firstToWatch(movieID: movieID),
              movie.releaseDate != releaseDate else { return }
        movie.releaseDate = releaseDate
        try context.save()
    }

    public func removeFromWatchlist(movieID: Int) throws {
        guard let movie = try firstToWatch(movieID: movieID) else { return }
        context.delete(movie)
        try context.save()
    }

    /// Marca como assistido, movendo de "quero assistir" quando presente.
    public func markWatched(_ item: MediaItem) throws {
        if let pending = try firstToWatch(movieID: item.id) {
            context.delete(pending)
        }
        guard !isWatched(movieID: item.id) else {
            try context.save()
            return
        }
        let watched = MoviesWatched(item: item)
        watched.watchedAt = .now
        context.insert(watched)
        try context.save()
    }

    public func unmarkWatched(movieID: Int) throws {
        guard let movie = try firstWatched(movieID: movieID) else { return }
        context.delete(movie)
        try context.save()
    }

    /// Persiste a nova ordem manual da lista "quero assistir".
    public func reorderToWatch(_ movies: [MoviesToWatch]) throws {
        for (index, movie) in movies.enumerated() {
            movie.sortIndex = index
        }
        try context.save()
    }

    // MARK: - Helpers

    private func firstToWatch(movieID: Int) throws -> MoviesToWatch? {
        // Sem #Predicate: o avaliador do SwiftData trapa em propriedades
        // armazenadas chamadas `id` (colisão com PersistentModel.id).
        // Listas pessoais são pequenas; filtrar em memória.
        try moviesToWatch().first { $0.id == Int64(movieID) }
    }

    private func firstWatched(movieID: Int) throws -> MoviesWatched? {
        try moviesWatched().first { $0.id == Int64(movieID) }
    }
}
