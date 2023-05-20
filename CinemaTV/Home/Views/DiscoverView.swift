//
//  DiscoverMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct DiscoverView: View {
    @FetchRequest(sortDescriptors: []) var moviesWatched: FetchedResults<MoviesWatched>
    
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
                            NavigationLink(destination: DetailView(id: movie.id, state: state)) {
                                GeometryReader { proxy in
                                    let minX = proxy.frame(in: .global).minX
                                    MovieCell(image: URL(string: Constants.basePosters + (movie.posterPath ?? "")), watched: moviesWatched.contains{ $0.id == movie.id ?? 0})
                                        .rotation3DEffect(Angle(degrees: (Double(minX) - 40) / -20), axis: (x: 0, y: 1, z: 0))
                                        .shadow(radius: 10, x: 0, y: 10)
                                        
                                }
                                .frame(width: 246, height: 150)
                            }
                        }
                    }
                    .padding(.top, 10)
                    .padding(.trailing, 40)
                    .padding(.leading, 40)
                    .padding(.bottom, 40)
                    Spacer()
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: 460)
        }
    }
}

struct DiscoverMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView(
            state: .movie,
            movies: MoviesTVShowResult.stubbedMovies(),
            selectionIndex: 0
        )
    }
}
