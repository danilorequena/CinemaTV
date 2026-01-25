//
//  InProgressView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 25/01/26.
//

import SwiftUI
import SwiftData

struct InProgressView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \MoviesToWatch.lastUpdated, order: .reverse)
    private var moviesToWatch: [MoviesToWatch]

    @Query(sort: \TVShowWatchingModel.lastUpdated, order: .reverse)
    private var tvShowsWatching: [TVShowWatchingModel]

    var body: some View {
        Group {
            if sortedItems.isEmpty {
                emptyStateView
            } else {
                List {
                    ForEach(sortedItems) { item in
                        InProgressCardView(item: item)
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .contextMenu {
                                Button {
                                    handleMarkAsWatched(item: item)
                                } label: {
                                    Label(LC.markWatched.text, systemImage: "checkmark.circle.fill")
                                }

                                Button(role: .destructive) {
                                    removeItem(item: item)
                                } label: {
                                    Label(LC.remove.text, systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(LC.inProgress.text)
        .refreshable {
            // SwiftData automatically refreshes via @Query
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Content Yet",
            systemImage: "play.circle",
            description: Text("Start tracking movies and TV shows to see them here.")
        )
    }

    private var sortedItems: [InProgressItem] {
        var items: [InProgressItem] = []

        for movie in moviesToWatch {
            items.append(InProgressItem(
                id: "movie-\(movie.id ?? 0)",
                tmdbId: Int(movie.id ?? 0),
                type: .movie,
                imageURL: URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                title: movie.name ?? "",
                subtitle: movie.overview ?? "",
                progress: nil,
                lastUpdated: movie.lastUpdated
            ))
        }

        for show in tvShowsWatching {
            let seasonNumber = show.currentSeasonNumber ?? 1
            let episodeNumber = show.currentEpisodeNumber ?? 1
            var episodeName = ""

            if let seasons = show.seasons,
               let season = seasons.first(where: { $0.seasonNumber == seasonNumber }),
               let episodes = season.episodes,
               let episode = episodes.first(where: { $0.episodeNumber == episodeNumber }) {
                episodeName = episode.name ?? ""
            }

            items.append(InProgressItem(
                id: "tv-\(show.id ?? 0)",
                tmdbId: show.id ?? 0,
                type: .tvShow(seasonNumber: seasonNumber, episodeNumber: episodeNumber, episodeName: episodeName),
                imageURL: URL(string: Constants.basePosters + (show.imagePath ?? "")),
                title: show.name ?? "",
                subtitle: show.overview ?? "",
                progress: show.currentSeasonProgress,
                lastUpdated: show.lastUpdated
            ))
        }

        return items.sorted { $0.lastUpdated > $1.lastUpdated }
    }

    private func handleMarkAsWatched(item: InProgressItem) {
        switch item.type {
        case .movie:
            markMovieAsWatched(tmdbId: item.tmdbId)
        case .tvShow(let seasonNum, let episodeNum, _):
            markEpisodeAsWatched(tmdbId: item.tmdbId, seasonNum: seasonNum, episodeNum: episodeNum)
        }
    }

    private func removeItem(item: InProgressItem) {
        switch item.type {
        case .movie:
            removeMovie(tmdbId: item.tmdbId)
        case .tvShow:
            removeTVShow(tmdbId: item.tmdbId)
        }
    }

    private func removeMovie(tmdbId: Int) {
        guard let movie = moviesToWatch.first(where: { Int($0.id ?? 0) == tmdbId }) else { return }
        modelContext.delete(movie)
        try? modelContext.save()
    }

    private func removeTVShow(tmdbId: Int) {
        guard let show = tvShowsWatching.first(where: { $0.id == tmdbId }) else { return }
        modelContext.delete(show)
        try? modelContext.save()
    }

    private func markMovieAsWatched(tmdbId: Int) {
        guard let movie = moviesToWatch.first(where: { Int($0.id ?? 0) == tmdbId }) else {
            print("Movie not found with tmdbId: \(tmdbId)")
            return
        }

        let watchedMovie = MoviesWatched(
            counter: movie.counter,
            id: movie.id,
            name: movie.name,
            overview: movie.overview,
            profilePath: movie.profilePath
        )

        modelContext.insert(watchedMovie)
        modelContext.delete(movie)

        do {
            try modelContext.save()
        } catch {
            print("Error saving: \(error)")
        }
    }

    private func markEpisodeAsWatched(tmdbId: Int, seasonNum: Int, episodeNum: Int) {
        guard let show = tvShowsWatching.first(where: { $0.id == tmdbId }) else {
            print("TV Show not found with tmdbId: \(tmdbId)")
            return
        }

        guard let seasons = show.seasons,
              let season = seasons.first(where: { $0.seasonNumber == seasonNum }),
              let episodes = season.episodes,
              let episode = episodes.first(where: { $0.episodeNumber == episodeNum }) else {
            print("Episode not found: S\(seasonNum)E\(episodeNum)")
            return
        }

        episode.isWatched = true
        episode.watchedDate = Date()
        show.lastUpdated = Date()

        if let nextEpisode = episodes.first(where: { $0.episodeNumber == episodeNum + 1 && !$0.isWatched }) {
            show.currentEpisodeNumber = nextEpisode.episodeNumber
        } else if let totalEpisodes = season.episodeCount, episodeNum < totalEpisodes {
            show.currentEpisodeNumber = episodeNum + 1
        } else {
            let sortedSeasons = seasons.sorted { ($0.seasonNumber ?? 0) < ($1.seasonNumber ?? 0) }
            if let currentSeasonIndex = sortedSeasons.firstIndex(where: { $0.seasonNumber == seasonNum }),
               currentSeasonIndex + 1 < sortedSeasons.count {
                let nextSeason = sortedSeasons[currentSeasonIndex + 1]
                show.currentSeasonNumber = nextSeason.seasonNumber
                show.currentEpisodeNumber = 1
            }
        }

        do {
            try modelContext.save()
        } catch {
            print("Error saving: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        InProgressView()
    }
    .modelContainer(for: [MoviesToWatch.self, MoviesWatched.self, TVShowWatchingModel.self])
}
