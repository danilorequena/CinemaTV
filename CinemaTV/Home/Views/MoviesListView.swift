//
//  MoviesListView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/02/22.
//

import SwiftUI

struct MoviesListView: View {
    let title: String
    let movies: [MoviesResult]
    
    var body: some View {
        NavigationView {
            List(movies) { movie in
                MoviesListCell(
                    image: URL(string: Constants.basePosters + movie.posterPath),
                    title: movie.title,
                    subTitle: movie.overview
                )
            }
        }
        .navigationTitle(title)
    }
}

struct MoviesListView_Previews: PreviewProvider {
    static var previews: some View {
        MoviesListView(
            title: "Movies",
            movies: MoviesResult.stub
        )
    }
}
