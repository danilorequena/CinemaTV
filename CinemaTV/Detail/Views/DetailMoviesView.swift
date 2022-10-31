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
                                            
                                            Text(LC.releaseDate.text + detail.releaseDate.formatString())
                                                .font(.subheadline)
                                                .foregroundColor(Color.blue)
                                            
                                            Text(LC.average.text + "\(detail.voteAverage.description)/10")
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
                                    
                                    if let cast = viewModel.cast?.cast {
                                        CastView(
                                            state: .movie,
                                            castData: cast
                                        )
                                    }
                                    
                                    CarouselInDetailView(data: viewModel.moviesRecommendations?.results ?? [], title: LC.recommendations.text)
                                    
                                    CarouselInDetailView(data: viewModel.moviesSimilars?.results ?? [], title: LC.similars.text)
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

