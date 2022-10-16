//
//  DetailTVShowView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI
import Kingfisher

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
                    KFImage.url(URL(string: Constants.basePosters + (detail.posterPath ?? String())))
                        .placeholder {
                            Circle().fill(Color.gray)
                                .frame(width: 60, height: 60)
                        }
                        .resizable()
                    
                    ScrollView(.vertical, showsIndicators: false) {
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
                                
                                RecommendationsView(data: viewModel.tvShowsRecommendations?.results ?? [], title: LC.recommendations.text)
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .padding(.horizontal, 16)
                        }
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
