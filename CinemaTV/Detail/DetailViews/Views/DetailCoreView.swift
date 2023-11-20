//
//  DetailCoreView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 23/11/22.
//

import SwiftUI
import SwiftData

struct DetailCoreView: View {
    @Environment(\.modelContext) var moc
    @Environment(\.modelContext) var mocWatched
    @Query var movies: [MoviesToWatch]
    @Query var moviesWatched: [MoviesWatched]
    
    @State private var buttonMarkDisabled = false
    @State private var buttonCheckDisabled = false
    
    let viewModel: DetailViewModel
    var id: Int
    var showAddFavoritesButton: Bool
    
    var body: some View {
        ZStack {
            if let detail = viewModel.detailMovie {
                AsyncImage(url: URL(string: Constants.basePosters + (detail.posterPath ?? ""))) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                    } else if phase.error != nil {
                        Image("placeholder-image")
                            .resizable()
                    } else {
                        Image("placeholder-image")
                            .resizable()
                    }
                }
                
                ScrollView {
                    Spacer(minLength: UIScreen.main.bounds.height / 2)
                    VStack(spacing: 16) {
                        VStack(spacing: 16) {
                            RoundedRectangle(cornerRadius: 25)
                                .frame(width: 50, height: 6)
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 16) {
                                    Text(detail.title)
                                        .font(.title)
                                        .bold()
                                    Spacer()
                                    if showAddFavoritesButton {
                                        Menu {
                                            Button("Want to Watch") { saveData(with: detail, isWatched: false) }
                                                .disabled(verifyIfExists(id: detail.id, verifyIn: .toWatch))
                                            Button("Watched") { saveData(with: detail, isWatched: true) }
                                        } label: {
                                            HStack {
                                                if !verifyIfExists(id: detail.id, verifyIn: .wached) {
                                                    Image(systemName: "bookmark.fill")
                                                        .foregroundColor(changeColor(id: detail.id))
                                                } else {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.green)
                                                }
                                                
                                                Text(changeTitle(id: detail.id))
                                                    .foregroundColor(.black)
                                            }
                                            .padding(8)
                                            .background(.ultraThinMaterial.opacity(0.2))
                                            .cornerRadius(16)
                                        }
                                        .disabled(verifyIfExists(id: detail.id))
                                    }
                                }
                                
                                Text(LC.releaseDate.text + detail.releaseDateFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                                
                                Text(LC.average.text + detail.voteAverageFormatted)
                                    .font(.subheadline)
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 8)
                            
                            Text(detail.overview)
                                .font(.headline)
                                .padding(.horizontal, 8)
                        }
                        .padding()
                        
                        TrailersView(videoID: id, videoKey: viewModel.videoKey ?? "")
                            .frame(height: 260)
                            .padding(16)
                        
                        if let cast = viewModel.cast?.cast, !cast.isEmpty {
                            CastView(state: .movie, castData: cast)
                                .padding(.leading, 10)
                        }
                        
                        if let flatrate = viewModel.providers?.flatrate, !flatrate.isEmpty {
                            ProvidersView(data: flatrate, title: "Streaming", link: viewModel.providers?.link ?? "")
                                .padding(.leading, 10)

                        }
                        
                        if let rent = viewModel.providers?.rent, !rent.isEmpty {
                            ProvidersView(data: rent, title: "Rent", link: viewModel.providers?.link ?? "")
                                .padding(.leading, 10)
                        }
                        
                        if let buy = viewModel.providers?.buy, !buy.isEmpty {
                            ProvidersView(data: buy, title: "Buy", link: viewModel.providers?.link ?? "")
                                .padding(.leading, 10)
                        }
                        
                        if let recommendations = viewModel.moviesRecommendations?.results, !recommendations.isEmpty {
                            CarouselInDetailView(data: recommendations, title: LC.recommendations.text)
                                .padding(.leading, 10)
                        }
                        
                        if let similars = viewModel.moviesSimilars?.results, !similars.isEmpty {
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
                let movie = MoviesToWatch(
                    id: Int64(detailData.id),
                    counter: Double(detailData.runtime),
                    name: detailData.title,
                    overview: detailData.overview,
                    profilePath: detailData.posterPath
                )
                moc.insert(movie)
                try? moc.save()
                
                buttonCheckDisabled = true
            } else {
                if !verifyIfExists(id: detailData.id, verifyIn: .wached) {
                    let movie = MoviesWatched(
                        counter: Double(detailData.runtime),
                        id: Int64(detailData.id),
                        name: detailData.title,
                        overview: detailData.overview,
                        profilePath: detailData.posterPath
                    )
                    mocWatched.insert(movie)
                    try? mocWatched.save()
                    
                    buttonCheckDisabled = true
                }
            }
        }
    }
    
    private func verifyIfExists(id: Int, verifyIn: DataBase) -> Bool {
        switch verifyIn {
        case .toWatch:
            let exist = movies.contains(where: {$0.id ?? 0 == id})
            return exist
        case .wached:
            let exist = moviesWatched.contains(where: {$0.id ?? 0 == id})
            return exist
        }
    }
    
    private func verifyIfExists(id: Int) -> Bool {
        if movies.contains(where: {$0.id ?? 0 == id}) || moviesWatched.contains(where: {$0.id ?? 0 == id}) {
            return true
        }
        
        return false
    }
    
    private func changeColor(id: Int) -> Color {
        if moviesWatched.contains(where: {$0.id ?? 0 == id}) {
            return .gray
        } else if movies.contains(where: {$0.id ?? 0 == id}) {
            return .accentColor
        } else {
            return .pink
        }
    }
    
    private func changeTitle(id: Int) -> String {
        if moviesWatched.contains(where: {$0.id ?? 0 == id}) {
            return "Watched"
        } else if movies.contains(where: {$0.id ?? 0 == id}) {
            return "Want Watch"
        } else {
            return LC.addFavorites.text
        }
    }
    
    private func setWatchProviders(with data: WatchProviders) -> [WatchProvider] {
        let providers = data.results?.br?.flatrate ?? []
        
        return providers
    }
}

#Preview {
    DetailMoviesView(state: .movie, id: 287, showAddFavoritesButton: true)
        .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self])
}
