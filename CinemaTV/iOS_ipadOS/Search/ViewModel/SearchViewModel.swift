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
    
    @MainActor
    func loadMultiResults(searchText: String) {
        self.movies = []
        self.isLoading = false
        
        self.isLoading = true
        MovieStore.shared.fetchMultiSearch(from: MoviesEndpoint.multiSearch.path(), query: searchText) { [weak self] (result) in
            guard let self = self else { return }
            self.isLoading = false
            switch result {
            case .success(let multiResults):
                self.multiResults = multiResults.results ?? []
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}
