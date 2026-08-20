//
//  TVShowEntity.swift
//  CinemaTV
//
//  AppEntity de série para Siri/Shortcuts/Spotlight/Visual Intelligence.
//  Espelha o MediaItem (não o modelo SwiftData), como o MovieEntity.
//

import Foundation
import AppIntents
import CoreSpotlight
import CinemaTVCore

struct TVShowEntity: AppEntity, IndexedEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "TV Show"
    static let defaultQuery = TVShowQuery()

    let id: Int

    @Property(title: "Title", indexingKey: \.title)
    var title: String

    @Property(title: "Overview", indexingKey: \.contentDescription)
    var overview: String

    let firstAirYear: String?
    let posterPath: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(title)",
            subtitle: firstAirYear.map { "\($0)" },
            image: TMDBImage.url(path: posterPath, size: .thumbnail).map { .init(url: $0) }
        )
    }

    init(item: MediaItem) {
        self.id = item.id
        self.firstAirYear = item.releaseYear
        self.posterPath = item.posterPath
        self.title = item.title
        self.overview = item.overview
    }

    var mediaItem: MediaItem {
        MediaItem(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: firstAirYear,
            mediaType: .tvShow
        )
    }
}

struct TVShowQuery: IndexedEntityQuery, EntityStringQuery {
    private var client: TMDBClient {
        TMDBClient(configuration: (try? .fromBundle(.main)) ?? TMDBConfiguration(apiKey: ""))
    }

    func entities(for identifiers: [Int]) async throws -> [TVShowEntity] {
        try await withThrowingTaskGroup(of: TVShowEntity.self) { group in
            for id in identifiers {
                group.addTask { [client] in
                    let details: TVShowDetails = try await client.fetch(.tvShowDetail(id: id))
                    return TVShowEntity(item: details.mediaItem)
                }
            }
            return try await group.reduce(into: []) { $0.append($1) }
        }
    }

    func entities(matching string: String) async throws -> [TVShowEntity] {
        let page: PagedResponse<MediaItem> = try await client.fetch(.searchTVShows, query: string)
        return page.results.prefix(10).map(TVShowEntity.init)
    }

    /// Sugestões: as séries que o usuário acompanha.
    @MainActor
    func suggestedEntities() async throws -> [TVShowEntity] {
        let store = TVShowTrackingStore(container: AppContainer.shared)
        return try store.watchingShows().map { show in
            TVShowEntity(
                item: MediaItem(
                    id: show.id ?? 0,
                    title: show.name ?? "",
                    overview: show.overview ?? "",
                    posterPath: show.imagePath,
                    backdropPath: nil,
                    voteAverage: show.voteAverage ?? 0,
                    releaseDate: show.firstAirDate,
                    mediaType: .tvShow
                )
            )
        }
    }

    // MARK: IndexedEntityQuery — reindex dirigido pelo sistema

    func reindexEntities(
        for identifiers: [Int],
        indexDescription: CSSearchableIndexDescription
    ) async throws {
        try await CSSearchableIndex.default().indexAppEntities(entities(for: identifiers))
    }

    func reindexAllEntities(indexDescription: CSSearchableIndexDescription) async throws {
        // Corpus indexado = séries acompanhadas, não resultados de busca.
        try await CSSearchableIndex.default().indexAppEntities(suggestedEntities())
    }
}
