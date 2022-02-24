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
    @Published var discoverMovies: [MoviesResult] = []
    @Published var topRatedMovies: [MoviesResult] = []
    @Published var upcomingMovies: [MoviesResult] = []
    @Published var nowPlayngMovies: [MoviesResult] = []
    @Published var isLoadingPage = true
    var currentPage = 1
    var isLastItem = false
    
    func loadData(state: MoviesState) {
        switch state {
        case .discover:
            loadDiscoverMovies()
        case .upcoming:
            loadUpcomingMovies()
        case .topVoted:
            loadTopRatedMovies()
        case .nowPlaying:
            loadNowPlayingMovies()
        }
    }
    
    func loadDiscoverMovies() {
        MoviesListService.loadMovies(
            page: "\(currentPage)",
            endPoint: .discover
        ) { (result: Result<DiscoverMovie, APIServiceError>) in
            switch result {
            case .success(let movies):
                DispatchQueue.main.async {
                    self.discoverMovies += movies.results
                    self.isLoadingPage = false
                    self.currentPage += 1
                    print("Quantidade de filmes: \(self.discoverMovies.count)")
                    print("pagina: \(self.currentPage)")
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func loadUpcomingMovies() {
        MoviesListService.loadMovies(
            page: "\(currentPage)",
            endPoint: .upcoming
        ) { (result: Result<DiscoverMovie, APIServiceError>) in
            switch result {
            case .success(let movies):
                DispatchQueue.main.async {
                    self.upcomingMovies += movies.results
                    self.isLoadingPage = false
                    self.currentPage += 1
                    print("Quantidade de filmes: \(self.discoverMovies.count)")
                    print(self.currentPage)
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func loadTopRatedMovies() {
        MoviesListService.loadMovies(
            page: "\(currentPage)",
            endPoint: .toRated
        ) { (result: Result<DiscoverMovie, APIServiceError>) in
            switch result {
            case .success(let movies):
                DispatchQueue.main.async {
                    self.topRatedMovies += movies.results
                    self.isLoadingPage = false
                    self.currentPage += 1
                    print("Quantidade de filmes: \(self.discoverMovies.count)")
                    print(self.currentPage)
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func loadNowPlayingMovies() {
        MoviesListService.loadMovies(
            page: "\(currentPage)",
            endPoint: .nowPlaying
        ) { (result: Result<DiscoverMovie, APIServiceError>) in
            switch result {
            case .success(let movies):
                DispatchQueue.main.async {
                    self.nowPlayngMovies += movies.results
                    self.isLoadingPage = false
                    self.currentPage += 1
                    print("Quantidade de filmes: \(self.discoverMovies.count)")
                    print(self.currentPage)
                }
                
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
