//
//  MenuOptionsDetailView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 8/1/24.
//

import SwiftUI
import SwiftData

struct MenuOptionsDetailView: View {
    let dataManager: MoviesDatabaseManager
    let detail: DetailMoviesModel
    let moc: ModelContext
    let mocWatched: ModelContext
    let movies: [MoviesToWatch]
    let moviesWatched: [MoviesWatched]
    let showAddFavoritesButton: Bool
    
    
    var body: some View {
        if showAddFavoritesButton {
            Menu {
                Button("Want to Watch") {
                    dataManager.saveData(
                        with: detail,
                        isWatched: false,
                        moc: moc,
                        mocWatched: mocWatched,
                        movies: movies,
                        moviesWatched: moviesWatched
                    )
                }
                .disabled(dataManager.verifyIfExists(
                    id: detail.id,
                    verifyIn: .toWatch,
                    movies: movies,
                    moviesWatched: moviesWatched
                ))
                
                Button("Watched") {
                    dataManager.saveData(
                        with: detail,
                        isWatched: true,
                        moc: moc,
                        mocWatched: mocWatched,
                        movies: movies,
                        moviesWatched: moviesWatched
                    )
                }
            } label: {
                HStack {
                    Image(
                        systemName: dataManager.verifyIfExists(
                            id: detail.id,
                            movies: movies,
                            moviesWatched: moviesWatched
                        ) ? "checkmark" : "bookmark.fill"
                    )
                    .foregroundColor(
                        dataManager.changeColor(
                            id: detail.id,
                            movies: movies,
                            moviesWatched: moviesWatched
                        )
                    )
                    
                    Text(dataManager.changeTitle(
                        id: detail.id,
                        movies: movies,
                        moviesWatched: moviesWatched
                    ))
                    .foregroundColor(.black)
                }
                .padding(8)
                .background(.ultraThinMaterial.opacity(0.2))
                .cornerRadius(16)
            }
            .disabled(dataManager.verifyIfExists(id: detail.id, movies: movies, moviesWatched: moviesWatched))
        }
    }
}
