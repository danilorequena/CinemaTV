//
//  CinemaTVApp.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI
import SwiftData

@main
struct CinemaTVApp: App {
    var body: some Scene {
        WindowGroup {
            AppView()
        }
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self])
    }
}

#Preview {
    AppView()
        .preferredColorScheme(.light)
}
