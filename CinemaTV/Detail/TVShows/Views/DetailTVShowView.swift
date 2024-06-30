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
    @Query var seasons: [TVShowWatchedModel]
    
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
                                        saveData(with: detail)
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
        guard let title = detailData.name,
              let overview = detailData.overview, // Ajuste conforme necessário
              let releaseDateString = detailData.firstAirDate,
              let releaseDate = DateFormatter.yyyyMMdd.date(from: releaseDateString),
              let imagePath = detailData.posterPath else {
            print("Dados insuficientes para salvar a série.")
            return
        }

        let tvShow = TVShowDataModel(id: detailData.id ?? 0, title: title, overview: overview, releaseDate: releaseDate, imagePath: imagePath)
        
        for seasonData in detailData.seasons ?? [] {
            guard let seasonID = seasonData.id,
                  let seasonNumber = seasonData.seasonNumber,
                  let seasonReleaseDateString = seasonData.airDate,
                  let seasonReleaseDate = DateFormatter.yyyyMMdd.date(from: seasonReleaseDateString) else {
                continue
            }
            
            let season = SeasonDataModel(id: seasonID, seasonNumber: seasonNumber, releaseDate: seasonReleaseDate/*, tvShow: tvShow*/)
            
//            for episodeData in seasonData.episodes {
//                guard let episodeTitle = episodeData.name,
//                      let episodeDuration = episodeData.runtime,
//                      let episodeReleaseDateString = episodeData.airDate,
//                      let episodeReleaseDate = DateFormatter.yyyyMMdd.date(from: episodeReleaseDateString) else {
//                    continue
//                }
//                
//                let episode = EpisodeDataModel(
//                    title: episodeTitle,
//                    duration: episodeDuration,
//                    releaseDate: episodeReleaseDate,
//                    season: season
//                )
//                season.episodes.append(episode)
//            }
            
            tvShow.seasons?.append(season)
        }

        mocWatching.insert(tvShow)
        do {
            try mocWatching.save()
            print("Dados salvos com sucesso!")
        } catch {
            print("Erro ao salvar dados: \(error.localizedDescription)")
        }
    }
}

#Preview {
    DetailTVShowView(state: .tvShow, id: 71712)
}


extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
