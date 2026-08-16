//
//  OpenIntents.swift
//  CinemaTV
//
//  Intents que abrem o app, roteando pelo mesmo funil dos deep links.
//

import Foundation
import AppIntents
import CinemaTVCore

struct OpenMovieIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Movie"
    static let description = IntentDescription("Opens a movie's detail page in CinemaTV.")
    static let openAppWhenRun = true

    @Parameter(title: "Movie")
    var movie: MovieEntity

    @Dependency
    private var router: AppRouter

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$movie)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        router.open(.movie(id: movie.id))
        return .result()
    }
}

struct OpenWatchlistIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Watchlist"
    static let description = IntentDescription("Opens your CinemaTV watchlist.")
    static let openAppWhenRun = true

    @Dependency
    private var router: AppRouter

    @MainActor
    func perform() async throws -> some IntentResult {
        router.open(.watchlist)
        return .result()
    }
}

struct SearchMoviesIntent: AppIntent {
    static let title: LocalizedStringResource = "Search Movies"
    static let description = IntentDescription("Searches TMDB for movies and returns the results.")

    @Parameter(title: "Query")
    var query: String

    static var parameterSummary: some ParameterSummary {
        Summary("Search movies for \(\.$query)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<[MovieEntity]> {
        let client = TMDBClient(configuration: (try? .fromBundle(.main)) ?? TMDBConfiguration(apiKey: ""))
        let page: PagedResponse<MediaItem> = try await client.fetch(.searchMovies, query: query)
        return .result(value: page.results.prefix(10).map(MovieEntity.init))
    }
}
