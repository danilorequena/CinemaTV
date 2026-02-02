//
//  DiscoverySheetViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import Foundation
import SwiftUI

enum DiscoveryMediaType: String, CaseIterable {
    case movies = "Movies"
    case tvShows = "TV Shows"
}

@MainActor
@Observable
final class DiscoverySheetViewModel {
    // Movies
    var discoverMovies: [MoviesTVShowResult] = []
    var upcomingMovies: [MoviesTVShowResult] = []
    var nowPlayingMovies: [MoviesTVShowResult] = []
    var popularMovies: [MoviesTVShowResult] = []
    var topRatedMovies: [MoviesTVShowResult] = []

    // TV Shows
    var discoverTVShows: [MoviesTVShowResult] = []
    var airingTodayTVShows: [MoviesTVShowResult] = []
    var onTheAirTVShows: [MoviesTVShowResult] = []
    var popularTVShows: [MoviesTVShowResult] = []

    // State
    var selectedMediaType: DiscoveryMediaType = .movies
    var isLoading = false

    // Search
    var searchResults: [MultiSearchResult] = []

    private let movieService: MovieServiceProtocol
    private let tvShowService: TVShowServiceProtocol

    init(
        movieService: MovieServiceProtocol = MovieStore(),
        tvShowService: TVShowServiceProtocol = TVShowStore.shared
    ) {
        self.movieService = movieService
        self.tvShowService = tvShowService
    }

    func loadAllData() async {
        isLoading = true

        async let moviesTask: () = loadMovies()
        async let tvShowsTask: () = loadTVShows()

        _ = await (moviesTask, tvShowsTask)

        isLoading = false
    }

    private func loadMovies() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchMovies(endpoint: .discover) }
            group.addTask { await self.fetchMovies(endpoint: .upcoming) }
            group.addTask { await self.fetchMovies(endpoint: .nowPlaying) }
            group.addTask { await self.fetchMovies(endpoint: .popular) }
            group.addTask { await self.fetchMovies(endpoint: .toRated) }
        }
    }

    private func loadTVShows() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchTVShows(endpoint: .discover) }
            group.addTask { await self.fetchTVShows(endpoint: .airingToday) }
            group.addTask { await self.fetchTVShows(endpoint: .nowPlaying) }
            group.addTask { await self.fetchTVShows(endpoint: .popular) }
        }
    }

    private func fetchMovies(endpoint: MoviesEndpoint) async {
        await withCheckedContinuation { continuation in
            movieService.fetchDiscoverMovies(from: endpoint, page: "1") { [weak self] result in
                guard let self else {
                    continuation.resume()
                    return
                }

                switch result {
                case .success(let movies):
                    Task { @MainActor in
                        self.handleMoviesData(endpoint: endpoint, movies: movies)
                        continuation.resume()
                    }
                case .failure(let error):
                    print("Error fetching movies: \(error.localizedDescription)")
                    continuation.resume()
                }
            }
        }
    }

    private func fetchTVShows(endpoint: TVShowsEndpoint) async {
        await withCheckedContinuation { continuation in
            tvShowService.fetchDiscoverTVShows(from: endpoint) { [weak self] result in
                guard let self else {
                    continuation.resume()
                    return
                }

                switch result {
                case .success(let tvShows):
                    Task { @MainActor in
                        self.handleTVShowsData(endpoint: endpoint, tvShows: tvShows)
                        continuation.resume()
                    }
                case .failure(let error):
                    print("Error fetching TV shows: \(error.localizedDescription)")
                    continuation.resume()
                }
            }
        }
    }

    private func handleMoviesData(endpoint: MoviesEndpoint, movies: DiscoverMovies) {
        switch endpoint {
        case .discover:
            discoverMovies = movies.results
        case .nowPlaying:
            nowPlayingMovies = movies.results
        case .popular:
            popularMovies = movies.results
        case .upcoming:
            upcomingMovies = movies.results
        case .toRated:
            topRatedMovies = movies.results
        default:
            break
        }
    }

    private func handleTVShowsData(endpoint: TVShowsEndpoint, tvShows: DiscoverTVShow) {
        switch endpoint {
        case .discover:
            discoverTVShows = tvShows.results ?? []
        case .nowPlaying:
            onTheAirTVShows = tvShows.results ?? []
        case .popular:
            popularTVShows = tvShows.results ?? []
        case .airingToday:
            airingTodayTVShows = tvShows.results ?? []
        default:
            break
        }
    }

    func search(query: String) {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        movieService.fetchMultiSearch(from: MoviesEndpoint.multiSearch.path(), query: query) { [weak self] result in
            switch result {
            case .success(let response):
                Task { @MainActor in
                    self?.searchResults = response.results ?? []
                }
            case .failure(let error):
                print("Search error: \(error.localizedDescription)")
            }
        }
    }
}
