//
//  TVHomeModel.swift
//  CinemaTV
//
//  Lado Séries da Discover: espelho do HomeScreenModel com as rails de TV.
//

import Foundation
import CinemaTVCore
import CinemaTVDesignSystem

@MainActor
@Observable
final class TVHomeModel {
    struct Content: Sendable {
        let airingToday: [MediaItem]
        let onTheAir: [MediaItem]
        let popular: [MediaItem]
    }

    private(set) var state: LoadState<Content> = .idle

    /// Gatilho Equatable para a animação de entrada do conteúdo.
    var isLoaded: Bool {
        if case .loaded = state { return true }
        return false
    }

    func load(client: TMDBClient) async {
        if case .loaded = state { return }
        state = .loading
        do {
            state = .loaded(try await fetchContent(client: client))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Pull-to-refresh: mantém o conteúdo atual até os novos dados chegarem.
    func refresh(client: TMDBClient) async {
        do {
            state = .loaded(try await fetchContent(client: client))
        } catch {
            if case .loaded = state { return }
            state = .failed(error.localizedDescription)
        }
    }

    func retry(client: TMDBClient) async {
        state = .idle
        await load(client: client)
    }

    private func fetchContent(client: TMDBClient) async throws -> Content {
        async let airingToday: PagedResponse<MediaItem> = client.fetch(.airingTodayTVShows)
        async let onTheAir: PagedResponse<MediaItem> = client.fetch(.onTheAirTVShows)
        async let popular: PagedResponse<MediaItem> = client.fetch(.popularTVShows)

        return Content(
            airingToday: try await airingToday.results,
            onTheAir: try await onTheAir.results,
            popular: try await popular.results
        )
    }
}
