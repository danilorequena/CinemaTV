//
//  MovieListScreen.swift
//  CinemaTV
//
//  Grid paginada de uma categoria — substitui MoviesListView/MovieCell.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct MovieListScreen: View {
    @Environment(\.tmdbClient) private var client
    @State private var model = MovieListModel()

    let category: MovieCategory

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: DSSpacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DSSpacing.lg) {
                ForEach(model.items) { item in
                    let selection = MediaSelection(item: item, scope: "list-\(category.rawValue)")
                    NavigationLink(value: selection) {
                        MediaCard(item: item, zoomSourceID: selection.sourceID)
                    }
                    .buttonStyle(.plain)
                    .task {
                        // Paginação: carrega a próxima página ao chegar no fim.
                        if item.id == model.items.last?.id {
                            await model.loadMore(client: client, category: category)
                        }
                    }
                }
            }
            .padding(.horizontal, DSSpacing.lg)

            if model.isLoadingMore {
                ProgressView()
                    .padding(DSSpacing.lg)
            }
        }
        .navigationTitle(Text(category.displayName))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await model.loadInitial(client: client, category: category)
        }
        .overlay {
            if model.items.isEmpty, let error = model.errorMessage {
                ErrorStateView(message: error) {
                    Task { await model.loadInitial(client: client, category: category) }
                }
            }
        }
    }
}

@MainActor
@Observable
final class MovieListModel {
    private(set) var items: [MediaItem] = []
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?
    private var currentPage = 0
    private var hasMorePages = true

    func loadInitial(client: TMDBClient, category: MovieCategory) async {
        guard items.isEmpty else { return }
        await fetchPage(1, client: client, category: category)
    }

    func loadMore(client: TMDBClient, category: MovieCategory) async {
        guard hasMorePages, !isLoadingMore else { return }
        await fetchPage(currentPage + 1, client: client, category: category)
    }

    private func fetchPage(_ page: Int, client: TMDBClient, category: MovieCategory) async {
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response: PagedResponse<MediaItem> = try await client.fetch(category.endpoint, page: page)
            let existing = Set(items.map(\.id))
            items.append(contentsOf: response.results.filter { !existing.contains($0.id) })
            currentPage = response.page
            hasMorePages = response.hasMorePages
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
