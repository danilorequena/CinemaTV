//
//  MovieEntity.swift
//  CinemaTV
//
//  AppEntity de filme para Siri/Shortcuts/Spotlight. Espelha o MediaItem
//  (não o modelo SwiftData). TVShowEntity entra na V2.
//

import Foundation
import AppIntents
import CinemaTVCore

struct MovieEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Movie"
    static let defaultQuery = MovieQuery()

    let id: Int
    let title: String
    let releaseYear: String?
    let overview: String
    let posterPath: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: releaseYear.map { "\($0)" },
            image: TMDBImage.url(path: posterPath, size: .thumbnail).map { .init(url: $0) }
        )
    }

    init(item: MediaItem) {
        self.id = item.id
        self.title = item.title
        self.releaseYear = item.releaseYear
        self.overview = item.overview
        self.posterPath = item.posterPath
    }

    var mediaItem: MediaItem {
        MediaItem(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: releaseYear,
            mediaType: .movie
        )
    }
}

struct MovieQuery: EntityQuery, EntityStringQuery {
    private var client: TMDBClient {
        TMDBClient(configuration: (try? .fromBundle(.main)) ?? TMDBConfiguration(apiKey: ""))
    }

    func entities(for identifiers: [Int]) async throws -> [MovieEntity] {
        try await withThrowingTaskGroup(of: MovieEntity.self) { group in
            for id in identifiers {
                group.addTask { [client] in
                    let details: MovieDetails = try await client.fetch(.movieDetail(id: id))
                    return MovieEntity(item: details.mediaItem)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }

    func entities(matching string: String) async throws -> [MovieEntity] {
        let page: PagedResponse<MediaItem> = try await client.fetch(.searchMovies, query: string)
        return page.results.prefix(10).map(MovieEntity.init)
    }

    /// Sugestões: os filmes da watchlist do usuário.
    @MainActor
    func suggestedEntities() async throws -> [MovieEntity] {
        let store = WatchlistStore(container: AppContainer.shared)
        return try store.moviesToWatch().map { movie in
            MovieEntity(
                item: MediaItem(
                    id: Int(movie.id ?? 0),
                    title: movie.name ?? "",
                    overview: movie.overview ?? "",
                    posterPath: movie.profilePath,
                    backdropPath: nil,
                    voteAverage: movie.counter ?? 0,
                    releaseDate: nil,
                    mediaType: .movie
                )
            )
        }
    }
}
