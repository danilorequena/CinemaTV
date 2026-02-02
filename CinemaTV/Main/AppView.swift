//
//  AppView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 13/08/22.
//

import SwiftUI
import SwiftData

struct AppView: View {
    var body: some View {
        MainContainerView()
    }
}

#Preview {
    AppView()
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self, TVShowWatchingModel.self])
        .preferredColorScheme(.light)
}

#Preview {
    AppView()
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self, TVShowWatchingModel.self])
        .preferredColorScheme(.dark)
}
