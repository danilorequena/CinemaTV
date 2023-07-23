//
//  DetailCoreView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 23/11/22.
//

import SwiftUI

struct DetailCoreView: View {
    let viewModel: DetailViewModel
    var id: Int
    
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var movies: FetchedResults<MoviesToWatch>
    @Environment(\.managedObjectContext) var mocWatched
    @FetchRequest(sortDescriptors: []) var moviesWatched: FetchedResults<MoviesWatched>
    
    @State private var buttonMarkDisabled = false
    @State private var buttonCheckDisabled = false
    @State private var addButtonTitle = LC.addFavorites.text
    
    var body: some View {
        ZStack {
            if let detail = viewModel.detailMovie {
                AsyncImage(url: URL(string: Constants.basePosters + detail.posterPath)) { image in
                    image
                        .resizable()
                } placeholder: {
                    Image("placeholder-image")
                }
                
                ScrollView {
                    Spacer(minLength: UIScreen.main.bounds.height / 2)
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 16) {
                                    Text(detail.title)
                                        .font(.title)
                                        .bold()
                                    Spacer()
                                    Menu {
                                        Button("Want to Watch") {
                                            saveData(with: detail, isWatched: false)
                                        }
                                        .disabled(verifyIfExists(id: detail.id, verifyIn: .toWatch))
                                        
                                        Button("Watched") {
                                            saveData(with: detail, isWatched: true)
                                        }
                                        .disabled(verifyIfExists(id: detail.id, verifyIn: .wached))
                                        
                                    } label: {
                                        HStack {
//                                            Text(verifyIfExists(id: detail.id, verifyIn: .toWatch) ? "Added" : addButtonTitle)
//                                                .foregroundColor(verifyIfExists(id: detail.id, verifyIn: .wached) ? .gray : .black)
                                            ButtonFavorites(id: detail.id)
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 4)
                                        .background(.ultraThinMaterial.opacity(0.8))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                Text(LC.releaseDate.text + detail.releaseDateFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                Text(LC.average.text + detail.voteAverageFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 10)
                            
                            Text(detail.overview)
                                .font(.headline)
                                .padding(.horizontal, 10)
                        }
                        .padding()
                        
                        TrailersView(videoID: id, videoKey: viewModel.videoKey ?? "")
                            .padding(.horizontal, 16)
                            .frame(height: 260)
                        
                        if let cast = viewModel.cast?.cast {
                            CastView(state: .movie, castData: cast)
                                .padding(.leading, 10)
                        }
                        
                        ProvidersWatchView(
                            title: "Streaming",
                            providers: viewModel.providers?.flatrate,
                            link: viewModel.providers?.link ?? ""
                        )
                        
                        ProvidersWatchView(
                            title: "Rent",
                            providers: viewModel.providers?.rent,
                            link: viewModel.providers?.link ?? ""
                        )
                        
                        ProvidersWatchView(
                            title: "Buy",
                            providers: viewModel.providers?.buy,
                            link: viewModel.providers?.link ?? ""
                        )
                        
                        if let recommendations = viewModel.moviesRecommendations?.results {
                            CarouselInDetailView(data: recommendations, title: LC.recommendations.text)
                                .padding(.leading, 10)
                        }
                        
                        if let similars = viewModel.moviesSimilars?.results {
                            CarouselInDetailView(data: similars, title: LC.similars.text)
                                .padding(.leading, 10)
                        }
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                }
            }
        }
    }
    
    @ViewBuilder
    private func ButtonFavorites(id: Int) -> some View {
        if !verifyIfExists(id: id, verifyIn: .wached) {
            Text(verifyIfExists(id: id, verifyIn: .toWatch) ? "Added" : addButtonTitle)
                .foregroundColor(verifyIfExists(id: id, verifyIn: .toWatch) ? .gray : .black)
        } else {
            Text("Watched")
                .foregroundColor(.gray)
        }
    }
    
    @ViewBuilder
    private func ProvidersWatchView(title: String, providers: [WatchProvider]?, link: String) -> some View {
        if let providers = providers {
            ProvidersView(data: providers, title: title, link: link)
                .padding(.leading, 10)
        }
    }
    
    private func saveData(with detailData: DetailMoviesModel, isWatched: Bool) {
        if !verifyIfExists(id: detailData.id, verifyIn: .toWatch) {
            if !isWatched {
                let movie = MoviesToWatch(context: moc)
                movie.id = Int64(detailData.id)
                movie.name = detailData.title
                movie.overview = detailData.overview
                movie.profilePath = detailData.posterPath
                try? moc.save()
                
                buttonCheckDisabled = true
            } else {
                if !verifyIfExists(id: detailData.id, verifyIn: .wached) {
                    let movie = MoviesWatched(context: mocWatched)
                    movie.id = Int64(detailData.id)
                    movie.name = detailData.title
                    movie.overview = detailData.overview
                    movie.profilePath = detailData.posterPath
                    movie.counter = Double(detailData.runtime)
                    try? mocWatched.save()
                    
                    buttonCheckDisabled = true
                }
            }
        }
    }
    
    private func verifyIfExists(id: Int, verifyIn: DataBase) -> Bool {
        switch verifyIn {
        case .toWatch:
            let exist = movies.contains(where: {$0.id == id})
            return exist
        case .wached:
            let exist = moviesWatched.contains(where: {$0.id == id})
            return exist
        }
    }
    
    private func setWatchProviders(with data: WatchProviders) -> [WatchProvider] {
        let providers = data.results?.br?.flatrate ?? []
        
        return providers
    }
}
struct DetailCoreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailMoviesView(state: .movie, id: 287)
        }
    }
}
