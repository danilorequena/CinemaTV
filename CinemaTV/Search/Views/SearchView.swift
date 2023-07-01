//
//  SearchView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 18/07/22.
//

import SwiftUI

struct SearchView: View {
    @StateObject var viewModel = SearchViewModel()
    @State var searchText = ""
    @Environment(\.isSearching) var isSearching
    @Environment(\.dismissSearch) var dismissSearch
    var isTVShow = false
    
    var body: some View {
        NavigationStack {
            List(self.viewModel.multiResults) { result in
                NavigationLink(destination: DetailView(id: result.id, state: result.mediaType == "movie" ? .movie : .tvShow)) {
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
        .onChange(of: searchText, { _, _ in
            if searchText.isEmpty {
                self.viewModel.multiResults.removeAll()
            }
        })
        .onSubmit(of: .search) {
            if isSearching && searchText.isEmpty {
                dismissSearch()
            }
            self.viewModel.loadMultiResults(searchText: searchText)
        }
    }
    
    func setState(with isMovie: Bool) -> MovieORTVShow {
        return isMovie == true ? .movie : .tvShow
    }
}

#Preview {
    SearchView()
}
