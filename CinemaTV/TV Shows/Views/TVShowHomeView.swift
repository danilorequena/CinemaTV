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
            if colorScheme == .dark {
                Group {
                    TVShowView()
                }
                .background(Gradient(colors: [.gray, .black]))
            .navigationTitle(LC.tvShows.text)
            } else {
                Group {
                    TVShowView()
                }
                .background(Gradient(colors: [.gray, .white]))
            .navigationTitle(LC.tvShows.text)
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
