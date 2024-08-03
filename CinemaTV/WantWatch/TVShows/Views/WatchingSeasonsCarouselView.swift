//
//  WatchingSeasonsCarouselView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 7/9/24.
//

import SwiftUI
import SwiftData

struct WatchingSeasonsCarouselView: View {
    let data: TVShowWatchingModel
    let title: String
    @Namespace var animation
    var body: some View {
        if let seasons = data.seasons, seasons.isEmpty {
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
                    LazyHStack {
                        ForEach(data.seasons ?? [], id: \.self) { tvShow in
                            NavigationLink {
                                DetailSeasonView(
                                    viewModel: SeasonViewModel(
                                        tvShowID: tvShow.id ?? 0,
                                        tvshowSeasonNumber: tvShow.seasonNumber ?? 0
                                    ),
                                    tvShowDetailData: nil,
                                    tvShow: data
                                )
                            } label: {
                                VStack {
                                    MovieCell(
                                        image: URL(string: Constants.basePosters + (tvShow.posterPath ?? "")),
                                        id: tvShow.id ?? 0,
                                        animation: animation
                                    )
                                    .scaledToFit()
                                    .frame(width: 200, height: 240)
                                    
                                    ProgressView(value: 5, total: Double(tvShow.episodeCount ?? 0))
                                        .padding(16)
                                }
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
