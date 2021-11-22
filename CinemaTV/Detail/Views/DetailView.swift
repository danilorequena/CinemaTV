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
        ScrollView {
            GeometryReader { geometry in
                ZStack {
                    if let detail = viewModel.detailMovie {
                        AsyncImage(url: URL(string: Constants.basePosters + detail.posterPath)) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                        }
                        .scaledToFill()
                        .frame(height: 475)
                        .offset(y: -geometry.frame(in: .global).minY)
                    }
                    VStack {
                        if let detail = viewModel.detailMovie {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Average: \(detail.voteAverage.formatted())/10")
                                    .font(.subheadline)
                                    .foregroundColor(.indigo)
                                
                                Text(detail.overview)
                                    .font(.headline)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(16)
                        }
                    }
                    .task {
                        await viewModel.fetchDetail(movieID: movieID ?? 0)
                    }
                }
                .navigationTitle(viewModel.detailMovie?.title ?? "")
                .navigationBarTitleDisplayMode(.inline)
                .navigationBarHidden(true)
                .edgesIgnoringSafeArea(.top)
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(movieID: 19404)
    }
}
