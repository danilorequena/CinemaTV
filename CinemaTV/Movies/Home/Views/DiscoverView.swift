//
//  DiscoverMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI
import SwiftData

struct DiscoverView: View {
    let state: MovieORTVShow
    let movies: [MoviesTVShowResult]
    var selectionIndex: Int
    
    var body: some View {
        if movies.isEmpty {
            CinemaTVProgressView()
        } else {
            VStack(alignment: .trailing) {
                NavigationLink(
                    destination: MoviesListView(
                        title: LC.discover.text,
                        selectionIndex: selectionIndex
                    )
                ) {
                    Text(LC.seeAll.text)
                        .font(.subheadline)
                        .padding(.trailing, 16)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(movies) { movie in
                            NavigationLink(destination: DetailView(id: movie.id, state: state, showAddFavoritesButton: true)) {
                                if !UIDevice.isIPad {
                                    setupCell(with: movie)
                                        .frame(width: 246, height: 150)
                                } else {
                                    MovieCell(image: URL(string: Constants.basePosters + (movie.posterPath ?? "")))
                                        .frame(maxWidth: .infinity, maxHeight: 500)
                                }
                            }
                        }
                    }
                    .scrollTargetLayout()
                    Spacer()
                }
                .contentMargins(.horizontal, 10, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned(limitBehavior: .never))
                .safeAreaPadding(.horizontal)
            }
            .frame(maxWidth: .infinity, minHeight: 460)
        }
    }
    
    @ViewBuilder
    private func setupCell(with movie: MoviesTVShowResult) -> some View {
        GeometryReader { proxy in
            MovieCell(image: URL(string: Constants.basePosters + (movie.posterPath ?? "")))
                .rotation3DEffect(Angle(degrees: (Double(proxy.frame(in: .global).minX) - 40) / -20), axis: (x: 0, y: 10.0, z: 0))
        }
    }
}

#Preview {
    HomeView()
}
