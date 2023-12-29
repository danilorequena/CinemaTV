//
//  TVShowHomeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/09/22.
//

import SwiftUI

struct TVShowHomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var viewModel = TVShowViewModel()
    var body: some View {
        NavigationStack {
            Group {
                TVShowView()
                    .environmentObject(viewModel)
            }
            .background(Gradient(colors: colorScheme == .dark ? [.gray, .black] : [.gray, .white]))
            .navigationTitle(LC.tvShows.text)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: TVShowsWatchingView(),
                        label: {
                            Image(systemName: "star.fill")
                                .foregroundColor(colorScheme == .light ? .white : .secondary)
                        }
                    )
                }
            }
        }
        
    }
}

#Preview {
    TVShowHomeView()
        .preferredColorScheme(.light)
}

#Preview {
    TVShowHomeView()
        .preferredColorScheme(.dark)
}
