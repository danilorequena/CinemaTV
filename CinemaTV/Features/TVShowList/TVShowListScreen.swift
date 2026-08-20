//
//  TVShowListScreen.swift
//  CinemaTV
//
//  Grade paginada de uma categoria de séries.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct TVShowListScreen: View {
    @Environment(\.tmdbClient) private var client
    @State private var model = TVShowListModel()

    let category: TVShowCategory

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: DSSpacing.md)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: DSSpacing.lg) {
                ForEach(model.items) { item in
                    let selection = MediaSelection(
                        item: item,
                        scope: "tv-list-\(category.rawValue)"
                    )

                    NavigationLink(value: selection) {
                        MediaCard(item: item, zoomSourceID: selection.sourceID)
                    }
                    .buttonStyle(.plain)
                    .task {
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
                    Task {
                        await model.loadInitial(client: client, category: category)
                    }
                }
            }
        }
    }
}
