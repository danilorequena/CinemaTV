//
//  MoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 29/09/22.
//

import SwiftUI

struct MoviesView: View {
    @StateObject private var viewModel = HomeViewModel()
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 32) {
                DiscoverMoviesView(state: .movie, movies: viewModel.discoverMovies, selectionIndex: 0)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .discover)
                    }
                
                CarouselMoviesView(data: viewModel.upcomingMovies, title: LC.soon.text, selectionIndex: 0, isLightBackground: false)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .upcoming)
                    }
                
                CarouselMoviesView(data: viewModel.nowPlayngMovies, title: LC.nowPlaying.text, selectionIndex: 0, isLightBackground: false)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .nowPlaying)
                    }
                
                CarouselMoviesView(data: viewModel.popularMovies, title: LC.popular.text, selectionIndex: 1, isLightBackground: false)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .popular)
                    }
                
                CarouselMoviesView(data: viewModel.topRatedMovies, title: LC.rated.text, selectionIndex: 2, isLightBackground: false)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .toRated)
                    }
                
                NavigationLink(destination: MoviesListView(title: LC.movies.text, selectionIndex: 0)) {
                    VStack {
                        Text(LC.seeAll.text)
                    }
                    .frame(width: UIScreen.main.bounds.width - 32, height: 56)
                    .background(Color(uiColor: .darkGray))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
    }
}