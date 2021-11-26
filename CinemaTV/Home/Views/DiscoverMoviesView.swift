//
//  DiscoverMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct DiscoverMoviesView: View {
    let movies: [MoviesResult]
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(movies) { movie in
                    NavigationLink(destination: DetailView(movieID: movie.id)) {
                        MovieCell(image: URL(string: Constants.basePosters + movie.posterPath))
                            .frame(width: 260, height: 380)
                    }
                }
            }
            .padding(.init(
                top: 0,
                leading: 22,
                bottom: 0,
                trailing: 0)
            )
        }
    }
}

struct DiscoverMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverMoviesView(movies: MoviesResult.stub)
    }
}
