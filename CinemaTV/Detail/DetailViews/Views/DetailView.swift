//
//  DetailView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/11/21.
//

import SwiftUI

struct DetailView: View {
    var id: Int?
    var state: MovieORTVShow
    var showAddFavoritesButton: Bool
    
    var body: some View {
        VStack {
            switch state {
            case .movie:
                DetailMoviesView(
                    state: state,
                    id: id,
                    showAddFavoritesButton: showAddFavoritesButton
                )
            case .tvShow:
                DetailTVShowView(state: state, id: id)
            }
        }
    }
}

#Preview {
    DetailView(id: 19404, state: .movie, showAddFavoritesButton: true)
}

#Preview {
    DetailView(id: 94997, state: .tvShow, showAddFavoritesButton: true)
}
