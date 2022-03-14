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
                            
                            CarouselMoviesView(movies: viewModel.nowPlayngMovies, title: "Lançamentos", selectionIndex: 0)
                                .buttonStyle(.plain)
                            
                            CarouselMoviesView(movies: viewModel.popularMovies, title: "Filmes Populares", selectionIndex: 1)
                                .buttonStyle(.plain)
                            
                            CarouselMoviesView(movies: viewModel.topRatedMovies, title: "Melhor avaliados", selectionIndex: 2)
                                .buttonStyle(.plain)
                            
                            NavigationLink(destination: MoviesListView(title: "Movies", selectionIndex: 0)) {
                                VStack {
                                    Text("Ver Todos")
                                }
                                .frame(width: UIScreen.main.bounds.width - 32, height: 56)
                                .background(Color.blue)
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
