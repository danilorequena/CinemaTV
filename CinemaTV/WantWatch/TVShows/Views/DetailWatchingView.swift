//
//  DetailWatchingView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 7/9/24.
//

import SwiftUI
import SwiftData

struct DetailWatchingView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var mocWatching
    var watchingTVShows: TVShowWatchingModel
    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: Constants.basePosters + (watchingTVShows.imagePath ?? String()))) { image in
                image
                    .resizable()
            } placeholder: {
                Image("placeholder-image")
            }
            
            ScrollView {
                Spacer(minLength: UIScreen.main.bounds.height / 2)
                VStack {
                    VStack(alignment: .leading, spacing: 16) {
                        InformationDetailView(
                            name: watchingTVShows.name ?? "",
                            firstAirDate: "Implementar",
                            overview: watchingTVShows.overview ?? "",
                            voteAverage: "Implementar"
                        )
                        
                        WatchingSeasonsCarouselView(data: watchingTVShows, title: "Seasons")
                        
                    }
                }
                .background(.ultraThinMaterial)
                .cornerRadius(16)
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
}
