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
        VStack(alignment: .center) {
            HStack {
                Text(title)
                    .font(.system(.headline, design: .rounded))
                    .lineLimit(1)
                    .frame(width: 260, alignment: .leading)
                    
                
                Button {
                    
                } label: {
                    Text("ver todos")
                        .font(.subheadline)
                        .frame(width: 80, alignment: .trailing)
                }
            }
            .frame(width: UIScreen.main.bounds.width)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(movies) { movie in
                        NavigationLink(destination: DetailView(movieID: movie.id)) {
                            VStack(spacing: 2) {
                                MovieCell(image: URL(string: Constants.basePosters + movie.backdropPath))
                                    .frame(width: 180, height: 100)
                                Text(movie.title)
                                    .font(.caption)
                                    .lineLimit(1)
                                    .frame(width: 180)
                            }
                            .buttonStyle(.plain)
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

struct TopVotedMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        CarouselMoviesView(movies: [
            MoviesResult(
                backdropPath: "/g2djzUqA6mFplzC03gDk0WSyg99.jpg",
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
                           title: "Lançamentos"
        )
    }
}
