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
        ZStack {
            if let detail = viewModel.detailMovie {
                AsyncImage(url: URL(string: Constants.basePosters + detail.posterPath)) { image in
                    image.resizable()
                } placeholder: {
                    ProgressView()
                }
            }
            ZStack {
                ScrollView {
                    if let detail = viewModel.detailMovie {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Average: \(detail.voteAverage.formatted())/10")
                                    .font(.subheadline)
                                    .foregroundColor(.indigo)
                                
                                Text(detail.overview)
                                    .font(.headline)
                            }
                            
                            CastView(castID: detail.id)
                                .offset(x: 10)
                        }
                        .padding()
                        .background(Color.white.opacity(0.8))
                        .cornerRadius(16)
                        .offset(y: UIScreen.main.bounds.height / 2)
                    }
                }
                .task {
                    await viewModel.fetchDetail(movieID: movieID ?? 0)
                }
            }
        }
        .navigationTitle(viewModel.detailMovie?.title ?? "")
        .navigationBarTitleDisplayMode(.automatic)
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(movieID: 19404)
    }
}
