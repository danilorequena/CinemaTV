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
    
    func fetchDetail(movieID: Int) async {
        Task.init {
            dispathGroup.enter()
            let result = try await MoviesService.loadDetail(from: MoviesEndpoint.detail(movie: movieID).path())
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
