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
    @Published var endpointToLoadMore: MoviesEndpoint?
    var currentPage = 1
    var isLastItem = false
    
    func loadData(endpoint: MoviesEndpoint) {
        loadDiscoverMovies(endpoint: endpoint)
    }
    
    func loadDiscoverMovies(endpoint: MoviesEndpoint) {
        movies.removeAll()
        currentPage = 1
        isLoadingPage = true
        MovieStore.shared.fetchDiscoverMovies(from: endpoint, page: String(currentPage)) { result in
            switch result {
            case .success(let movies):
                self.movies.append(contentsOf: movies.results)
                self.isLoadingPage = false
                print("Quantidade de filmes: \(self.movies.count)")
                print("pagina: \(self.currentPage)")
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    @MainActor
    func loadMoreMovies() {
        currentPage += 1
        MovieStore.shared.fetchDiscoverMovies(from: endpointToLoadMore ?? .discover, page: String(currentPage)) { result in
            switch result {
            case .success(let movies):
                self.movies.append(contentsOf: movies.results)
                self.isLoadingPage = false
                print("Quantidade de filmes: \(self.movies.count)")
                print("pagina: \(self.currentPage)")
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func hasReachedEnd(of movie: MoviesTVShowResult) -> Bool {
        movies.last?.id == movie.id
    }
}
