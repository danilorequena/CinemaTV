//
//  DetailMovieViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/11/21.
//

import Foundation
import SwiftUI

final class DetailViewModel: ObservableObject {
    var service = MoviesService()
    var newService: MovieServiceProtocol
    var isDetailLoading = true
    var isCastLoading = true
    @Published var detailMovie: DetailMoviesModel?
    @Published var cast: CastModel?
    @Published var dispathGroup = DispatchGroup()
    @Published var videos: [VideoResult] = []
    @Published var videoKey: String?
    
    init(newService: MovieServiceProtocol = MovieStore.shared) {
        self.newService = newService
    }
    
    func loadDetails(movieID: Int) async {
        dispathGroup.enter()
        await fetchDetail(movieID: movieID)
        dispathGroup.leave()
        
        dispathGroup.enter()
        await fetchTrailers(movieID: movieID)
        dispathGroup.leave()
    }
    
    func fetchDetail(movieID: Int) async {
        Task {
            newService.fetchDetail(from: movieID) { result in
                switch result {
                case .success(let detail):
                    self.detailMovie = detail
                    self.isDetailLoading = false
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
    
    func fetchCast(movieID: Int) async {
        Task {
            newService.fetchCast(from: MoviesEndpoint.credits(movie: movieID).path()) { result in
                switch result {
                case .success(let cast):
                    self.cast = cast
                    self.isCastLoading = false
                case .failure(let error):
                    print(error)
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
}
