//
//  DetailView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/11/21.
//

import SwiftUI

struct DetailView: View {
    @ObservedObject var viewModel = DetailViewModel()
    var movieID: Int?
    
    var body: some View {
        VStack {
            ZStack {
                if let detail = viewModel.detailMovie {
                    if viewModel.isLoading {
                        CinemaTVProgressView()
                    } else {
                        if let image = URL(string: Constants.basePosters + detail.posterPath), let imageData = try? Data(contentsOf: image), let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                        }
                        ScrollView {
                            Spacer(minLength: UIScreen.main.bounds.height / 2)
                            VStack {
                                if #available(iOS 15.0, *) {
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text(detail.title)
                                                .font(.title)
                                                .bold()
                                            
                                            Text("Average: \(detail.voteAverage)/10")
                                                .font(.subheadline)
                                                .foregroundColor(Color.blue)
                                            
                                            Text(detail.overview)
                                                .font(.headline)
                                        }
                                        .padding()
                                        
                                        TrailersView(videoID: movieID, videoKey: viewModel.videoKey ?? "")
                                            .padding(16)
                                            .frame(height: 260)
                                        
                                        CastView(castID: detail.id)
                                    }
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                                } else {
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 16) {
                                            Text(detail.title)
                                                .font(.title)
                                                .bold()
                                            
                                            Text("Average: \(detail.voteAverage)/10")
                                                .font(.subheadline)
                                                .foregroundColor(Color.blue)
                                            
                                            Text(detail.overview)
                                                .font(.headline)
                                        }
                                        .padding()
                                        
                                        TrailersView(videoID: movieID, videoKey: viewModel.videoKey ?? "")
                                            .padding(16)
                                            .frame(height: 260)
                                        
                                        CastView(castID: detail.id)
                                    }
                                    .background(Color.gray.opacity(0.8))
                                    .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .onAppear {
                viewModel.loadDetails(movieID: movieID ?? 0)
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(movieID: 19404)
    }
}
