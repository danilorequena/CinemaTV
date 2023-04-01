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
    var service = MoviesService()
    var newService: MovieServiceProtocol
    var tvShowService: TVShowServiceProtocol
    var isDetailLoading = true
    var isCastLoading = true
    @Published var detailMovie: DetailMoviesModel?
    @Published var detailTVShow: DetailTVShow?
    @Published var cast: CastModel?
    @Published var providers: ProvidersData?
    @Published var tvShowsRecommendations: DiscoverTVShow?
    @Published var moviesRecommendations: DiscoverMovies?
    @Published var tvShowsSimilars: DiscoverTVShow?
    @Published var moviesSimilars: DiscoverMovies?
    @Published var dispathGroup = DispatchGroup()
    @Published var videos: [VideoResult] = []
    @Published var videoKey: String?
    
    init(
        newService: MovieServiceProtocol = MovieStore.shared,
        tvShowService: TVShowServiceProtocol = TVShowStore.shared
    ) {
        self.newService = newService
        self.tvShowService = tvShowService
    }
    
    func loadDetails(ID: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            dispathGroup.enter()
            await fetchDetail(movieID: ID)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchTrailers(movieID: ID)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchCast(id: ID, state: state)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchWatchProviders(id: ID, state: .movie)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchRecommendations(id: ID, state: .movie)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchSimilars(id: ID, state: .movie)
            dispathGroup.leave()
            
        case .tvShow:
            dispathGroup.enter()
            await fetchTVShowDetail(tvShowID: ID)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchTrailers(movieID: ID)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchCast(id: ID, state: state)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchRecommendations(id: ID, state: .tvShow)
            dispathGroup.leave()
            
            dispathGroup.enter()
            await fetchSimilars(id: ID, state: .tvShow)
            dispathGroup.leave()
        }
    }
    
    func fetchDetail(movieID: Int) async {
        Task {
            newService.fetchDetail(from: MoviesEndpoint.detail(movie: movieID).path()) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let detail):
                    DispatchQueue.main.async {
                        self.detailMovie = detail
                        self.isDetailLoading = false
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
        
//        MovieStore.shared.fetchDetail(from: movieID) { result in
//            self.dispathGroup.enter()
//            switch result {
//            case .success(let movies):
//                self.dispathGroup.leave()
//                self.dispathGroup.notify(queue: .main) {
//                    self.detailMovie = movies
//                    self.isDetailLoading = false
//                }
//            case .failure(let error):
//                print(error.localizedDescription)
//                self.dispathGroup.leave()
//            }
//        }
    }
    
    func fetchTVShowDetail(tvShowID: Int) async {
        Task {
            newService.fetchTVShowDetail(from: MoviesEndpoint.detailTVShow(tvShow: tvShowID).path()) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let detail):
                    DispatchQueue.main.async {
                        self.detailTVShow = detail
                        self.isDetailLoading = false
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
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
//        MovieStore.shared.fetchTrailer(from: MoviesEndpoint.videos(videoID: movieID).path()) { result in
//            self.dispathGroup.enter()
//            switch result {
//            case .success(let videos):
//                self.dispathGroup.leave()
//                self.dispathGroup.notify(queue: .main) {
//                    let videosSorted = videos.results.filter{$0.type == "Trailer"}
//                    self.videos.append(contentsOf: videosSorted)
//                    self.videoKey = videosSorted.first?.key ?? ""
//                }
//            case .failure(let error):
//                print(error.localizedDescription)
//                self.dispathGroup.leave()
//            }
//        }
    }
    
    func fetchRecommendations(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchRecommendations(from: MoviesEndpoint.recommended(movie: id)) { result in
                    switch result {
                    case .success(let recommendations):
                        DispatchQueue.main.async {
                            self.moviesRecommendations = recommendations
                        }
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
                        DispatchQueue.main.async {
                            self.tvShowsRecommendations = recommendations
                        }
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        }
    }
    
    func fetchSimilars(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchSimilars(from: MoviesEndpoint.similar(movie: id)) { result in
                    switch result {
                    case .success(let similars):
                        DispatchQueue.main.async {
                            self.moviesSimilars = similars
                        }
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
                        DispatchQueue.main.async {
                            self.tvShowsSimilars = similars
                        }
                    case .failure(let failure):
                        print(failure)
                    }
                }
            }
        }
    }
    
    func fetchCast(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchCast(from: MoviesEndpoint.credits(movie: id).path()) { result in
                    switch result {
                    case .success(let cast):
                        DispatchQueue.main.async {
                            self.cast = cast
                            self.isCastLoading = false
                        }
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
                        DispatchQueue.main.async {
                            self.cast = cast
                            self.isCastLoading = false
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
        }
//        MovieStore.shared.fetchCast(from: MoviesEndpoint.credits(movie: movieID).path()) { result in
//            self.dispathGroup.enter()
//            switch result {
//            case .success(let cast):
//                self.dispathGroup.leave()
//                self.dispathGroup.notify(queue: .main) {
//                    self.cast = cast
//                    self.isCastLoading = false
//                }
//            case .failure(let error):
//                print(error.localizedDescription)
//                self.dispathGroup.leave()
//            }
//        }
    }
    
    func fetchWatchProviders(id: Int, state: MovieORTVShow) async {
        switch state {
        case .movie:
            Task {
                newService.fetchDetailWatchProviders(from: MoviesEndpoint.watchProviders(movieID: id).path()) { result in
                    switch result {
                    case .success(let providers):
                        DispatchQueue.main.async {
                            self.providers = providers.results?.br
                            self.isCastLoading = false
                        }
                    case .failure(let error):
                        print(error.localizedDescription)
                    }
                }
            }
        case .tvShow:
//            Task {
//                newService.fetchCast(from: TVShowsEndpoint.credits(tvShow: id).path()) { result in
//                    switch result {
//                    case .success(let cast):
//                        DispatchQueue.main.async {
//                            self.cast = cast
//                            self.isCastLoading = false
//                        }
//                    case .failure(let error):
//                        print(error)
//                    }
//                }
//            }
            break
        }
    }
}
