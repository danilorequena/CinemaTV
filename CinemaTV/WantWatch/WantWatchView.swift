//
//  WantWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/10/22.
//

import SwiftUI
import SwiftData

struct WantWatchView: View {
    @Query var movies: [MoviesToWatch]
    @Query var moviesWatched: [MoviesWatched]
    @Environment(\.modelContext) var moc
    @Environment(\.modelContext) var mocWatched
    
    var counter: Double {
        moviesWatched.reduce(0) { $0 + ($1.counter ?? 0) }
    }
    
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
                        
                        Text(minutesToHoursAndMinutes(Int(counter)))
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
    
    func minutesToHoursAndMinutes(_ minutes: Int) -> String {
        let string = "Você já assistiu \(minutes / 60) horas e \(minutes % 60) minutos de conteudo na sua vida!"
        return string
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
