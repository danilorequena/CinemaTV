//
//  WatchlistIntents.swift
//  CinemaTV
//
//  Intents inline (sem abrir o app): mexem na watchlist via WatchlistStore
//  compartilhado e mantêm o índice do Spotlight em dia.
//

import Foundation
import AppIntents
import CinemaTVCore

struct AddMovieToWatchlistIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Movie to Watchlist"
    static let description = IntentDescription("Adds a movie to your CinemaTV watchlist.")

    @Parameter(title: "Movie")
    var movie: MovieEntity

    init() {}
    init(movie: MovieEntity) {
        self.movie = movie
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$movie) to watchlist")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        let store = WatchlistStore(container: AppContainer.shared)
        try store.addToWatchlist(movie.mediaItem)
        SpotlightIndexer.index(movie)
        return .result(
            dialog: "Added \(movie.title) to your watchlist.",
            snippetIntent: MovieCardSnippetIntent(movie: movie)
        )
    }
}

struct MarkMovieWatchedIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Movie as Watched"
    static let description = IntentDescription("Marks a movie as watched, moving it out of your watchlist.")

    @Parameter(title: "Movie")
    var movie: MovieEntity

    init() {}
    init(movie: MovieEntity) {
        self.movie = movie
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Mark \(\.$movie) as watched")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        // Filme ainda sem estreia não pode ser marcado (mesma regra da UI;
        // o store também recusa).
        guard movie.mediaItem.isReleased else {
            return .result(
                dialog: "\(movie.title) hasn't been released yet, so it can't be marked as watched.",
                snippetIntent: MovieCardSnippetIntent(movie: movie)
            )
        }
        let store = WatchlistStore(container: AppContainer.shared)
        try store.markWatched(movie.mediaItem)
        return .result(
            dialog: "Marked \(movie.title) as watched.",
            snippetIntent: MovieCardSnippetIntent(movie: movie)
        )
    }
}

struct RemoveFromWatchlistIntent: AppIntent {
    static let title: LocalizedStringResource = "Remove Movie from Watchlist"
    static let description = IntentDescription("Removes a movie from your CinemaTV watchlist.")

    @Parameter(title: "Movie")
    var movie: MovieEntity

    static var parameterSummary: some ParameterSummary {
        Summary("Remove \(\.$movie) from watchlist")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let store = WatchlistStore(container: AppContainer.shared)
        try store.removeFromWatchlist(movieID: movie.id)
        SpotlightIndexer.deindex(movieID: movie.id)
        return .result(dialog: "Removed \(movie.title) from your watchlist.")
    }
}
