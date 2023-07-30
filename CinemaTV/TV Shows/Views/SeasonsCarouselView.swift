//
//  SeasonsCollectionView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 30/10/22.
//

import SwiftUI

struct SeasonsCarouselView: View {
    let seriesID: Int
    let data: [Season]
    let title: String
    var body: some View {
        if data.isEmpty {
            CinemaTVProgressView()
        } else {
            VStack(alignment: .center) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                        .padding(.leading, 16)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(data) { tvShow in
                            NavigationLink(destination: DetailSeasonView(
                                viewModel: SeasonViewModel(
                                    tvShowID: seriesID,
                                    tvshowSeasonNumber: tvShow.seasonNumber ?? 0
                                )
                            )) {
                                VStack(spacing: 2) {
                                    AsyncImage(url: URL(string: Constants.basePosters + (tvShow.posterPath ?? ""))) { image in
                                        image
                                            .resizable()
                                            .cornerRadius(16)
                                            .scaledToFit()
                                            .frame(width: 200, height: 240)
                                    } placeholder: {
                                        ProgressView()
                                    }

                                    Text(tvShow.name ?? "")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 180)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.init(
                        top: 0,
                        leading: 8,
                        bottom: 0,
                        trailing: 0
                    ))
                }
            }
        }
    }
}

struct SeasonsCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        SeasonsCarouselView(
            seriesID: 94997,
            data: Season.mockArray(),
            title: "Title"
        )
    }
}

