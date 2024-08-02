//
//  MoviesDataManager.swift
//  CinemaTV
//
//  Created by Danilo Requena on 8/1/24.
//

import SwiftData
import SwiftUI

class MoviesDatabaseManager {
    
    func saveData(
        with detailData: DetailMoviesModel,
        isWatched: Bool,
        modelContext: ModelContext,
        movies: [MoviesToWatch],
        moviesWatched: [MoviesWatched]
    ) {
        if !verifyIfExists(id: detailData.id, verifyIn: .toWatch, movies: movies, moviesWatched: moviesWatched) {
            if !isWatched {
                let movie = MoviesToWatch(
                    id: Int64(detailData.id),
                    counter: Double(detailData.runtime),
                    name: detailData.title,
                    overview: detailData.overview,
                    profilePath: detailData.posterPath
                )
                modelContext.insert(movie)
                do {
                    try modelContext.save()
                    print("Movie saved to watch list!")
                } catch {
                    print("Failed to save movie: \(error.localizedDescription)")
                }
            } else {
                if !verifyIfExists(id: detailData.id, verifyIn: .watched, movies: movies, moviesWatched: moviesWatched) {
                    let movie = MoviesWatched(
                        counter: Double(detailData.runtime),
                        id: Int64(detailData.id),
                        name: detailData.title,
                        overview: detailData.overview,
                        profilePath: detailData.posterPath
                    )
                    modelContext.insert(movie)
                    do {
                        try modelContext.save()
                        print("Movie saved to watched list!")
                    } catch {
                        print("Failed to save movie: \(error.localizedDescription)")
                    }
                }
            }
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
            return "Watched"
        } else if movies.contains(where: {$0.id ?? 0 == id}) {
            return "Want Watch"
        } else {
            return LC.addFavorites.text
        }
    }
}
