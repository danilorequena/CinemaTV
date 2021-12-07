//
//  HomeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject private var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationView{
            Group {
            if viewModel.discoverMovies.isEmpty && viewModel.topRatedMovies.isEmpty {
                CinemaTVProgressView()
            } else {
                ScrollView(.vertical) {
                        VStack(spacing: 20) {
                            DiscoverMoviesView(movies: viewModel.discoverMovies)
                                .buttonStyle(.plain)
                            .navigationTitle("Discover")
                            
                            TopVotedMoviesView(movies: viewModel.topRatedMovies)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadComponents()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
