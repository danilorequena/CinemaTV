//
//  DetailTVShowView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI

struct DetailTVShowView: View {
    var state: MovieORTVShow
    @Environment(\.colorScheme) var colorScheme
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
}
