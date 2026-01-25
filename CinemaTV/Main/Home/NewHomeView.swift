//
//  NewHomeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI
import SwiftData

struct NewHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: \MoviesToWatch.name) private var moviesToWatch: [MoviesToWatch]
    @Query(sort: \MoviesWatched.name) private var moviesWatched: [MoviesWatched]
    @Query(sort: \TVShowWatchingModel.name) private var tvShowsWatching: [TVShowWatchingModel]

    @Binding var sheetDetent: PresentationDetent

    private var hasContent: Bool {
        !moviesToWatch.isEmpty || !moviesWatched.isEmpty || !tvShowsWatching.isEmpty
    }

    private var totalWatchedMinutes: Int {
        moviesWatched.reduce(0) { $0 + Int($1.counter ?? 0) }
    }

    var body: some View {
        NavigationStack {
            mainContent
                .background {
                LinearGradient(
                    colors: colorScheme == .dark ? [.gray.opacity(0.3), .black] : [.gray.opacity(0.1), .white],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            }
            .navigationTitle("My Library")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    NavigationLink(destination: CreditsView()) {
                        Label("Info", systemImage: "info.circle")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        GlassEffectContainer(spacing: 20) {
            if hasContent {
                contentView
            } else {
                EmptyStateView {
                    withAnimation(.spring(response: 0.4)) {
                        sheetDetent = .large
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Featured card - most recently active content
                if let featured = getFeaturedContent() {
                    FeaturedCardView(
                        imageURL: featured.imageURL,
                        title: featured.title,
                        subtitle: featured.subtitle,
                        progress: featured.progress
                    ) {
                        // Navigation handled by NavigationLink wrapper
                    }
                    .padding(.horizontal)
                }

                // Currently Watching TV Shows
                if !tvShowsWatching.isEmpty {
                    TrackedContentRow(title: "Currently Watching", tvShows: tvShowsWatching)
                }

                // Movies to Watch
                if !moviesToWatch.isEmpty {
                    TrackedContentRow(title: "Want to Watch", movies: moviesToWatch)
                }

                // Movies Watched
                if !moviesWatched.isEmpty {
                    TrackedContentRow(title: "Watched", movies: moviesWatched)
                }

                // Stats card
                statsCard

                // Spacer for bottom sheet
                Color.clear.frame(height: 100)
            }
            .padding(.vertical)
        }
        .refreshable {
            // SwiftData automatically refreshes via @Query
        }
        .scrollIndicators(.hidden)
    }

    private var inProgressCount: Int {
        moviesToWatch.count + tvShowsWatching.count
    }

    private var statsCard: some View {
        GlassCardView(cornerRadius: 16, tint: .stats) {
            VStack(spacing: 16) {
                Text("Your Stats")
                    .font(.headline)

                HStack(spacing: 32) {
                    StatItem(
                        icon: "film",
                        value: "\(moviesWatched.count)",
                        label: "Movies"
                    )

                    StatItem(
                        icon: "tv",
                        value: "\(tvShowsWatching.count)",
                        label: "Shows"
                    )

                    StatItem(
                        icon: "clock",
                        value: formatWatchTime(totalWatchedMinutes),
                        label: "Total"
                    )
                }

                if inProgressCount > 0 {
                    Divider()

                    NavigationLink(destination: InProgressView()) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .foregroundStyle(Color.accentColor)
                            Text(LC.inProgress.text)
                            Spacer()
                            Text("\(inProgressCount)")
                                .foregroundStyle(.secondary)
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
        }
        .padding(16)
    }

    private func getFeaturedContent() -> (imageURL: URL?, title: String, subtitle: String, progress: Double?)? {
        // Priority: Currently watching TV show > Movie to watch > Recently watched
        if let show = tvShowsWatching.first {
            return (
                URL(string: Constants.basePosters + (show.imagePath ?? "")),
                show.name ?? "TV Show",
                show.overview ?? "",
                calculateTVShowProgress(show)
            )
        }

        if let movie = moviesToWatch.first {
            return (
                URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                movie.name ?? "Movie",
                movie.overview ?? "",
                nil
            )
        }

        if let movie = moviesWatched.first {
            return (
                URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                movie.name ?? "Movie",
                movie.overview ?? "",
                1.0 // Completed
            )
        }

        return nil
    }

    private func calculateTVShowProgress(_ show: TVShowWatchingModel) -> Double? {
        return show.currentSeasonProgress
    }

    private func formatWatchTime(_ minutes: Int) -> String {
        let hours = minutes / 60
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(minutes)m"
    }
}

// MARK: - Supporting Views

struct StatItem: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.title3.bold())

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    NewHomeView(sheetDetent: .constant(.height(80)))
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self, TVShowWatchingModel.self])
}
