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
        ScrollView {
            TabView {
                ForEach(movies) { movie in
                    NavigationLink(destination: DetailView(movieID: movie.id)) {
                        GeometryReader { proxy in
                            let minX = proxy.frame(in: .global).minX
                            MovieCell(image: URL(string: Constants.basePosters + movie.posterPath))
                                .padding(.vertical, 20)
                                .rotation3DEffect(.degrees(minX / -10), axis: (x: 0, y: 1, z: 0))
                                .blur(radius: abs(minX / 40))
                                .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 10)
                                .frame(width: 380, height: 580)
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(width: 380, height: 600)
        }
    }
}

struct DiscoverMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverMoviesView(movies: MoviesResult.stub)
    }
}
