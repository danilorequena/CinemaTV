//
//  SearchViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/07/22.
//

import Foundation

final class SearchViewModel: ObservableObject {
    let service: MovieStore
    var isLoading = true
    @Published var movies = [SearchResult]()
    @Published var multiResults = [MultiSearchResult]()
    
    init(service: MovieStore = MovieStore.shared) {
        self.service = service
    }
    
    func loadMultiResults(searchText: String) {
        self.movies = []
        self.isLoading = false
        
        self.isLoading = true
        
//        Task {
//            service.fetchSearch(from: MoviesEndpoint.searchMovie.path(), query: searchText) { [weak self] (result) in
//                guard let self = self else { return }
//                self.isLoading = false
//                switch result {
//                case .success(let movies):
//                    DispatchQueue.main.async {
//                        self.movies = movies.results
//                    }
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
        
        MovieStore.shared.fetchMultiSearch(from: MoviesEndpoint.searchMovie.path(), query: searchText) { [weak self] (result) in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let multiResults):
                DispatchQueue.main.async {
                    self.multiResults = multiResults.results ?? []
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func loadResults(searchText: String) {
        self.movies = []
        self.isLoading = false
        
        self.isLoading = true
        
//        Task {
//            service.fetchSearch(from: MoviesEndpoint.searchMovie.path(), query: searchText) { [weak self] (result) in
//                guard let self = self else { return }
//                self.isLoading = false
//                switch result {
//                case .success(let movies):
//                    DispatchQueue.main.async {
//                        self.movies = movies.results
//                    }
//                case .failure(let error):
//                    print(error)
//                }
//            }
//        }
        
        MovieStore.shared.fetchSearch(from: MoviesEndpoint.multiSearch.path(), query: searchText) { [weak self] (result) in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let movies):
                DispatchQueue.main.async {
                    self.movies = movies.results
                }
            case .failure(let error):
                print(error)
            }
        }
    }
}
