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
                    VStack {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(spacing: 16) {
                                        Text(detail.title)
                                            .font(.title)
                                            .bold()
                                        
                                        Button {
                                            saveData(with: detail, isWatched: false)
                                        } label: {
                                            HStack {
                                                Image(systemName: "bookmark.fill")
                                                    .foregroundColor(verifyIfExists(id: detail.id, verifyIn: .toWatch) ? .gray : .yellow)
                                                
                                                Text(LC.watchButton.text)
                                                    .foregroundColor(.black)
                                            }
                                            .padding(8)
                                            .background(.ultraThinMaterial.opacity(0.2))
                                            .cornerRadius(16)
                                        }
                                        .disabled(verifyIfExists(id: detail.id, verifyIn: .toWatch))
                                        
                                        Button {
                                            saveData(with: detail, isWatched: true)
                                        } label: {
                                            HStack {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(verifyIfExists(id: detail.id, verifyIn: .wached) ? .gray : .green)
                                                
                                                Text(LC.watchedButton.text)
                                                    .foregroundColor(.black)
                                            }
                                            .padding(8)
                                            .background(.ultraThinMaterial.opacity(0.2))
                                            .cornerRadius(32)
                                        }
                                        .disabled(verifyIfExists(id: detail.id, verifyIn: .wached))
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
                                CastView(
                                    state: .movie,
                                    castData: cast
                                )
                            }
                            
                            ProvidersView(data: viewModel.providers?.flatrate ?? [], title: "Streaming", link: viewModel.providers?.link ?? "")
                            
                            ProvidersView(data: viewModel.providers?.rent ?? [], title: "Rent", link: viewModel.providers?.link ?? "")
                            
                            ProvidersView(data: viewModel.providers?.buy ?? [], title: "Buy", link: viewModel.providers?.link ?? "")
                            
                            
                            CarouselInDetailView(data: viewModel.moviesRecommendations?.results ?? [], title: LC.recommendations.text)
                            
                            CarouselInDetailView(data: viewModel.moviesSimilars?.results ?? [], title: LC.similars.text)
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
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