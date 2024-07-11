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
    @Namespace private var animation
    
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
                            NavigationLink {
                                DetailView(
                                    id: movie.id, state: state,
                                    showAddFavoritesButton: true
                                )
                                .navigationTransition(.zoom(sourceID: movie.id, in: animation))
                            } label: {
                                setupCell(with: movie, iPad: UIDevice.isIPad)
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
    private func setupCell(with movie: MoviesTVShowResult, iPad: Bool) -> some View {
        if iPad {
            MovieCell(
                image: URL(string: Constants.basePosters + (movie.posterPath ?? "")),
                id: movie.id ?? 0,
                animation: animation
            )
            .frame(maxWidth: .infinity, maxHeight: 500)
        } else {
            GeometryReader { proxy in
                MovieCell(
                    image: URL(string: Constants.basePosters + (movie.posterPath ?? "")),
                    id: movie.id ?? 0,
                    animation: animation
                )
                    .rotation3DEffect(Angle(degrees: (Double(proxy.frame(in: .global).minX) - 40) / -20), axis: (x: 0, y: 10.0, z: 0))
            }
            .frame(width: 246, height: 150)
        }
    }
}

#Preview {
    HomeView()
}
