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
                                        Button("Want to Watch") {saveData(with: detail, isWatched: false) }
                                        Button("Watched") {saveData(with: detail, isWatched: true) }
                                            .disabled(verifyIfExists(id: detail.id, verifyIn: .wached))
                                    } label: {
                                        HStack {
                                            Image(systemName: "bookmark.fill")
                                                .foregroundColor(verifyIfExists(id: detail.id, verifyIn: .toWatch) ? .gray : .pink)
                                            
                                            Text(LC.addFavorites.text)
                                                .foregroundColor(.black)
                                        }
                                        .padding(8)
                                        .background(.ultraThinMaterial.opacity(0.2))
                                        .cornerRadius(16)
                                    }
                                    .padding(.horizontal, 16)
                                }
                                
                                Text(LC.releaseDate.text + detail.releaseDateFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                Text(LC.average.text + detail.voteAverageFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                            
                            Text(detail.overview)
                                .font(.headline)
                        }
                        .padding()
                        
                        TrailersView(videoID: id, videoKey: viewModel.videoKey ?? "")
                            .padding(16)
                            .frame(height: 260)
                        
                        if let cast = viewModel.cast?.cast {
                            CastView(state: .movie, castData: cast)
                                .padding(.leading, 10)
                        }
                        
                        if let flatrate = viewModel.providers?.flatrate {
                            ProvidersView(data: flatrate, title: "Streaming", link: viewModel.providers?.link ?? "")
                                .padding(.leading, 10)

                        }
                        
                        if let rent = viewModel.providers?.rent {
                            ProvidersView(data: rent, title: "Rent", link: viewModel.providers?.link ?? "")
                                .padding(.leading, 10)
                        }
                        
                        if let buy = viewModel.providers?.buy {
                            ProvidersView(data: buy, title: "Buy", link: viewModel.providers?.link ?? "")
                                .padding(.leading, 10)
                        }
                        
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
    
    func placeOrder() { }
    func adjustOrder() { }
    func cancelOrder() { }
}
struct DetailCoreView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailMoviesView(state: .movie, id: 287)
        }
    }
}
