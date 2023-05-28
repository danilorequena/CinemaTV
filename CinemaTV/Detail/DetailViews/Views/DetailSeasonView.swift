//
//  DetailSeasonView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import SwiftUI

struct DetailSeasonView: View {
    @ObservedObject var viewModel: SeasonViewModel
    var body: some View {
        ZStack {
            VStack {
                AsyncImage(url: URL(string: Constants.basePosters + (viewModel.data?.posterPath ?? ""))) { image in
                    image
                        .resizable()
                } placeholder: {
                    Image("placeholder-image")
                }
            }
        }
        .ignoresSafeArea(.all, edges: .top)
        .task {
            await viewModel.loadSeasonDetail()
        }
    }
}

struct DetailSeasonView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSeasonView(
            viewModel: SeasonViewModel(
                tvShowID: 60735,
                tvshowSeasonNumber: 1
            )
        )
    }
}
