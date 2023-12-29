//
//  TVShowsWatchingView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 19/11/23.
//

import SwiftUI
import SwiftData

struct TVShowsWatchingView: View {
    @Environment(\.modelContext) var mocTVWatching
    @Query(sort: \TVShowWatchingModel.name) var tvShows: [TVShowWatchingModel]
    @State var isAlertPresented: Bool = false
    
    var body: some View {
        VStack {
            if !tvShows.isEmpty {
                List {
                    Section(header: Text("Watching")) {
                        ForEach(tvShows) { tvShow in
                            NavigationLink(destination: DetailView(id: Int(truncatingIfNeeded: tvShow.id ?? 0), state: .tvShow, showAddFavoritesButton: false)) {
                                MoviesListCell(
                                    image: URL(string: Constants.basePosters + (tvShow.imagePath ?? "")),
                                    title: tvShow.name ?? "",
                                    subTitle: tvShow.overview ?? ""
                                )
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteMovie(tvShow)
                                    } label: {
                                        Label("delete", systemImage: "trash.fill")
                                            .background(.red)
                                    }

                                }
                            }
                        }
                    }
                }
            } else {
                Text("Você ainda não marcou nenhuma série")
            }
        }
    }
    
    private func minutesToHoursAndMinutes(_ minutes: Int) -> String {
        let string = "Você já assistiu \(minutes / 60) horas e \(minutes % 60) minutos de filmes na sua vida!"
        return string
    }
    
    private func deleteMovies(at offsets: IndexSet) {
        for offset in offsets {
            let movie = tvShows[offset]
            mocTVWatching.delete(movie)
        }
        
        try? mocTVWatching.save()
    }
    
    private func moveMovieToWatched(_ movie: TVShowWatchingModel) {
//        let movieWatched = MoviesWatched(
//            counter: movie.counter,
//            id: movie.id,
//            name: movie.name,
//            overview: movie.overview,
//            profilePath: movie.profilePath
//        )
//        mocTVWatched.insert(movieWatched)
//        do {
//            try mocTVWatched.save()
//            deleteMovie(movie)
//        } catch {
//            isAlertPresented = true
//        }
    }
    
    private func deleteMovie(_ movie: TVShowWatchingModel) {
        mocTVWatching.delete(movie)
        try? mocTVWatching.save()
    }
    
    private func deleteMoviesThanWatched(at offsets: IndexSet) {
//        for offset in offsets {
//            let tvShow = tvShowsWatched[offset]
//            mocTVWatched.delete(tvShow)
//        }
//        
//        try? mocTVWatched.save()
    }
}

#Preview {
    TVShowsWatchingView()
        .modelContainer(for: [TVShowWatchingModel.self, TVShowWatchedModel.self])
}
