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
    var isLoading = true
    @Published var detailMovie: DetailMoviesModel?
    @Published var cast: CastModel?
    @Published var dispathGroup = DispatchGroup()
    @Published var videos: [VideoResult] = []
    @Published var videoKey: String?
    
    func loadDetails(movieID: Int) async {
        dispathGroup.enter()
        await fetchDetail(movieID: movieID)
        dispathGroup.leave()
        
        dispathGroup.enter()
        await fetchTrailers(movieID: movieID)
        dispathGroup.leave()
    }
    
    func fetchDetail(movieID: Int) async {
        Task.init {
            dispathGroup.enter()
            let result = try await MovieStore.shared.fetchDetail(from: movieID, completion: { result in
                switch result {
                case .success(let movie):
                    self.dispathGroup.notify(queue: .main) {
                        self.detailMovie = movie
                    }
                    self.dispathGroup.leave()
                    self.isLoading = false
                case .failure(let error):
                    print(error)
                    self.dispathGroup.leave()
                }
            })
        }
    }
    
    func fetchTrailers(movieID: Int) async {
        Task.init {
            dispathGroup.enter()
            let result = try await MoviesService.loadTrailer(from: MoviesEndpoint.videos(videoID: movieID).path())
            switch result {
            case .success(let videos):
                self.dispathGroup.notify(queue: .main) {
                    let videosSorted = videos.results.filter{$0.type == "Trailer"}
                    self.videos.append(contentsOf: videosSorted)
                    self.videoKey = videosSorted.first?.key ?? ""
                }
                self.dispathGroup.leave()
                
            case .failure(let error):
                print(error)
                self.dispathGroup.leave()
            }
        }
    }
    
    func fetchCast(movieID: Int) async {
        Task.init {
            dispathGroup.enter()
            let result = try await CastService.loadCast(from: MoviesEndpoint.credits(movie: movieID).path())
            switch result {
            case .success(let cast):
                self.dispathGroup.notify(queue: .main) {
                    self.cast = cast
                }
                self.dispathGroup.leave()
                
            case .failure(let error):
                print(error)
                self.dispathGroup.leave()
            }
        }
    }
}
