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
                    MovieCell(image: URL(string: Constants.basePosters + movie.posterPath))
                        .frame(width: 200, height: 310)
                }
            }
        }
        .padding(20)
    }
}

struct DiscoverMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverMoviesView(movies: [
            MoviesResult(
                adult: false,
                backdropPath: "",
                genreIDS: [1,2],
                id: 1,
                originalTitle: "",
                overview: "",
                popularity: 1.2,
                posterPath: "/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg",
                releaseDate: "",
                title: "Steve Jobs Steve Jobs Steve Jobs",
                video: true,
                voteAverage: 1.2,
                voteCount: 12
            ),
            MoviesResult(
                adult: false,
                backdropPath: "",
                genreIDS: [1,2],
                id: 1,
                originalTitle: "",
                overview: "",
                popularity: 1.2,
                posterPath: "/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg",
                releaseDate: "",
                title: "Steve Jobs Steve Jobs Steve Jobs",
                video: true,
                voteAverage: 1.2,
                voteCount: 12
            )
        ])
    }
}
