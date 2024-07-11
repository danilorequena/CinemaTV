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
        .modelContainer(
            for: [
                MoviesWatched.self,
                MoviesToWatch.self,
                TVShowWatchingModel.self,
                SeasonSD.self,
                EpisodeSD.self
            ]
        )
    }
    
    init () {
        loadRocketSimConnect()
    }
    
    private func loadRocketSimConnect() {
        #if DEBUG
        guard (Bundle(path: "/Applications/RocketSim.app/Contents/Frameworks/RocketSimConnectLinker.nocache.framework")?.load() == true) else {
            print("Failed to load linker framework")
            return
        }
        print("RocketSim Connect successfully linked")
        #endif
    }
}

#Preview {
    AppView()
        .preferredColorScheme(.light)
}
