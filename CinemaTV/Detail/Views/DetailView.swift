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
                    AsyncImage(url: URL(string: Constants.basePosters + detail.posterPath)) { image in
                        image.resizable()
                    } placeholder: {
                        ProgressView()
                    }
                }
                ScrollView {
                    Spacer(minLength: UIScreen.main.bounds.height / 2)
                    VStack {
                        if let detail = viewModel.detailMovie {
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
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Casting")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                        .padding(.init(top: 0, leading: 16, bottom: 0, trailing: 0))
                                    
                                    CastView(castID: detail.id)
                                }
                            }
                            .navigationTitle(detail.title)
                            .navigationBarTitleDisplayMode(.automatic)
                            .background(Color.white.opacity(0.90))
                            .cornerRadius(16)
                        }
                    }
                }
                .task {
                    await viewModel.fetchDetail(movieID: movieID ?? 0)
                }
            }
            .edgesIgnoringSafeArea(.top)
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(movieID: 19404)
    }
}
