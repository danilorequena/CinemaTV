//
//  MoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 29/09/22.
//

import SwiftUI
import MySwiftLibrary

struct MoviesView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(.vertical) {
            VStack(spacing: 32) {
                DiscoverView(state: .movie, movies: viewModel.discoverMovies, selectionIndex: 0)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .discover)
                    }
                
                DefaultCarouselView(data: viewModel.upcomingMovies, title: LC.soon.text, selectionIndex: 1, isLightBackground: false, state: .movie)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .upcoming)
                    }
                
                DefaultCarouselView(data: viewModel.nowPlayngMovies, title: LC.nowPlaying.text, selectionIndex: 2, isLightBackground: false, state: .movie)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .nowPlaying)
                    }
                
                DefaultCarouselView(data: viewModel.popularMovies, title: LC.popular.text, selectionIndex: 2, isLightBackground: false, state: .movie)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .popular)
                    }
                
                DefaultCarouselView(data: viewModel.topRatedMovies, title: LC.rated.text, selectionIndex: 2, isLightBackground: false, state: .movie)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getAllData(with: .toRated)
                    }
                
                NavigationLink(destination: MoviesListView(title: LC.movies.text, selectionIndex: 0)) {
                    VStack {
                        Text(LC.seeAll.text)
                            .foregroundColor(colorScheme == .light ? .black : .white)
                    }
                    .frame(width: UIScreen.main.bounds.width - 32, height: 56)
                    .background(.thinMaterial)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            }
        }
        .refreshable {
            Task {
                await viewModel.getAllData(with: .discover)
                await viewModel.getAllData(with: .upcoming)
                await viewModel.getAllData(with: .nowPlaying)
                await viewModel.getAllData(with: .popular)
                await viewModel.getAllData(with: .toRated)
            }
        }
    }
}

#Preview {
    MoviesView()
        .environmentObject(HomeViewModel())
}
