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
        NavigationView {
            Group {
                ScrollView(.vertical) {
                    VStack(spacing: 32) {
                        DiscoverMoviesView(movies: viewModel.discoverMovies, selectionIndex: 0)
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.getAllData(with: .discover)
                            }
                        
                        CarouselMoviesView(data: viewModel.upcomingMovies, title: LC.soon.text, selectionIndex: 0, isLightBackground: true)
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.getAllData(with: .upcoming)
                            }
                        
                        CarouselMoviesView(data: viewModel.nowPlayngMovies, title: LC.nowPlaying.text, selectionIndex: 0, isLightBackground: true)
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.getAllData(with: .nowPlaying)
                            }
                        
                        CarouselMoviesView(data: viewModel.popularMovies, title: LC.popular.text, selectionIndex: 1, isLightBackground: true)
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.getAllData(with: .popular)
                            }
                        
                        CarouselMoviesView(data: viewModel.topRatedMovies, title: LC.rated.text, selectionIndex: 2, isLightBackground: true)
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.getAllData(with: .toRated)
                            }
                        
                        NavigationLink(destination: MoviesListView(title: LC.movies.text, selectionIndex: 0)) {
                            VStack {
                                Text(LC.seeAll.text)
                            }
                            .frame(width: UIScreen.main.bounds.width - 32, height: 56)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle(LC.discover.text)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        
                    } label: {
                        Image(systemName: "info.circle")
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
