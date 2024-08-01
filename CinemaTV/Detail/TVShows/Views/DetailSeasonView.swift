//
//  DetailSeasonView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import SwiftUI

struct DetailSeasonView: View {
    @StateObject var viewModel: SeasonViewModel
    @State private var isWatched = false
    @Environment(\.modelContext) var modelContext
    let tvShowDetailData: DetailTVShow?
    var tvShow: TVShowWatchingModel?
    
    var body: some View {
        VStack {
            if let data = viewModel.data {
                List {
                    Section {
                        HStack {
                            AsyncImage(url: URL(string: Constants.basePosters + (data.posterPath))) { image in
                                image
                                    .resizable()
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(16)
                            } placeholder: {
                                Image("placeholder-image")
                                    .resizable()
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(16)
                            }
                            
                            VStack{
                                Text(data.name)
                                Text(data.overview)
                                    .lineLimit(8)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    Section("episodes") {
                        ForEach(data.episodes) { episode in
                            DisclosureGroup(episode.name ?? "") {
                                EpisodeCellView(
                                    imagePath: Constants.basePosters + (episode.stillPath ?? ""),
                                    overview: episode.overview ?? ""
                                )
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(action: {
                                    isWatched.toggle()
                                    saveData()
                                }, label: {
                                    Label("Watched", image: "checkmark")
                                })
                                .background(isWatched ? .green : .gray)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .task {
            await viewModel.loadSeasonDetail()
        }
    }
    
    private func saveData() {
        let episodes = viewModel.data?.episodes.compactMap { episode -> EpisodeSD? in
            EpisodeSD(
                id: episode.id,
                airDate: episode.airDate,
                episodeNumber: episode.episodeNumber,
                name: episode.name,
                overview: episode.overview,
                productionCode: episode.productionCode,
                runtime: episode.runtime,
                seasonNumber: episode.seasonNumber,
                showID: episode.showID,
                stillPath: episode.stillPath,
                voteAverage: episode.voteAverage,
                voteCount: episode.voteCount
            )
        }
        
        let seasons = tvShowDetailData?.seasons?.compactMap { season -> SeasonSD? in
            return SeasonSD(
                id: tvShowDetailData?.id,
                airDate: season.airDate ?? "",
                episodeCount: season.episodeCount ?? 0,
                name: season.name ?? "",
                overview: season.overview ?? "",
                posterPath: season.posterPath ?? "",
                seasonNumber: season.seasonNumber,
                episodes: episodes
            )
        }
        
        let tvShow = TVShowWatchingModel(
            id: tvShowDetailData?.id,
            name: tvShowDetailData?.name,
            overview: tvShowDetailData?.overview,
            imagePath: tvShowDetailData?.posterPath,
            seasons: []
        )
        
        modelContext.insert(tvShow)
        tvShow.seasons = seasons
        seasons?.forEach {$0.episodes = episodes }
        do {
            try modelContext.save()
            print("DEU CERTOOOOO!!!!")
        } catch {
            print(error.localizedDescription)
        }
    }
}
