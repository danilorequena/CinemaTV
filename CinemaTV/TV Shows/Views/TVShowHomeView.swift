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
                                await viewModel.getDiscoverTVShowsList()
                            }
                    }
                }
            }
        }
    }
}

struct TVShowHomeView_Previews: PreviewProvider {
    static var previews: some View {
        TVShowHomeView()
    }
}
