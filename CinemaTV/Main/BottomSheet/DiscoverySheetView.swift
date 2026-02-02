//
//  DiscoverySheetView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct DiscoverySheetView: View {
    @Bindable var viewModel: DiscoverySheetViewModel
    @Binding var selectedDetent: PresentationDetent
    var startWithSearch: Bool = false

    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        sheetContent
            .onAppear {
                if startWithSearch {
                    // Focus search field when opened from search bar tap
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isSearchFocused = true
                    }
                }
            }
    }

    @ViewBuilder
    private var sheetContent: some View {
        GlassEffectContainer(spacing: 16) {
            navigationContent
        }
    }

    private var navigationContent: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Search bar with glass effect
                    searchBar

                    // Media type picker (only when not searching)
                    if searchText.isEmpty {
                        Picker("Media Type", selection: $viewModel.selectedMediaType) {
                            ForEach(DiscoveryMediaType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                    }

                    // Search results or discovery sections
                    if !searchText.isEmpty {
                        if !viewModel.searchResults.isEmpty {
                            searchResultsSection
                        } else if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(.top, 40)
                        } else {
                            noSearchResultsView
                        }
                    } else {
                        discoverySections
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .navigationTitle(searchText.isEmpty ? "Discover" : "Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedDetent = .height(80)
                            searchText = ""
                        }
                    } label: {
                        Label("Close", systemImage: "xmark.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                }
            }
            .toolbarBackgroundVisibility(.hidden, for: .navigationBar)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.body.weight(.medium))
                .foregroundStyle(.secondary)

            TextField("Search movies & TV shows", text: $searchText)
                .textFieldStyle(.automatic)
                .focused($isSearchFocused)
                .onSubmit {
                    viewModel.search(query: searchText)
                }
                .onChange(of: searchText) { _, newValue in
                    viewModel.search(query: newValue)
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.searchResults = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .glassEffect(.clear.interactive().tint(.clear), in: .capsule)
        .padding(.horizontal)
    }

    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundStyle(.tertiary)

            Text("No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("Try searching for a movie or TV show")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }

    @ViewBuilder
    private var discoverySections: some View {
        if viewModel.selectedMediaType == .movies {
            moviesSections
        } else {
            tvShowsSections
        }
    }

    @ViewBuilder
    private var moviesSections: some View {
        DiscoverySectionView(
            title: LC.popular.text,
            data: viewModel.popularMovies,
            state: .movie
        )

        DiscoverySectionView(
            title: LC.rated.text,
            data: viewModel.topRatedMovies,
            state: .movie
        )

        DiscoverySectionView(
            title: LC.soon.text,
            data: viewModel.upcomingMovies,
            state: .movie
        )

        DiscoverySectionView(
            title: LC.nowPlaying.text,
            data: viewModel.nowPlayingMovies,
            state: .movie
        )
    }

    @ViewBuilder
    private var tvShowsSections: some View {
        DiscoverySectionView(
            title: LC.popTVShows.text,
            data: viewModel.popularTVShows,
            state: .tvShow
        )

        DiscoverySectionView(
            title: LC.airingToday.text,
            data: viewModel.airingTodayTVShows,
            state: .tvShow
        )

        DiscoverySectionView(
            title: LC.onTheAir.text,
            data: viewModel.onTheAirTVShows,
            state: .tvShow
        )
    }

    @ViewBuilder
    private var searchResultsSection: some View {
        LazyVStack(spacing: 12) {
            ForEach(viewModel.searchResults) { result in
                NavigationLink(destination: destinationView(for: result)) {
                    HStack(spacing: 0) {
                        AsyncImage(url: URL(string: Constants.basePosters + (result.posterPath ?? ""))) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Rectangle().fill(.quaternary)
                        }
                        .frame(width: 60, height: 90)
                        .clipped()

                        HStack(spacing: 8) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(result.title ?? result.name ?? "")
                                    .font(.headline)
                                    .lineLimit(2)

                                Text(result.mediaType?.rawValue.capitalized ?? "")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                if let overview = result.overview, !overview.isEmpty {
                                    Text(overview)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .padding()
                        .frame(maxHeight: .infinity)
                        .background {
                            Rectangle()
                                .glassEffect(.regular.tint(searchResultTint(for: result).opacity(0.3)).interactive())
                        }
                    }
                    .frame(height: 90)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func destinationView(for result: MultiSearchResult) -> some View {
        if result.mediaType == .movie {
            DetailView(id: result.id ?? 0, state: .movie, showAddFavoritesButton: true)
        } else if result.mediaType == .tv {
            DetailView(id: result.id ?? 0, state: .tvShow, showAddFavoritesButton: true)
        } else {
            EmptyView()
        }
    }

    private func searchResultTint(for result: MultiSearchResult) -> Color {
        switch result.mediaType {
        case .movie:
            return GlassTint.movies.color ?? .clear
        case .tv:
            return GlassTint.tvShows.color ?? .clear
        default:
            return GlassTint.search.color ?? .clear
        }
    }
}

#Preview {
    DiscoverySheetView(
        viewModel: DiscoverySheetViewModel(),
        selectedDetent: .constant(.large)
    )
}
