//
//  DetailSeasonView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import SwiftUI

struct DetailSeasonView: View {
    var seasonID: Int
    var seasonNumber: Int
    var viewModel = SeasonViewModel()
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: Constants.basePosters + (viewModel.data?.posterPath ?? ""))) { image in
                image
                    .resizable()
            } placeholder: {
                Image("placeholder-image")
            }
        }
        .ignoresSafeArea()
        .task {
            await viewModel.loadSeasonDetail(with: seasonID, and: seasonNumber)
        }
    }
}

struct DetailSeasonView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSeasonView(seasonID: 60735, seasonNumber: 1)
    }
}
