//
//  DiscoverMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct DiscoverMoviesView: View {
    @StateObject var viewModel = HomeViewModel()
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 20) {
                ForEach(viewModel.discoverMovies) { movie in
                    NavigationLink(destination: DetailView(movieID: movie.id)) {
                        //TODO: - acertar esse scroll pra tirar esses travamentos
//                        GeometryReader { proxy in
                            MovieCell(image: URL(string: Constants.basePosters + movie.posterPath))
//                                x
                                .onAppear {
                                    if movie.id == viewModel.discoverMovies.last?.id {
                                        viewModel.loadComponents(currentItem: movie)
                                    }
                                }
//                        }
//                        .frame(width: 246, height: 150)
                    }
                }
            }
            .padding(40)
            Spacer()
        }
        .frame(width: UIScreen.main.bounds.width, height: 460)
    }
}

struct DiscoverMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverMoviesView()
    }
}
