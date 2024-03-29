//
//  RecommendationsView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI

struct CarouselInDetailView: View {
    let viewModel = DetailViewModel()
    let data: [MoviesTVShowResult]
    let title: String
    var body: some View {
        if data.isEmpty {
            CinemaTVProgressView()
        } else {
            VStack(alignment: .center) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(data) { movie in
                            NavigationLink(destination: DetailView(id: movie.id, state: .movie, showAddFavoritesButton: true)) {
                                VStack(spacing: 2) {
                                    AsyncImage(url: URL(string: Constants.basePosters + (movie.posterPath ?? ""))) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .cornerRadius(16)
                                                .scaledToFit()
                                                .frame(width: 200, height: 240)
                                        } else if phase.error != nil {
                                            Image("placeholder-image")
                                                .resizable()
                                                .cornerRadius(16)
                                                .scaledToFit()
                                                .frame(width: 200, height: 240)
                                        } else {
                                            ProgressView()
                                        }
                                    }

                                    Text((movie.title ?? movie.name) ?? "")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 180)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CarouselInDetailView(
        data: MoviesTVShowResult.stubbedMovies(),
        title: "Title"
    )
}

