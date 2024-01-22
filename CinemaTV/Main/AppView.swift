//
//  AppView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 13/08/22.
//

import SwiftUI

struct AppView: View {
    let featureToggle = FeatureToggle()
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "movieclapper")
                    Text("Movies")
                }
            if featureToggle.enableTVShows {
                TVShowHomeView()
                    .tabItem {
                        Image(systemName: "play.tv")
                        Text("TV Shows")
                    }
            }
            
            SearchView()
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("Search")
                }
        }
    }
}

#Preview {
    AppView()
        .preferredColorScheme(.light)
}

#Preview {
    AppView()
        .preferredColorScheme(.dark)
}
