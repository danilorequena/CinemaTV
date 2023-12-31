//
//  DetailMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI

enum DataBase {
    case toWatch
    case wached
}

struct DetailMoviesView: View {
    var state: MovieORTVShow
    var id: Int?
    var showAddFavoritesButton: Bool
    
    @StateObject var viewModel = DetailViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isDetailLoading && viewModel.isCastLoading {
                CinemaTVProgressView()
            } else {
                DetailCoreView(
                    id: id ?? 0,
                    showAddFavoritesButton: showAddFavoritesButton
                )
                .environmentObject(viewModel)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .task {
            await viewModel.loadDetails(ID: id ?? 0, state: state)
        }
    }
}

struct DetailMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailMoviesView(state: .movie, id: 287, showAddFavoritesButton: true)
                .environmentObject(DetailViewModel())
        }
    }
}
