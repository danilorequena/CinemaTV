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
                DiscoverView(state: .tvShow, movies: viewModel.discoverTVShows, selectionIndex: 0)
                    .buttonStyle(.plain)
                    .task {
                        await viewModel.getData(with: .discover)
                    }
                
                DefaultCarouselView(
                    data: viewModel.todayTVShows,
                    title: LC.airingToday.text,
                    selectionIndex: 0,
                    isLightBackground: false,
                    state: .tvShow
                )
                .buttonStyle(.plain)
                .task {
                    await viewModel.getData(with: .airingToday)
                }
                
                DefaultCarouselView(
                    data: viewModel.nowTVShows,
                    title: LC.onTheAir.text,
                    selectionIndex: 0,
                    isLightBackground: false,
                    state: .tvShow
                )
                .buttonStyle(.plain)
                .task {
                    await viewModel.getData(with: .nowPlaying)
                }
                
                DefaultCarouselView(
                    data: viewModel.popTVShows,
                    title: LC.popTVShows.text,
                    selectionIndex: 0,
                    isLightBackground: false,
                    state: .tvShow
                )
                .buttonStyle(.plain)
                .task {
                    await viewModel.getData(with: .popular)
                }
            }
        }
    }
}

#Preview {
    TVShowView()
}
