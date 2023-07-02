//
//  DiscoverMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI
import SwiftData

struct DiscoverView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query var moviesWatched: [MoviesWatched]
    
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
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(movies) { movie in
                            NavigationLink(destination: DetailView(id: movie.id, state: state)) {
                                MovieCell(image: URL(string: Constants.basePosters + (movie.posterPath ?? "")), watched: moviesWatched.contains{ $0.id ?? 0 == movie.id ?? 0})
                                    .scrollTransition(axis: .horizontal) { content, phase in
                                        content
                                            .scaleEffect(
                                                x: phase.isIdentity ? 1.0 : 0.80,
                                                y: phase.isIdentity ? 1.0 : 0.80
                                            )
                                    }
                                    .aspectRatio(contentMode: .fit)
                                    .containerRelativeFrame(
                                        .horizontal,
                                        count: sizeClass == .regular ? 2 : 1,
                                        spacing: 10
                                    )
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 20)
                .scrollTargetBehavior(.paging)
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct DiscoverMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(
            state: .movie,
            movies: MoviesTVShowResult.stubbedJsonsMovies,
            selectionIndex: 0
        )
    }
}
