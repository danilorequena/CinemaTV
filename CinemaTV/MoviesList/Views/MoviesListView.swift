//
//  MoviesListView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/02/22.
//

import SwiftUI

enum MoviesState {
    case discover
    case upcoming
    case topVoted
    case nowPlaying
}

struct MoviesListView: View {
    let title: String
    let state: MoviesState
    @ObservedObject private var viewModel = MoviesListViewModel()
    @State private var searchText: String = ""
    
    var body: some View {
        VStack {
            if viewModel.isLoadingPage {
                CinemaTVProgressView()
            } else if state == .discover {
                List(viewModel.discoverMovies, id: \.self) { movie in
                    NavigationLink(destination: DetailView(viewModel: DetailViewModel(), movieID: movie.id)) {
                        MoviesListCell(
                            image: URL(string: Constants.basePosters + movie.posterPath),
                            title: movie.title,
                            subTitle: movie.overview
                        )
                            .onAppear {
                                setupViews(state: state, movie: movie)
                            }
                    }
                }
                .navigationTitle(title)
                .searchable(text: $searchText)
                
            } else if state == .topVoted {
                List(viewModel.topRatedMovies) { movie in
                    MoviesListCell(
                        image: URL(string: Constants.basePosters + movie.posterPath),
                        title: movie.title,
                        subTitle: movie.overview
                    )
                        .onAppear {
                            setupViews(state: state, movie: movie)
                        }
                }
                .navigationTitle(title)
                .searchable(text: $searchText)
                
            } else if state == .nowPlaying {
                List(viewModel.nowPlayngMovies) { movie in
                    MoviesListCell(
                        image: URL(string: Constants.basePosters + movie.posterPath),
                        title: movie.title,
                        subTitle: movie.overview
                    )
                        .onAppear {
                            setupViews(state: state, movie: movie)
                        }
                }
                .navigationTitle(title)
                .searchable(text: $searchText)
                
            } else if state == .upcoming {
                List(viewModel.upcomingMovies) { movie in
                    MoviesListCell(
                        image: URL(string: Constants.basePosters + movie.posterPath),
                        title: movie.title,
                        subTitle: movie.overview
                    )
                        .onAppear {
                            setupViews(state: state, movie: movie)
                        }
                }
                .navigationTitle(title)
                .searchable(text: $searchText)
            }
        }
        .onAppear {
            viewModel.loadData(state: state)
        }
    }
    
    private func setupViews(state: MoviesState, movie: MoviesResult) {
        switch state {
        case .discover:
            if movie == viewModel.discoverMovies.last {
                viewModel.loadData(state: state)
            }
        case .upcoming:
            if movie == viewModel.upcomingMovies.last {
                viewModel.loadData(state: state)
            }
        case .topVoted:
            if movie == viewModel.topRatedMovies.last {
                viewModel.loadData(state: state)
            }
        case .nowPlaying:
            if movie == viewModel.nowPlayngMovies.last {
                viewModel.loadData(state: state)
            }
        }
    }
}

struct MoviesListView_Previews: PreviewProvider {
    static var previews: some View {
        MoviesListView(
            title: "Movies", state: .topVoted
        )
    }
}
