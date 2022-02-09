//
//  HomeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView{
            Group {
                if viewModel.isLoadingPage {
                    CinemaTVProgressView()
                } else {
                    ScrollView(.vertical) {
                        VStack(spacing: 20) {
                            DiscoverMoviesView(movies: viewModel.discoverMovies)
                                .buttonStyle(.plain)
                                .navigationTitle("Discover")
                            
                            CarouselMoviesView(movies: viewModel.latestMovies, title: "Upcoming Movies")
                            CarouselMoviesView(movies: viewModel.topRatedMovies, title: "Top Reated")
                        }
                    }
                }
            }
            .task {
                await viewModel.loadComponents(currentItem: viewModel.discoverMovies)
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
