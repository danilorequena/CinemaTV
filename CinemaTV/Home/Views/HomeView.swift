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
        TabView {
            NavigationView{
                Group {
                    if viewModel.discoverMovies.isEmpty && viewModel.topRatedMovies.isEmpty {
                        ProgressView()
                    } else {
                        VStack(spacing: 20) {
                            DiscoverMoviesView(movies: viewModel.discoverMovies)
                                .navigationTitle("Discover")
                            
                            TopVotedMoviesView(movies: viewModel.topRatedMovies)
                        }
                    }
                }
                .task {
                    await viewModel.loadComponents()
                }
            }
            .tabItem {
                Label("Movies", systemImage: "square.and.pencil")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
