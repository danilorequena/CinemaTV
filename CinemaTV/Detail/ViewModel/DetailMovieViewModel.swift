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
    @Published var detailMovie: DetailMoviesModel?

    @State private var isLoading = true
    
    func fetchDetail(movieID: Int) async {
        Task.init {
            let result = try await MoviesService.loadDetail(from: MoviesEndpoint.detail(movie: movieID).path())
            switch result {
            case .success(let movie):
                DispatchQueue.main.async {
                    self.detailMovie = movie
                }
                
            case .failure(let error):
                print(error)
            }
        }
    }
}
