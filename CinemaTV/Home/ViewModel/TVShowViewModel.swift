//
//  TVShowViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/09/22.
//

import Foundation
import SwiftUI

final class TVShowViewModel: ObservableObject {
    var service: TVShowServiceProtocol
    @Published var discoverTVShows: [MovieResult] = []
    @Published var isLoadingPage = true
    @Published var dispathGroup = DispatchGroup()
    
    init(service: TVShowServiceProtocol = TVShowStore.shared) {
        self.service = service
    }
    
    func getDiscoverTVShowsList() async {
        Task {
            service.fetchDiscoverTVShows(from: TVShowsEndpoint.discover) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let tvShows):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.discoverTVShows = tvShows.results ?? []
                        self.isLoadingPage = false
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
}

