//
//  HomeViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation
import SwiftUI

final class HomeViewModel: ObservableObject {
    var service: MovieServiceProtocol
    @Published var discoverMovies: [MoviesTVShowResult] = []
    @Published var topRatedMovies: [MoviesTVShowResult] = []
    @Published var popularMovies: [MoviesTVShowResult] = []
    @Published var nowPlayngMovies: [MoviesTVShowResult] = []
    @Published var upcomingMovies: [MoviesTVShowResult] = []
    @Published var isLoadingPage = true
    var currentPage = 0
    @Published var dispathGroup = DispatchGroup()
    var perPage = 20
    var isLastItem = false
    
    init(service: MovieServiceProtocol = MovieStore()) {
        self.service = service
    }
    
    func getAllData(with enpoint: MoviesEndpoint) async {
        Task {
            service.fetchDiscoverMovies(from: enpoint, page: String(1)) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.handleData(endpoint: enpoint, movies: movies)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
    
    private func handleData(endpoint: MoviesEndpoint, movies: DiscoverMovies) {
        switch endpoint {
        case .discover:
            self.discoverMovies = movies.results
            self.isLoadingPage = false
        case .nowPlaying:
            self.nowPlayngMovies = movies.results
            self.isLoadingPage = false
        case .popular:
            self.popularMovies = movies.results
            self.isLoadingPage = false
        case .upcoming:
            self.upcomingMovies = movies.results
            self.isLoadingPage = false
        case .toRated:
            self.topRatedMovies = movies.results
            self.isLoadingPage = false
        default:
            break
        }
    }
    
    private func hideLoading() {
        if !discoverMovies.isEmpty && !popularMovies.isEmpty && !topRatedMovies.isEmpty && !nowPlayngMovies.isEmpty && !upcomingMovies.isEmpty {
            isLoadingPage = false
        }
    }
}
