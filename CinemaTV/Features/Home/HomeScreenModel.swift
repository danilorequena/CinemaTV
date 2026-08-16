//
//  HomeScreenModel.swift
//  CinemaTV
//

import Foundation
import CinemaTVCore
import CinemaTVDesignSystem

@MainActor
@Observable
final class HomeScreenModel {
    struct Content: Sendable {
        let nowPlaying: [MediaItem]
        let upcoming: [MediaItem]
        let popular: [MediaItem]
        let topRated: [MediaItem]
        let discover: [MediaItem]
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

    /// Pull-to-refresh: recarrega mesmo com estado .loaded, mantendo o
    /// conteúdo atual na tela até os novos dados chegarem (sem skeleton).
    func refresh(client: TMDBClient) async {
        do {
            state = .loaded(try await fetchContent(client: client))
        } catch {
            // Refresh falhou: preserva o conteúdo atual se já havia algum;
            // só mostra erro se não havia nada carregado.
            if case .loaded = state { return }
            state = .failed(error.localizedDescription)
        }
    }

    private func fetchContent(client: TMDBClient) async throws -> Content {
        async let nowPlaying: PagedResponse<MediaItem> = client.fetch(.nowPlayingMovies)
        async let upcoming: PagedResponse<MediaItem> = client.fetch(.upcomingMovies)
        async let popular: PagedResponse<MediaItem> = client.fetch(.popularMovies)
        async let topRated: PagedResponse<MediaItem> = client.fetch(.topRatedMovies)
        async let discover: PagedResponse<MediaItem> = client.fetch(.discoverMovies)

        return Content(
            nowPlaying: try await nowPlaying.results,
            upcoming: try await upcoming.results,
            popular: try await popular.results,
            topRated: try await topRated.results,
            discover: try await discover.results
        )
    }

    func retry(client: TMDBClient) async {
        state = .idle
        await load(client: client)
    }
}
