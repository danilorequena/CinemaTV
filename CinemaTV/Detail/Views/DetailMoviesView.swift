//
//  DetailMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI

struct DetailMoviesView: View {
    var state: MovieORTVShow
    @ObservedObject var viewModel = DetailViewModel()
    var id: Int?
    var body: some View {
        VStack {
            if viewModel.isDetailLoading && viewModel.isCastLoading {
                CinemaTVProgressView()
            } else {
                ZStack {
                    if let detail = viewModel.detailMovie {
                        AsyncImage(url: URL(string: Constants.basePosters + detail.posterPath)) { image in
                            image
                                .resizable()
                        } placeholder: {
                            Image("placeholder-image")
                        }
                        
                        ScrollView {
                            Spacer(minLength: UIScreen.main.bounds.height / 2)
                            VStack {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(detail.title)
                                                .font(.title)
                                                .bold()
                                            
                                            Text("Release Date: \(detail.releaseDate).")
                                                .font(.subheadline)
                                                .foregroundColor(Color.blue)
                                            
                                            Text("Average: \(detail.voteAverage.formatted())/10")
                                                .font(.subheadline)
                                                .foregroundColor(Color.blue)
                                        }
                                        
                                        Text(detail.overview)
                                            .font(.headline)
                                    }
                                    .padding()
                                    
                                    TrailersView(videoID: id, videoKey: viewModel.videoKey ?? "")
                                        .padding(16)
                                        .frame(height: 260)
                                    
                                    CastView(state: .movie, data: viewModel.cast?.cast ?? [])
                                    RecommendationsView(data: viewModel.moviesRecommendations?.results ?? [], title: "Recommendations")
                                }
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .task {
            await viewModel.loadDetails(ID: id ?? 0, state: state)
        }
    }
}

