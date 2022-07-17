//
//  SearchViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/07/22.
//

import Foundation

final class SearchViewModel: ObservableObject {
    var service = MoviesService()
    var isLoading = true
    @Published var searchModel: SearchModel?
    
    func loadResults(movie: String) {
        MovieStore.shared.fetchSearch(from: MoviesEndpoint.searchMovie.path(), query: movie) { result in
            switch result {
            case .success(let movies):
                //TODO: - Montar a estrutura de receber os filmes
                print("success")
            case .failure(let error):
                //TODO: - Montar a tela de empty e error
                print("deu ruim")
            }
        }
    }
}
