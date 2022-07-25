//
//  SearchView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 18/07/22.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel = SearchViewModel()
    @State var searchText = ""
    
    var body: some View {
        NavigationView {
            List {
                ForEach(self.viewModel.movies.filter { self.searchText.isEmpty ? true : $0.title.contains(self.searchText)}) { movies in
                    Text(movies.title)
                }
            }
            .searchable(text: self.$searchText)
            .onChange(of: self.searchText, perform: { newQuery in
                self.viewModel.loadResults(searchText: newQuery)
            })
            .navigationTitle("Search")
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
