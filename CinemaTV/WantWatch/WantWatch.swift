//
//  WantWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/10/22.
//

import SwiftUI

struct WantWatch: View {
    @FetchRequest(sortDescriptors: []) var movies: FetchedResults<Movies>
    @Environment(\.managedObjectContext) var moc
    let layout = [GridItem(.adaptive(minimum: 80))]
    var body: some View {
        VStack {
            if !movies.isEmpty {
                VStack {
                    Button {
                        
                    } label: {
                        Text("Limpar lista")
                    }
                    
                    List {
                        ForEach(movies) { movie in
                            Text(movie.name ?? "Unknow")
                        }
                        .onDelete(perform: deleteMovies)
                    }
                    
                    
                    //TODO: - Mudar essa lista acima por uma visão de grid
//                    ScrollView {
//                        LazyVGrid(columns: layout, spacing: 20) {
//                            ForEach(movies, id: \.self) { item in
//                                Text(item.name ?? "Unknow")
//                            }
//                            .onDelete(perform: deleteMovies)
//                        }
//                    }
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
}

struct WantWatch_Previews: PreviewProvider {
    static var previews: some View {
        WantWatch()
    }
}
