//
//  DetailSeasonView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import SwiftUI

struct DetailSeasonView: View {
    var data: SeasonModel
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: Constants.basePosters + data.posterPath)) { image in
                image
                    .resizable()
            } placeholder: {
                Image("placeholder-image")
            }
        }
        .ignoresSafeArea()
    }
}

struct DetailSeasonView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSeasonView(data: SeasonModel.stubbedSeason())
    }
}
