//
//  TVShowListModel.swift
//  CinemaTV
//
//  Paginação das categorias de séries do Discover.
//

import Foundation
import Observation
import CinemaTVCore

@MainActor
@Observable
final class TVShowListModel {
    private(set) var items: [MediaItem] = []
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?

    private var currentPage = 0
    private var hasMorePages = true

    func loadInitial(client: TMDBClient, category: TVShowCategory) async {
        guard items.isEmpty else { return }
        await fetchPage(1, client: client, category: category)
    }

    func loadMore(client: TMDBClient, category: TVShowCategory) async {
        guard hasMorePages, !isLoadingMore else { return }
        await fetchPage(currentPage + 1, client: client, category: category)
    }

    private func fetchPage(
        _ page: Int,
        client: TMDBClient,
        category: TVShowCategory
    ) async {
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            let response: PagedResponse<MediaItem> = try await client.fetch(
                category.endpoint,
                page: page
            )
            let existingIDs = Set(items.map(\.id))
            items.append(contentsOf: response.results.filter { !existingIDs.contains($0.id) })
            currentPage = response.page
            hasMorePages = response.hasMorePages
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
