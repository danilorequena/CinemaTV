//
//  TVShowView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 29/09/22.
//

import SwiftUI

struct TVShowView: View {
    @StateObject private var viewModel = TVShowViewModel()
    var body: some View {
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
}
