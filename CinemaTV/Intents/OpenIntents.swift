//
//  OpenIntents.swift
//  CinemaTV
//
//  Intents que abrem o app, roteando pelo mesmo funil dos deep links.
//

import Foundation
import AppIntents
import CinemaTVCore

// OpenIntent (e não AppIntent puro): é o que torna os resultados do Visual
// Intelligence abríveis. O perform customizado navega via router — o default
// só traria o app pra frente. O parâmetro precisa se chamar `target`.
struct OpenMovieIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open Movie"
    static let description = IntentDescription("Opens a movie's detail page in CinemaTV.")
    static var supportedModes: IntentModes { .foreground }

    @Parameter(title: "Movie")
    var target: MovieEntity

    @Dependency
    private var router: AppRouter

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        router.open(.movie(id: target.id))
        return .result()
    }
}

struct OpenTVShowIntent: OpenIntent {
    static let title: LocalizedStringResource = "Open TV Show"
    static let description = IntentDescription("Opens a TV show's detail page in CinemaTV.")
    static var supportedModes: IntentModes { .foreground }

    @Parameter(title: "TV Show")
    var target: TVShowEntity

    @Dependency
    private var router: AppRouter

    static var parameterSummary: some ParameterSummary {
        Summary("Open \(\.$target)")
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        router.open(.tvShow(id: target.id))
        return .result()
    }
}

struct OpenWatchlistIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Watchlist"
    static let description = IntentDescription("Opens your CinemaTV watchlist.")
    static var supportedModes: IntentModes { .foreground }

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
