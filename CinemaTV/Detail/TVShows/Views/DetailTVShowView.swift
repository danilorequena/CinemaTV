//
//  DetailTVShowView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI
import SwiftData

struct DetailTVShowView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var mocWatching
    @Query var seasons: [TVShowWatchingModel]
    
    var state: MovieORTVShow
    @StateObject var viewModel = DetailViewModel()
    var id: Int?
    var body: some View {
        ZStack {
            if let detail = viewModel.detailTVShow {
                if viewModel.isDetailLoading && viewModel.isCastLoading {
                    CinemaTVProgressView()
                } else {
                    AsyncImage(url: URL(string: Constants.basePosters + (detail.posterPath ?? String()))) { image in
                        image
                            .resizable()
                    } placeholder: {
                        Image("placeholder-image")
                    }
                    
                    ScrollView {
                        Spacer(minLength: UIScreen.main.bounds.height / 2)
                        VStack {
                            VStack(alignment: .leading, spacing: 16) {
                                InformationDetailView(detailInfos: detail)
                                
                                Menu {
                                    Button("Watching") {
                                        saveData(with: detail)
                                    }
                                    
                                    Button("Watched") {
//                                        Implementar o salvamento aqui
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "bookmark.fill")
                                        Text("Add")
                                            .foregroundColor(.black)
                                    }
                                    .padding(8)
                                    .background(.ultraThinMaterial.opacity(0.2))
                                    .cornerRadius(16)
                                }
                                .disabled(false)
                                .padding(.leading, 8)
                                
                                TrailersView(videoID: id, videoKey: viewModel.videoKey ?? "")
                                    .padding(16)
                                    .frame(height: 260)
                                
                                if let cast = viewModel.cast?.cast, !cast.isEmpty {
                                    CastView(state: .tvShow, castData: cast)
                                }
                                
                                if let seasons = viewModel.detailTVShow?.seasons,
                                   let seriesID = viewModel.detailTVShow?.id, !seasons.isEmpty {
                                    SeasonsCarouselView(seriesID: seriesID, data: seasons, title: "Seasons")
                                }
                                
                                if let recommendations = viewModel.tvShowsRecommendations?.results, !recommendations.isEmpty {
                                    CarouselInDetailView(data: viewModel.tvShowsRecommendations?.results ?? [], title: LC.recommendations.text)
                                }
                                
                                if let similars = viewModel.tvShowsSimilars?.results, !similars.isEmpty {
                                    CarouselInDetailView(data: viewModel.tvShowsSimilars?.results ?? [], title: LC.similars.text)
                                }
                            }
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
        .task {
            await viewModel.loadDetails(ID: id ?? 0, state: state)
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private func saveData(with detailData: DetailTVShow) {
        
        let seasons = detailData.seasons
        
        let tvShow = TVShowWatchingModel(
            id: detailData.id ?? 0,
            name: detailData.name ?? "",
            overview: detailData.overview ?? "",
            imagePath: detailData.posterPath,
            seasons: seasons?.compactMap { season in
                SeasonSD(
                    id: season.id ?? 0,
                    airDate: season.airDate ?? "",
                    episodeCount: season.episodeCount ?? 0,
                    name: season.name ?? "",
                    overview: season.overview ?? "",
                    posterPath: season.posterPath ?? "",
                    seasonNumber: season.seasonNumber ?? 0
                )
            } ?? []
        )
        
        mocWatching.insert(tvShow)
        do {
            try mocWatching.save()
            print("DEU CERTOOOOO!!!!")
        } catch {
            print(error.localizedDescription)
        }
    }
}

#Preview {
    DetailTVShowView(state: .tvShow, id: 71712)
}
