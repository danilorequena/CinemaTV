//
//  TopVotedMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/11/21.
//

import SwiftUI
import SwiftData

struct DefaultCarouselView: View {
    let data: [MoviesTVShowResult]
    let title: String
    var selectionIndex: Int
    let isLightBackground: Bool
    let state: MovieORTVShow
    var body: some View {
        if data.isEmpty {
            CinemaTVProgressView()
        } else {
            VStack(alignment: .center) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .frame(width: 260, alignment: .leading)
                        
                    NavigationLink(destination: MoviesListView(title: title, selectionIndex: selectionIndex)) {
                        Text(LC.seeAll.text)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
                .frame(width: UIScreen.main.bounds.width)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(data) { movie in
                            NavigationLink(destination: DetailView(id: movie.id, state: state, showAddFavoritesButton: true)) {
                                VStack(spacing: 2) {
                                    MovieCell(image: URL(string: Constants.basePosters + (movie.backdropPath ?? "")))
                                        .frame(width: 180, height: 100)
                                    Text((movie.title ?? movie.name) ?? "")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 180)
                                }
                                .padding(.bottom, 4)
                                .buttonStyle(.plain)
                                .background(.ultraThinMaterial.opacity(0.8))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.init(
                        top: 0,
                        leading: 16,
                        bottom: 0,
                        trailing: 0
                    ))
                }
            }
        }
    }
}

struct TopVotedMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCarouselView(
            data: MoviesTVShowResult.stubbedMovies(),
            title: "Title",
            selectionIndex: 0,
            isLightBackground: false,
            state: .movie
        )
    }
}
