//
//  MoviesDataManager.swift
//  CinemaTV
//
//  Created by Danilo Requena on 8/1/24.
//

import SwiftData
import SwiftUI

final class MoviesDatabaseManager {
    func saveData(
        in databaseType: DataBase,
        with detailData: DetailMoviesModel,
        isWatched: Bool,
        modelContext: ModelContext,
        movies: [MoviesToWatch],
        moviesWatched: [MoviesWatched]
    ) {
        switch databaseType {
        case .toWatch:
            let movie = MoviesToWatch(
                id: Int64(detailData.id),
                counter: Double(detailData.runtime),
                name: detailData.title,
                overview: detailData.overview,
                profilePath: detailData.posterPath
            )
            modelContext.insert(movie)
        case .watched:
            let movie = MoviesWatched(
                counter: Double(detailData.runtime),
                id: Int64(detailData.id),
                name: detailData.title,
                overview: detailData.overview,
                profilePath: detailData.posterPath
            )
            modelContext.insert(movie)
        }
    }
    
    func verifyIfExists(id: Int, verifyIn: DataBase, movies: [MoviesToWatch], moviesWatched: [MoviesWatched]) -> Bool {
        switch verifyIn {
        case .toWatch:
            let exist = movies.contains(where: {$0.id ?? 0 == id})
            return exist
        case .watched:
            let exist = moviesWatched.contains(where: {$0.id ?? 0 == id})
            return exist
        }
    }
    
    func verifyIfExists(id: Int, movies: [MoviesToWatch], moviesWatched: [MoviesWatched]) -> Bool {
        if movies.contains(where: {$0.id ?? 0 == id}) || moviesWatched.contains(where: {$0.id ?? 0 == id}) {
            return true
        }
        return false
    }

    func changeColor(id: Int, movies: [MoviesToWatch], moviesWatched: [MoviesWatched]) -> Color {
        if moviesWatched.contains(where: {$0.id ?? 0 == id}) {
            return .green
        } else if movies.contains(where: {$0.id ?? 0 == id}) {
            return .gray
        } else {
            return .pink
        }
    }
    
    func changeTitle(id: Int, movies: [MoviesToWatch], moviesWatched: [MoviesWatched]) -> String {
        if moviesWatched.contains(where: {$0.id ?? 0 == id}) {
            return LC.watchedButton.text
        } else if movies.contains(where: {$0.id ?? 0 == id}) {
            return LC.watchButton.text
        } else {
            return LC.addFavorites.text
        }
    }
}
