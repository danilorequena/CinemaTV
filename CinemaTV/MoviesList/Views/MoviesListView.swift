//
//  MoviesListView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/02/22.
//

import SwiftUI

struct MoviesListView: View {
    @State var title: String
    @State var selectionIndex: Int
    @State private var tabs = ["Discover", "Upcoming", "Top Rated"]
    @ObservedObject private var viewModel = MoviesListViewModel()
    @State private var searchText: String = ""
    
    var body: some View {
        VStack {
            if viewModel.isLoadingPage {
                CinemaTVProgressView()
            } else {
                Picker("_", selection: $selectionIndex) {
                    ForEach(0..<3) { index in
                        Text(tabs[index])
                            .font(.title)
                            .bold()
                            .tag(index)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: selectionIndex) { (_) in
                    if selectionIndex == 0 {
                        viewModel.loadData(endpoint: .discover)
                        title = "Discover"
                    } else if selectionIndex == 1 {
                        viewModel.loadData(endpoint: .upcoming)
                        title = "Upcoming"
                    } else if selectionIndex == 2 {
                        viewModel.loadData(endpoint: .toRated)
                        title = "Melhor Avaliados"
                    }
                }
                
//                List(viewModel.movies.filter{searchText.isEmpty ? true : $0.title.lowercased().localizedStandardContains(searchText.lowercased())}) { movie in
                List(viewModel.movies) { movie in
                    // Se eu incluir o NavigationLink ele fica com aquela travadinha
                    NavigationLink(destination: DetailView(viewModel: DetailViewModel(), movieID: movie.id)) {
                        MoviesListCell(
                            image: URL(string: Constants.basePosters + (movie.posterPath ?? "")),
                            title: (movie.title ?? movie.name) ?? "" ,
                            subTitle: movie.overview ?? ""
                        )
                    }
                }
                .navigationTitle(title)
//                .searchable(text: $searchText)
            }
        }
        .onAppear {
            switch selectionIndex {
            case 0:
                viewModel.loadData(endpoint: .discover)
            case 1:
                viewModel.loadData(endpoint: .upcoming)
            case 2:
                viewModel.loadData(endpoint: .toRated)
            default:
                break
            }
        }
    }
}

struct MoviesListView_Previews: PreviewProvider {
    static var previews: some View {
        MoviesListView(
            title: "Movies",
            selectionIndex: 0
        )
    }
}
