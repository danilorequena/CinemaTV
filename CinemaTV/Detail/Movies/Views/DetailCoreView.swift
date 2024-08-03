//
//  DetailCoreView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 23/11/22.
//

import SwiftUI
import SwiftData

struct DetailCoreView: View {
    @Environment(\.modelContext) var modelContext
    @Query var movies: [MoviesToWatch]
    @Query var moviesWatched: [MoviesWatched]
    @EnvironmentObject private var viewModel: DetailViewModel
    
    var id: Int
    var showAddFavoritesButton: Bool
    let dataManager = MoviesDatabaseManager()
    
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
                                    
                                    MenuOptionsDetailView(
                                        dataManager: dataManager,
                                        detail: detail,
                                        modelContext: modelContext,
                                        movies: movies,
                                        moviesWatched: moviesWatched,
                                        showAddFavoritesButton: showAddFavoritesButton
                                    )
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
                            .frame(height: 260)
                            .padding(16)
                        
                        if let cast = viewModel.cast?.cast, !cast.isEmpty {
                            CastView(state: .movie, castData: cast)
                        }
                        
                        if let flatrate = viewModel.providers?.flatrate, !flatrate.isEmpty {
                            ProvidersView(data: flatrate, title: "Streaming", link: viewModel.providers?.link ?? "")
                            
                        }
                        
                        ForEach(0..<2) { index in
                            if let rent = viewModel.providers?.rent, !rent.isEmpty,
                               let buy = viewModel.providers?.buy, !buy.isEmpty {
                                ProvidersView(
                                    data: index == 0 ? rent : buy,
                                    title: index == 0 ? "Rent" : "Buy",
                                    link: viewModel.providers?.link ?? ""
                                )
                            }
                        }
                        
                        ForEach(0..<2) { index in
                            if let recommendations = viewModel.moviesRecommendations?.results, !recommendations.isEmpty,
                               let similars = viewModel.moviesSimilars?.results, !similars.isEmpty {
                                CarouselInDetailView(
                                    data: index == 0 ? recommendations : similars,
                                    title: index == 0 ? LC.recommendations.text : LC.similars.text
                                )
                            }
                        }
                    }
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.bottom, 16)
                }
            }
        }
    }
}

#Preview {
    DetailMoviesView(
        state: .movie,
        id: 287,
        showAddFavoritesButton: true
    )
    .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self])
}
