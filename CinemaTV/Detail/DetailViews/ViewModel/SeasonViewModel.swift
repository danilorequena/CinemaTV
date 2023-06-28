//
//  SeasonViewModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import Foundation

final class SeasonViewModel: ObservableObject {
    @Published var data: SeasonModel?
    
    let service: SeasonService
    let tvShowID: Int
    let tvshowSeasonNumber: Int
    
    init(
        service: SeasonService = SeasonService(),
        tvShowID: Int,
        tvshowSeasonNumber: Int
    ) {
        self.service = service
        self.tvShowID = tvShowID
        self.tvshowSeasonNumber = tvshowSeasonNumber
    }
    
    @MainActor
    func loadSeasonDetail() async {
        service.fetchSeasonDetail(from: .season(seasonID: tvShowID, seasonNumber: tvshowSeasonNumber)) { result in
            switch result {
            case .success(let data):
                self.data = data
            case .failure(let failure):
                print(failure.localizedDescription)
            }
        }
    }
}
