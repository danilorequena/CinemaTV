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
                            DiscoverMoviesView(movies: viewModel.discoverMovies, selectionIndex: 0)
                                .buttonStyle(.plain)
                                .navigationTitle("Discover")
                                .toolbar {
                                    Button("about") {
                                        
                                    }
                                }
                            
                            CarouselMoviesView(movies: viewModel.nowPlayngMovies, title: "Lançamentos", state: .upcoming, selectionIndex: 0)
                                .buttonStyle(.plain)
                            
                            CarouselMoviesView(movies: viewModel.upcomingMovies, title: "O que vem por ai", state: .nowPlaying, selectionIndex: 1)
                                .buttonStyle(.plain)
                            
                            CarouselMoviesView(movies: viewModel.topRatedMovies, title: "Melhor avaliados", state: .topVoted, selectionIndex: 2)
                                .buttonStyle(.plain)
                            
                            NavigationLink(destination: MoviesListView(title: "Movies", state: .discover, selectionIndex: 0)) {
                                VStack {
                                    Text("Ver Todos")
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 56)
                                .background(.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                            }
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
