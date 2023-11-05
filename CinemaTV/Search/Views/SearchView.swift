//
//  SearchView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 18/07/22.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var viewModel = SearchViewModel()
    @State var data = [SearchResult]()
    @State var searchText = ""
    @Environment(\.isSearching) var isSearching
    @Environment(\.dismissSearch) var dismissSearch
    
    var body: some View {
        NavigationStack {
            List(self.viewModel.multiResults) { result in
                NavigationLink(destination: DetailView(id: result.id, state: .movie, showAddFavoritesButton: true)) {
                    MoviesListCell(
                        image: URL(string: Constants.basePosters + (result.posterPath ?? "")),
                        title: result.title ?? "",
                        subTitle: result.overview ?? ""
                    )
                }
            }
            .id(UUID())
            .navigationTitle("Search")
        }
        .searchable(text: self.$searchText)
        .onChange(of: searchText) {
            if searchText.isEmpty {
                self.viewModel.multiResults.removeAll()
            }
        }
        .onSubmit(of: .search) {
            if isSearching && searchText.isEmpty {
                dismissSearch()
            }
            self.viewModel.loadMultiResults(searchText: searchText)
        }
    }
}

struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        SearchView()
    }
}
