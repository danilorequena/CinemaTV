//
//  WantWatch.swift
//  CinemaTV
//
//  Created by Danilo Requena on 17/10/22.
//

import SwiftUI
import CoreData

struct WantWatch: View {
    @FetchRequest(sortDescriptors: []) var movies: FetchedResults<Movies>
    @Environment(\.managedObjectContext) var moc
    let layout = [GridItem(.adaptive(minimum: 80))]
    var body: some View {
        VStack {
            if !movies.isEmpty {
                VStack {
                    Button {
                        //TODO: - Ver uma forma de apagar com batchUpdate
                        deleteAllData(entity: "Movies")
                    } label: {
                        Text("Limpar lista")
                    }
                    
                    List {
                        Section(header: Text("Movies")) {
                            ForEach(movies) { movie in
                                MoviesListCell(
                                    image: URL(string: Constants.basePosters + (movie.profilePath ?? "")),
                                    title: movie.name ?? "",
                                    subTitle: movie.overview ?? ""
                                )
                            }
                            .onDelete(perform: deleteMovies)
                        }
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
    
    func deleteAllData(entity: String)
    {
        let ReqVar = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
        let DelAllReqVar = NSBatchDeleteRequest(fetchRequest: ReqVar)
        do { try moc.execute(DelAllReqVar) }
        catch { print(error) }
    }
}

struct WantWatch_Previews: PreviewProvider {
    static var previews: some View {
        WantWatch()
    }
}
