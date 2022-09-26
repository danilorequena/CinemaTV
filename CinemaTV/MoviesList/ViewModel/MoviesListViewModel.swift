//
//  MoviesListViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 23/02/22.
//

import Foundation
import SwiftUI


final class MoviesListViewModel: ObservableObject {
    var service = MoviesService()
    @Published var movies = [MoviesTVShowResult]()
    @Published var isLoadingPage = true
    var currentPage = 1
    var isLastItem = false
    
//    init() {
////        loadData(endpoint: <#T##MoviesEndpoint#>)
//    }
    
    func loadData(endpoint: MoviesEndpoint) {
        loadDiscoverMovies(endpoint: endpoint)
    }
    func loadDiscoverMovies(endpoint: MoviesEndpoint) {
        movies = []
        isLoadingPage = true
        MovieStore.shared.fetchDiscoverMovies(from: endpoint) { result in
            switch result {
            case .success(let movies):
                self.movies += movies.results
                self.isLoadingPage = false
                self.currentPage += 1
                print("Quantidade de filmes: \(self.movies.count)")
                print("pagina: \(self.currentPage)")
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
