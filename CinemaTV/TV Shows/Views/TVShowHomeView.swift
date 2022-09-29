//
//  TVShowHomeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/09/22.
//

import SwiftUI

struct TVShowHomeView: View {
    @StateObject private var viewModel = TVShowViewModel()
    var body: some View {
        NavigationView {
            Group {
                ScrollView(.vertical) {
                    VStack(spacing: 32) {
                        DiscoverMoviesView(movies: viewModel.discoverTVShows, selectionIndex: 0)
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.getData(with: .discover)
                            }
                        
                        CarouselMoviesView(
                            data: viewModel.nowTVShows,
                            title: LC.onTheAir.text,
                            selectionIndex: 0,
                            isLightBackground: false
                        )
                            .buttonStyle(.plain)
                            .task {
                                await viewModel.getData(with: .nowPlaying)
                            }
                    }
                }
                
            }
            .background(Gradient(colors: [.gray, .black]))
            .navigationTitle(LC.tvShows.text)
        }
    }
}

struct TVShowHomeView_Previews: PreviewProvider {
    static var previews: some View {
        TVShowHomeView()
    }
}
