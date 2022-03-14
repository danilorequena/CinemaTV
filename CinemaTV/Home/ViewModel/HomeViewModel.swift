//
//  HomeViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation
import SwiftUI

final class HomeViewModel: ObservableObject {
    var service = MoviesService()
    @Published var discoverMovies: [MoviesResult] = []
    @Published var topRatedMovies: [MoviesResult] = []
    @Published var popularMovies: [MoviesResult] = []
    @Published var nowPlayngMovies: [MoviesResult] = []
    @Published var isLoadingPage = true
    var currentPage = 0
    var canloadMorePages = true
    @Published var dispathGroup = DispatchGroup()
    @State private var isLoading = true
    var perPage = 20
    var isLastItem = false
    
    init() {
        loadMoreContent()
    }
    
    func loadMoreContent() {
        DispatchQueue.main.async {
            self.dispathGroup.enter()
            self.getNowPlayngList()
            self.dispathGroup.leave()
            
            self.dispathGroup.enter()
            self.getMoviesList()
            self.dispathGroup.leave()
            
            self.dispathGroup.enter()
            self.getPopularList()
            self.dispathGroup.leave()
            
            self.dispathGroup.enter()
            self.getTopVotedList()
            self.dispathGroup.leave()
        }
    }
    
    func getMoviesList() {
        Task.init {
            self.dispathGroup.enter()
            let result = try await MoviesService.newloadMovies(page: "\(currentPage + 1)", from: MoviesEndpoint.discover.path())
            switch result {
            case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.discoverMovies += movies.results
                        self.isLoadingPage = false
                    print("Quantidade de filmes: \(self.discoverMovies.count)")
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func getTopVotedList() {
        Task.init {
            self.dispathGroup.enter()
            let result = try await MoviesService.newloadMovies(page: "\(currentPage + 1)", from: MoviesEndpoint.toRated.path())
            switch result {
            case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.topRatedMovies += movies.results
                        self.isLoadingPage = false
                    }
            case .failure(let error):
                print(error.localizedDescription)
                self.dispathGroup.leave()
            }
        }
    }
    
    func getPopularList() {
        // chamada sem async já com novo service
        MovieStore.shared.fetchMovies(from: MoviesEndpoint.popular) { result in
            self.dispathGroup.enter()
            switch result {
            case .success(let movies):
                self.dispathGroup.leave()
                self.dispathGroup.notify(queue: .main) {
                    self.popularMovies = movies.results
                    self.isLoadingPage = false
                }
            case .failure(let error):
                print(error.localizedDescription)
                self.dispathGroup.leave()
            }
        }
    }
    
    func getNowPlayngList() {
        Task.init {
            self.dispathGroup.enter()
            let result = try await MoviesService.newloadMovies(page: "\(currentPage + 1)", from: MoviesEndpoint.nowPlaying.path())
            switch result {
            case .success(let movies):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.nowPlayngMovies += movies.results
                        self.isLoadingPage = false
                    }
            case .failure(let error):
                print(error.localizedDescription)
                self.dispathGroup.leave()
            }
        }
    }
}
