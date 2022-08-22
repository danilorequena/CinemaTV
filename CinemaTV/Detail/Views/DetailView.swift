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
                    if viewModel.isDetailLoading && viewModel.isCastLoading {
                        CinemaTVProgressView()
                    } else {
                        if let image = URL(string: Constants.basePosters + detail.posterPath), let imageData = try? Data(contentsOf: image), let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
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
                                    
                                    TrailersView(videoID: movieID, videoKey: viewModel.videoKey ?? "")
                                        .padding(16)
                                        .frame(height: 260)
                                    
                                    CastView(castID: detail.id)
                                }
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
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
