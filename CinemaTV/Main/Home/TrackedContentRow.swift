//
//  TrackedContentRow.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct TrackedContentRow<Item: Identifiable, Destination: View>: View {
    let title: String
    let items: [Item]
    let imageURLProvider: (Item) -> URL?
    let titleProvider: (Item) -> String
    let destination: (Item) -> Destination

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassSectionHeader(title: title, showSeeAll: false)

            if items.isEmpty {
                emptyRow
            } else {
                contentRow
            }
        }
    }

    private var emptyRow: some View {
        HStack {
            Spacer()
            Text("No items yet")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(height: 200)
    }

    private var contentRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items) { item in
                    NavigationLink(destination: destination(item)) {
                        VStack(spacing: 0) {
                            AsyncImage(url: imageURLProvider(item)) { phase in
                                switch phase {
                                case .empty:
                                    Rectangle()
                                        .fill(.quaternary)
                                        .overlay { ProgressView() }
                                case .success(let image):
                                    image.resizable().scaledToFill()
                                case .failure:
                                    Rectangle()
                                        .fill(.quaternary)
                                        .overlay {
                                            Image(systemName: "photo")
                                                .foregroundStyle(.secondary)
                                        }
                                @unknown default:
                                    EmptyView()
                                }
                            }
                            .frame(width: 120, height: 180)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Convenience initializers for common types

extension TrackedContentRow where Item == MoviesToWatch, Destination == DetailView {
    init(title: String, movies: [MoviesToWatch]) {
        self.title = title
        self.items = movies
        self.imageURLProvider = { movie in
            URL(string: Constants.basePosters + (movie.profilePath ?? ""))
        }
        self.titleProvider = { movie in
            movie.name ?? ""
        }
        self.destination = { movie in
            DetailView(id: Int(truncatingIfNeeded: movie.id ?? 0), state: .movie, showAddFavoritesButton: false)
        }
    }
}

extension TrackedContentRow where Item == MoviesWatched, Destination == DetailView {
    init(title: String, movies: [MoviesWatched]) {
        self.title = title
        self.items = movies
        self.imageURLProvider = { movie in
            URL(string: Constants.basePosters + (movie.profilePath ?? ""))
        }
        self.titleProvider = { movie in
            movie.name ?? ""
        }
        self.destination = { movie in
            DetailView(id: Int(truncatingIfNeeded: movie.id ?? 0), state: .movie, showAddFavoritesButton: false)
        }
    }
}

extension TrackedContentRow where Item == TVShowWatchingModel, Destination == DetailView {
    init(title: String, tvShows: [TVShowWatchingModel]) {
        self.title = title
        self.items = tvShows
        self.imageURLProvider = { show in
            URL(string: Constants.basePosters + (show.imagePath ?? ""))
        }
        self.titleProvider = { show in
            show.name ?? ""
        }
        self.destination = { show in
            DetailView(id: show.id ?? 0, state: .tvShow, showAddFavoritesButton: false)
        }
    }
}

private struct PreviewItem: Identifiable {
    let id: Int
    let name: String
}

#Preview {
    NavigationStack {
        TrackedContentRow(
            title: "Currently Watching",
            items: [
                PreviewItem(id: 1, name: "Item 1"),
                PreviewItem(id: 2, name: "Item 2"),
                PreviewItem(id: 3, name: "Item 3")
            ],
            imageURLProvider: { _ in URL(string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg") },
            titleProvider: { $0.name },
            destination: { _ in Text("Detail") }
        )
    }
}
