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
    
    var body: some View {
        VStack {
            switch state {
            case .movie:
                DetailMoviesView(state: state, id: id)
            case .tvShow:
                DetailTVShowView(state: state, id: id)
            }
        }
    }
}

struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailView(id: 19404, state: .movie)
            DetailView(id: 94997, state: .tvShow)
        }
    }
}
