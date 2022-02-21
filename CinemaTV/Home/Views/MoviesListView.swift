//
//  MoviesListView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/02/22.
//

import SwiftUI

struct MoviesListView: View {
    let title: String
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        if viewModel.isLoadingPage {
            CinemaTVProgressView()
        } else {
            List(viewModel.discoverMovies) { movie in
                MoviesListCell(
                    image: URL(string: Constants.basePosters + movie.posterPath),
                    title: movie.title,
                    subTitle: movie.overview
                )
                    .onAppear {
                        if movie == viewModel.discoverMovies.last {
                            viewModel.getMoviesList()
                        }
                    }
            }
            .navigationTitle(title)
            .refreshable {
                viewModel.getMoviesList()
            }
        }
    }
}

struct MoviesListView_Previews: PreviewProvider {
    static var previews: some View {
        MoviesListView(
            title: "Movies"
        )
    }
}
