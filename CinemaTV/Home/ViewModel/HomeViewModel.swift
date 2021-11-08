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
    var perPage = 20
    var currentPage = 1
    var listFull = false
    @Published var dispathGroup = DispatchGroup()
    @State private var isLoading = true
    
    func loadComponents() async {
        dispathGroup.enter()
        await getMoviesList()
        dispathGroup.leave()
        
        dispathGroup.enter()
        await getTopVotedList()
        dispathGroup.leave()
    }
    
    func getMoviesList() async {
        Task.init {
            self.dispathGroup.enter()
            let result = try await MoviesService.newloadMovies(from: MoviesEndpoint.discover.path())
            switch result {
            case .success(let movies):
                DispatchQueue.main.async {
//                    if self.movies.count < self.perPage {
//                        self.listFull = true
//                    }
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.discoverMovies = movies.results
                    }
                    self.isLoading = false
                }
            case .failure(let error):
                print(error.localizedDescription)
                self.dispathGroup.leave()
            }
        }
    }
    
    func getTopVotedList() async {
        Task.init {
            self.dispathGroup.enter()
            let result = try await MoviesService.newloadMovies(from: MoviesEndpoint.toRated.path())
            switch result {
            case .success(let movies):
                DispatchQueue.main.async {
//                    if self.movies.count < self.perPage {
//                        self.listFull = true
//                    }
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.topRatedMovies = movies.results
                    }
                }
            case .failure(let error):
                print(error.localizedDescription)
                self.dispathGroup.leave()
            }
        }
    }
}
