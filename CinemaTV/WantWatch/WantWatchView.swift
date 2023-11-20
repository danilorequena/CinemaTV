//
//  WantWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/10/22.
//

import SwiftUI
import SwiftData

struct WantWatchView: View {
    @Environment(\.modelContext) var moc
    @Environment(\.modelContext) var mocWatched
    @Query(sort: \MoviesToWatch.name) var movies: [MoviesToWatch]
    @Query(sort: \MoviesWatched.name) var moviesWatched: [MoviesWatched]
    @State var isAlertPresented: Bool = false
    
    var counter: Double {
        moviesWatched.reduce(0) { $0 + ($1.counter ?? 0) }
    }
    
    var body: some View {
        VStack {
            if !movies.isEmpty || !moviesWatched.isEmpty {
                VStack {
                    CarouselLifeView(value: minutesToHoursAndMinutes(Int(counter)))
                    
                    List {
                        Section(header: Text("Want Watch")) {
                            ForEach(movies) { movie in
                                NavigationLink(destination: DetailView(id: Int(truncatingIfNeeded: movie.id ?? 0), state: .movie, showAddFavoritesButton: false)) {
                                    MoviesListCell(
                                        image: URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                                        title: movie.name ?? "",
                                        subTitle: movie.overview ?? ""
                                    )
                                    .swipeActions(allowsFullSwipe: false) {
                                        Button {
                                            moveMovieToWatched(movie)
                                        } label: {
                                            Label("Watched", systemImage: "checkmark")
                                        }
                                        .tint(.indigo)
                                        
                                        Button(role: .destructive) {
                                            deleteMovie(movie)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                    }
                                    .alert("Error saving the movie.",
                                           isPresented: $isAlertPresented) {
                                    } message: {
                                           Text("There was an error saving the movie, try again...")
                                    }
                                }
                            }
                        }
                        
                        Section(header: Text("Movies Watched")) {
                            ForEach(moviesWatched) { movie in
                                NavigationLink(destination: DetailView(id: Int(truncatingIfNeeded: movie.id ?? 0), state: .movie, showAddFavoritesButton: false)) {
                                    MoviesListCell(
                                        image: URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                                        title: movie.name ?? "",
                                        subTitle: movie.overview ?? ""
                                    )
                                }
                            }
                            .onDelete(perform: deleteMoviesThanWatched)
                        }
                    }
                }
            } else {
                Text("Lista Vazia")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func minutesToHoursAndMinutes(_ minutes: Int) -> String {
        let string = "Você já assistiu \(minutes / 60) horas e \(minutes % 60) minutos de filmes na sua vida!"
        return string
    }
    
    private func deleteMovies(at offsets: IndexSet) {
        for offset in offsets {
            let movie = movies[offset]
            moc.delete(movie)
        }
        
        try? moc.save()
    }
    
    private func moveMovieToWatched(_ movie: MoviesToWatch) {
        let movieWatched = MoviesWatched(
            counter: movie.counter,
            id: movie.id,
            name: movie.name,
            overview: movie.overview,
            profilePath: movie.profilePath
        )
        mocWatched.insert(movieWatched)
        do {
            try mocWatched.save()
            deleteMovie(movie)
        } catch {
            isAlertPresented = true
        }
    }
    
    private func deleteMovie(_ movie: MoviesToWatch) {
        moc.delete(movie)
        try? moc.save()
    }
    
    private func deleteMoviesThanWatched(at offsets: IndexSet) {
        for offset in offsets {
            let movie = moviesWatched[offset]
            mocWatched.delete(movie)
        }
        
        try? mocWatched.save()
    }
}

#Preview {
    WantWatchView()
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self])
}
