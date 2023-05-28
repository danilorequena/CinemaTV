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
    @ObservedObject var viewModel = DetailViewModel()
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
                                
                                if let cast = viewModel.cast?.cast {
                                    CastView(state: .tvShow, castData: cast)
                                }
                                
                                if let seasons = viewModel.detailTVShow?.seasons,
                                   let seriesID = viewModel.detailTVShow?.id {
                                    SeasonsCarouselView(seriesID: seriesID, data: seasons, title: "Seasons")
                                }
                                
                                CarouselInDetailView(data: viewModel.tvShowsRecommendations?.results ?? [], title: LC.recommendations.text)
                                
                                CarouselInDetailView(data: viewModel.tvShowsSimilars?.results ?? [], title: LC.similars.text)
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

struct InformationDetailView: View {
    var detailInfos: DetailTVShow
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(detailInfos.name ?? "")
                    .font(.title)
                    .bold()
                
                Text("Release Date: \(detailInfos.firstAirDate?.formatString() ?? "").")
                    .font(.subheadline)
                    .foregroundColor(Color.blue)
                
                Text("Average: \(detailInfos.voteAverage?.formatted() ?? "")/10")
                    .font(.subheadline)
                    .foregroundColor(Color.blue)
            }
            
            Text(detailInfos.overview ?? "")
                .font(.headline)
            
        }
        .padding()
    }
}
