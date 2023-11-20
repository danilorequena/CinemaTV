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
    @Published var discoverTVShows: [MoviesTVShowResult] = []
    @Published var nowTVShows: [MoviesTVShowResult] = []
    @Published var popTVShows: [MoviesTVShowResult] = []
    @Published var todayTVShows: [MoviesTVShowResult] = []
    @Published var isLoadingPage = true
    @Published var dispathGroup = DispatchGroup()
    
    init(service: TVShowServiceProtocol = TVShowStore.shared) {
        self.service = service
    }
    
    func getData(with endpoint: TVShowsEndpoint) async {
        Task {
            service.fetchDiscoverTVShows(from: endpoint) { result in
                self.dispathGroup.enter()
                switch result {
                case .success(let tvShows):
                    self.dispathGroup.leave()
                    self.dispathGroup.notify(queue: .main) {
                        self.handleData(endpoint: endpoint, tvShows: tvShows)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                    self.dispathGroup.leave()
                }
            }
        }
    }
    
    private func handleData(endpoint: TVShowsEndpoint, tvShows: DiscoverTVShow) {
        switch endpoint {
        case .discover:
            self.discoverTVShows = tvShows.results ?? []
            self.isLoadingPage = false
        case .nowPlaying:
            self.nowTVShows = tvShows.results ?? []
            self.isLoadingPage = false
        case .popular:
            self.popTVShows = tvShows.results ?? []
            self.isLoadingPage = false
        case .airingToday:
            self.todayTVShows = tvShows.results ?? []
            self.isLoadingPage = false
        default:
            break
        }
    }
}

