//
//  WantWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/10/22.
//

import SwiftUI
import CoreData

struct WantWatchView: View {
    @FetchRequest(sortDescriptors: []) var movies: FetchedResults<MoviesToWatch>
    @FetchRequest(sortDescriptors: []) var moviesWatched: FetchedResults<MoviesWatched>
    @Environment(\.managedObjectContext) var moc
    @Environment(\.managedObjectContext) var mocWatched
    
    var body: some View {
        VStack {
            if !movies.isEmpty || !moviesWatched.isEmpty {
                VStack {
                    List {
                        Section(header: Text("Want Watch")) {
                            ForEach(movies) { movie in
                                MoviesListCell(
                                    image: URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                                    title: movie.name ?? "",
                                    subTitle: movie.overview ?? ""
                                )
                            }
                            .onDelete(perform: deleteMovies)
                        }
                        
                        Section(header: Text("Movies Watched")) {
                            ForEach(moviesWatched) { movie in
                                MoviesListCell(
                                    image: URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                                    title: movie.name ?? "",
                                    subTitle: movie.overview ?? ""
                                )
                            }
                            .onDelete(perform: deleteMoviesThanWatched)
                        }
                    }
                }
            } else {
                Text("Lista Vazia")
            }
        }
    }
    
    func deleteMovies(at offsets: IndexSet) {
        for offset in offsets {
            let movie = movies[offset]
            moc.delete(movie)
        }
        
        try? moc.save()
    }
    
    func deleteMoviesThanWatched(at offsets: IndexSet) {
        for offset in offsets {
            let movie = moviesWatched[offset]
            mocWatched.delete(movie)
        }
        
        try? mocWatched.save()
    }
}

struct WantWatch_Previews: PreviewProvider {
    static var previews: some View {
        WantWatchView()
    }
}
