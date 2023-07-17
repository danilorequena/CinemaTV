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
    @Query var movies: [MoviesToWatch]
    @Query var moviesWatched: [MoviesWatched]
    
    var counter: Double {
        moviesWatched.reduce(0) { $0 + ($1.counter ?? 0) }
    }
    
    var body: some View {
        VStack {
            if !movies.isEmpty || !moviesWatched.isEmpty {
                VStack {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            VStack {
                                Text(minutesToHoursAndMinutes(Int(counter)))
                                    .font(.headline)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .frame(width: 200, height: 100)
                            
                            //TODO: - Aqui ficará o counter de séries
                            VStack {
                                Text("Você já assistiu 10 horas e 12 minutos de séries na sua vida!!!")
                                    .font(.headline)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .frame(width: 200, height: 100)
                            
                            //TODO: - Aqui ficará o counter de Totel de conteudo
                            VStack {
                                Text("Você já consumiu um total de 100 horas de conteudo!!!")
                                    .font(.headline)
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                            .frame(width: 200, height: 100)
                        }
                        .padding(.horizontal)
                    }
                    
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
    
    func minutesToHoursAndMinutes(_ minutes: Int) -> String {
        let string = "Você já assistiu \(minutes / 60) horas e \(minutes % 60) minutos de filmes na sua vida!"
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
