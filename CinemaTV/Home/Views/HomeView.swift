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
                        VStack(spacing: 32) {
                            DiscoverMoviesView(movies: viewModel.discoverMovies)
                                .buttonStyle(.plain)
                                .navigationTitle("Discover")
                                .toolbar {
                                    Button("about") {
                                        
                                    }
                                }
                            
                            CarouselMoviesView(movies: viewModel.nowPlayngMovies, title: "Lançamentos", state: .upcoming)
                                .buttonStyle(.plain)
                            
                            CarouselMoviesView(movies: viewModel.upcomingMovies, title: "O que vem por ai", state: .nowPlaying)
                                .buttonStyle(.plain)
                            
                            CarouselMoviesView(movies: viewModel.topRatedMovies, title: "Melhor avaliados", state: .topVoted)
                                .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
