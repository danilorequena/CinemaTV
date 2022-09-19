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
    @Published var discoverMovies: [MovieResult] = []
    @Published var topRatedMovies: [MovieResult] = []
    @Published var popularMovies: [MovieResult] = []
    @Published var nowPlayngMovies: [MovieResult] = []
    @Published var upcomingMovies: [MovieResult] = []
    @Published var isLoadingPage = true
    var currentPage = 0
    @Published var dispathGroup = DispatchGroup()
    var perPage = 20
    var isLastItem = false
    
    init(service: MovieServiceProtocol = MovieStore()) {
        self.service = service
    }
    
    func getMoviesList() async {
        Task {
            service.fetchDiscoverMovies(from: MoviesEndpoint.discover) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.discoverMovies = movies.results
                        self.isLoadingPage = false
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
    
    func getNowPlayngList() async {
        Task {
            service.fetchNowMovies(from: MoviesEndpoint.nowPlaying) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.nowPlayngMovies = movies.results
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
    
    func getUpcomingList() async {
        Task {
            service.fetchNowMovies(from: MoviesEndpoint.upcoming) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.upcomingMovies = movies.results
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
    
    func getTopVotedList() async {
        Task {
            service.fetchTopMovies(from: MoviesEndpoint.toRated) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.topRatedMovies = movies.results
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
    
    func getPopularList() async {
        Task {
            service.fetchDiscoverMovies(from: MoviesEndpoint.popular) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.popularMovies = movies.results
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
    
    private func hideLoading() {
        if !discoverMovies.isEmpty && !popularMovies.isEmpty && !topRatedMovies.isEmpty && !nowPlayngMovies.isEmpty && !upcomingMovies.isEmpty {
            isLoadingPage = false
        }
    }
}
