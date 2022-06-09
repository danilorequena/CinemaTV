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
    @Published var discoverMovies: [MovieResult] = []
    @Published var topRatedMovies: [MovieResult] = []
    @Published var popularMovies: [MovieResult] = []
    @Published var nowPlayngMovies: [MovieResult] = []
    @Published var upcomingMovies: [MovieResult] = []
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
        self.dispathGroup.enter()
        self.getMoviesList()
        self.dispathGroup.leave()
        
        self.dispathGroup.enter()
        self.getNowPlayngList()
        self.dispathGroup.leave()
        
        self.dispathGroup.enter()
        self.getUpcomingList()
        self.dispathGroup.leave()
        
        self.dispathGroup.enter()
        self.getPopularList()
        self.dispathGroup.leave()
        
        self.dispathGroup.enter()
        self.getTopVotedList()
        self.dispathGroup.leave()
        
        self.dispathGroup.enter()
        self.hideLoading()
        self.dispathGroup.leave()
    }
    
    func getMoviesList() {
        MovieStore.shared.fetchDiscoverMovies(from: MoviesEndpoint.discover) { result in
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
    
    func getNowPlayngList() {
        MovieStore.shared.fetchNowMovies(from: MoviesEndpoint.nowPlaying) { result in
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
    
    func getUpcomingList() {
        MovieStore.shared.fetchNowMovies(from: MoviesEndpoint.upcoming) { result in
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
    
    func getTopVotedList() {
        MovieStore.shared.fetchTopMovies(from: MoviesEndpoint.toRated) { result in
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
    
    func getPopularList() {
        MovieStore.shared.fetchDiscoverMovies(from: MoviesEndpoint.popular) { result in
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
    
    private func hideLoading() {
        if !discoverMovies.isEmpty && !popularMovies.isEmpty && !topRatedMovies.isEmpty && !nowPlayngMovies.isEmpty && !upcomingMovies.isEmpty {
            isLoadingPage = false
        }
    }
}
