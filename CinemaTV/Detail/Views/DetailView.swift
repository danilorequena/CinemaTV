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
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text(detail.title)
                                            .font(.title)
                                            .bold()
                                        
                                        Text("Average: \(detail.voteAverage.formatted())/10")
                                            .font(.subheadline)
                                            .foregroundColor(.indigo)
                                        
                                        Text(detail.overview)
                                            .font(.headline)
                                    }
                                    .padding()
                                    
                                    CastView(castID: detail.id)
                                }
                                .navigationTitle(detail.title)
                                .navigationBarTitleDisplayMode(.automatic)
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                        }
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .task {
                await viewModel.fetchDetail(movieID: movieID ?? 0)
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(movieID: 19404)
    }
}
