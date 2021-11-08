//
//  TopVotedMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/11/21.
//

import SwiftUI

struct TopVotedMoviesView: View {
    let movies: [MoviesResult]
    var body: some View {
        VStack(alignment: .leading) {
            Text("Top Rated")
                .font(.system(size: 18))
                .bold()
                .offset(.init(width: 20, height: 0))
            
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        ForEach(movies) { movie in
                            VStack(spacing: 2) {
                                MovieCell(image: URL(string: Constants.basePosters + movie.posterPath))
                                    .frame(width: 120, height: 180)
                                Text(movie.title)
                                    .font(.system(size: 16))
                                    .bold()
                                    .lineLimit(1)
                                    .frame(width: 120)
                            }
                        }
                    }
                    .offset(.init(width: 20, height: 0))
                }
            }
        }
    }
}

struct TopVotedMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        TopVotedMoviesView(movies: [
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
        ]
        )
    }
}
