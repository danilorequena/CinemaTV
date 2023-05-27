//
//  SeasonViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import Foundation

final class SeasonViewModel {
    let service = SeasonService()
    
    @Published var data: SeasonModel?
    
    @MainActor
    func loadSeasonDetail(with seasonID: Int, and seasonNumber: Int) async {
        service.fetchSeasonDetail(from: .season(seasonID: seasonID, seasonNumber: seasonNumber)) { result in
            switch result {
            case .success(let data):
                self.data = data
            case .failure(let failure):
                print(failure)
            }
        }
    }
    
}
