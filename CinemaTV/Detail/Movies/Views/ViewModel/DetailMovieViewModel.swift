//
//  DetailMovieViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/11/21.
//

import Foundation
import SwiftUI

enum MovieORTVShow {
    case movie
    case tvShow
}

final class DetailViewModel: ObservableObject {
    @Published var detailMovie: DetailMoviesModel?
    @Published var detailTVShow: DetailTVShow?
    @Published var cast: CastModel?
    @Published var providers: ProvidersData?
    @Published var tvShowsRecommendations: DiscoverTVShow?
    @Published var moviesRecommendations: DiscoverMovies?
    @Published var tvShowsSimilars: DiscoverTVShow?
    @Published var moviesSimilars: DiscoverMovies?
    @Published var videos: [VideoResult] = []
    @Published var videoKey: String?
    
    var service = MoviesService()
    var newService: MovieServiceProtocol
    var tvShowService: TVShowServiceProtocol
    var isDetailLoading = true
    var isCastLoading = true
    
    init(
        newService: MovieServiceProtocol = MovieStore.shared,
        tvShowService: TVShowServiceProtocol = TVShowStore.shared
    ) {
        self.newService = newService
        self.tvShowService = tvShowService
    }
    
    @MainActor
    func loadDetails(ID: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            await fetchDetail(movieID: ID)
            await fetchTrailers(movieID: ID)
            await fetchCast(id: ID, state: state)
            await fetchWatchProviders(id: ID, state: .movie)
            await fetchRecommendations(id: ID, state: .movie)
            await fetchSimilars(id: ID, state: .movie)
        case .tvShow:
            await fetchTVShowDetail(tvShowID: ID)
            await fetchTrailers(movieID: ID)
            await fetchCast(id: ID, state: state)
            await fetchRecommendations(id: ID, state: .tvShow)
            await fetchSimilars(id: ID, state: .tvShow)
        }
    }
    
    @MainActor
    func fetchDetail(movieID: Int) async {
        newService.fetchDetail(from: MoviesEndpoint.detail(movie: movieID).path()) { result in
            switch result {
            case .success(let detail):
                self.detailMovie = detail
                self.isDetailLoading = false
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func fetchTVShowDetail(tvShowID: Int) async {
        Task {
            newService.fetchTVShowDetail(from: MoviesEndpoint.detailTVShow(tvShow: tvShowID).path()) { result in
                switch result {
                case .success(let detail):
                    self.detailTVShow = detail
                    self.isDetailLoading = false
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    @MainActor
    func fetchTrailers(movieID: Int) async {
        Task {
            newService.fetchTrailer(from: MoviesEndpoint.videos(videoID: movieID).path()) { result in
                switch result {
                case .success(let videos):
                    let videosSorted = videos.results.filter{$0.type == "Trailer"}
                    self.videos.append(contentsOf: videosSorted)
                    self.videoKey = videosSorted.first?.key ?? ""
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    @MainActor
    func fetchRecommendations(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchRecommendations(from: MoviesEndpoint.recommended(movie: id)) { result in
                    switch result {
                    case .success(let recommendations):
                        self.moviesRecommendations = recommendations
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        case .tvShow:
            Task {
                tvShowService.fetchRecommendations(from: TVShowsEndpoint.recommendations(tvShowID: id)) { result in
                    switch result {
                    case .success(let recommendations):
                        self.tvShowsRecommendations = recommendations
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        }
    }
    
    @MainActor
    func fetchSimilars(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchSimilars(from: MoviesEndpoint.similar(movie: id)) { result in
                    switch result {
                    case .success(let similars):
                        self.moviesSimilars = similars
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        case .tvShow:
            Task {
                tvShowService.fetchSimilars(from: TVShowsEndpoint.similar(movie: id)) { result in
                    switch result {
                    case .success(let similars):
                        self.tvShowsSimilars = similars
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        }
    }
    
    @MainActor
    func fetchCast(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchCast(from: MoviesEndpoint.credits(movie: id).path()) { result in
                    switch result {
                    case .success(let cast):
                        self.cast = cast
                        self.isCastLoading = false
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        case .tvShow:
            Task {
                newService.fetchCast(from: TVShowsEndpoint.credits(tvShow: id).path()) { result in
                    switch result {
                    case .success(let cast):
                        self.cast = cast
                        self.isCastLoading = false
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
    }
    
    @MainActor
    func fetchWatchProviders(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchDetailWatchProviders(from: MoviesEndpoint.watchProviders(movieID: id).path()) { result in
                    switch result {
                    case .success(let providers):
                        self.providers = providers.results?.br
                        self.isCastLoading = false
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        case .tvShow:
            break
        }
    }
}
