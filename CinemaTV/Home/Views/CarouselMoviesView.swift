//
//  TopVotedMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/11/21.
//

import SwiftUI

struct CarouselMoviesView: View {
    let movies: [MoviesResult]
    let title: String
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .padding(.init(top: 0, leading: 22, bottom: 0, trailing: 0))
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(movies) { movie in
                        NavigationLink(destination: DetailView(movieID: movie.id)) {
                            VStack(spacing: 2) {
                                MovieCell(image: URL(string: Constants.basePosters + movie.posterPath))
                                    .frame(width: 120, height: 180)
                                Text(movie.title)
                                    .font(.system(size: 16))
                                    .bold()
                                    .lineLimit(1)
                                    .frame(width: 120)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.init(
                    top: 0,
                    leading: 22,
                    bottom: 0,
                    trailing: 0
                ))
            }
        }
    }
}

struct TopVotedMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        CarouselMoviesView(movies: [
            MoviesResult(
                backdropPath: "",
                genreIDS: [1,2],
                id: 1,
                originalTitle: "",
                overview: "",
                popularity: 1.2,
                posterPath: "/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg",
                title: "Steve Jobs Steve Jobs Steve Jobs",
                video: true,
                voteAverage: 1.2,
                voteCount: 12
            ),
            MoviesResult(
                backdropPath: "",
                genreIDS: [1,2],
                id: 1,
                originalTitle: "",
                overview: "",
                popularity: 1.2,
                posterPath: "/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg",
                title: "Steve Jobs Steve Jobs Steve Jobs",
                video: true,
                voteAverage: 1.2,
                voteCount: 12
            )
        ],
                           title: "Top Reated"
        )
    }
}
