//
//  WantWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/10/22.
//

import SwiftUI
import SwiftData

enum WantWatchViewState {
    case success
    case empty
}

struct WantWatchView: View {
    @Environment(\.modelContext) var modelContext
    @Query(sort: \MoviesToWatch.name) var movies: [MoviesToWatch]
    @Query(sort: \MoviesWatched.name) var moviesWatched: [MoviesWatched]
    @State var isAlertPresented: Bool = false
    var state: WantWatchViewState {
        if !movies.isEmpty || !moviesWatched.isEmpty {
            .success
        } else {
            .empty
        }
    }
    
    var counter: Double {
        moviesWatched.reduce(0) { $0 + ($1.counter ?? 0) }
    }
    
    var manager = WantWatchDataManager()
    
    var body: some View {
        VStack {
            switch state {
            case .success:
                VStack {
                    CarouselLifeView(value: manager.minutesToHoursAndMinutes(Int(counter)))
                    
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
                                            manager.moveMovieToWatched(movie, moc: modelContext)
                                        } label: {
                                            Label("Watched", systemImage: "checkmark")
                                        }
                                        .tint(.indigo)
                                        
                                        Button(role: .destructive) {
                                            manager.deleteMovie(movie, moc: modelContext)
                                        } label: {
                                            Label("Delete", systemImage: "trash.fill")
                                        }
                                    }
                                    .alert("Error saving the movie.",
                                           isPresented: manager.$isAlertPresented) {
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
                            .onDelete { index in
                                manager.deleteMoviesThanWatched(at: index, moc: modelContext, moviesWatched: moviesWatched)
                            }
                        }
                    }
                }
            case .empty:
                Text("Lista Vazia")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    WantWatchView()
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self])
}
