//
//  WantWatchDataManager.swift
//  CinemaTV
//
//  Created by Danilo Requena on 8/2/24.
//

import SwiftData
import Foundation
import SwiftUI

final class WantWatchDataManager {
    
    @State var isAlertPresented = false
    
    func deleteMoviesThanWatched(at offsets: IndexSet, moc: ModelContext, moviesWatched: [MoviesWatched]) {
        for offset in offsets {
            let movie = moviesWatched[offset]
            moc.delete(movie)
        }
        
        try? moc.save()
    }
    
    func deleteMovie(_ movie: MoviesToWatch, moc: ModelContext) {
        moc.delete(movie)
        try? moc.save()
    }
    
    func moveMovieToWatched(_ movie: MoviesToWatch, moc: ModelContext) {
        let movieWatched = MoviesWatched(
            counter: movie.counter,
            id: movie.id,
            name: movie.name,
            overview: movie.overview,
            profilePath: movie.profilePath
        )
        moc.insert(movieWatched)
        do {
            try moc.save()
            deleteMovie(movie, moc: moc)
        } catch {
            isAlertPresented = true
        }
    }
    
    func deleteMovies(at offsets: IndexSet, moc: ModelContext, movies: [MoviesToWatch]) {
        for offset in offsets {
            let movie = movies[offset]
            moc.delete(movie)
        }
        
        try? moc.save()
    }
    
    func minutesToHoursAndMinutes(_ minutes: Int) -> String {
        let string = "Você já assistiu \(minutes / 60) horas e \(minutes % 60) minutos de filmes na sua vida!"
        return string
    }
}
