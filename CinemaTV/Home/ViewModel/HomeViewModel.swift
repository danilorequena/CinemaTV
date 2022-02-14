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
    @Published var discoverMovies = [MoviesResult]()
    @Published var topRatedMovies: [MoviesResult] = []
    @Published var latestMovies: [MoviesResult] = []
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
    
    func loadComponents(currentItem item: MoviesResult?) {
        guard let item = item else {
            loadMoreContent()
            return
        }
        let thresholdIndex = discoverMovies.index(discoverMovies.endIndex, offsetBy: -5)
            loadMoreContent()
    }
    
    func loadMoreContent() {
        DispatchQueue.main.async {
            self.dispathGroup.enter()
            self.getMoviesList()
            self.dispathGroup.leave()
            
            self.dispathGroup.enter()
            self.getUpcomingList()
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
//                DispatchQueue.main.async {
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.discoverMovies += movies.results
                        self.isLoadingPage = false
//                    }
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
            let result = try await MoviesService.newloadMovies(page: "1", from: MoviesEndpoint.toRated.path())
            switch result {
            case .success(let movies):
//                DispatchQueue.main.async {
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.topRatedMovies = movies.results
                    }
//                }
            case .failure(let error):
                print(error.localizedDescription)
                self.dispathGroup.leave()
            }
        }
    }
    
    func getUpcomingList() {
        Task.init {
            self.dispathGroup.enter()
            let result = try await MoviesService.loadLatest(from: MoviesEndpoint.upcoming.path())
            switch result {
            case .success(let movies):
//                DispatchQueue.main.async {
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.latestMovies = movies.results
                    }
//                }
            case .failure(let error):
                print(error.localizedDescription)
                self.dispathGroup.leave()
            }
        }
    }
}
