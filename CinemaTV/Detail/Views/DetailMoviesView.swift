//
//  DetailMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI

enum DataBase {
    case toWatch
    case wached
}

struct DetailMoviesView: View {
    var state: MovieORTVShow
    var id: Int?
    
    @ObservedObject var viewModel = DetailViewModel()
    
    var body: some View {
        VStack {
            if viewModel.isDetailLoading && viewModel.isCastLoading {
                CinemaTVProgressView()
            } else {
                DetailCoreView(viewModel: viewModel, id: id ?? 0)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .task {
            await viewModel.loadDetails(ID: id ?? 0, state: state)
        }
    }
}

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
                                            if !verifyIfExists(id: detail.id, verifyIn: .toWatch) {
                                                let movie = MoviesToWatch(context: moc)
                                                movie.id = Int64(detail.id)
                                                movie.name = detail.title
                                                movie.overview = detail.overview
                                                movie.profilePath = detail.posterPath
                                                try? moc.save()
                                                buttonMarkDisabled = true
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "bookmark.fill")
                                                    .foregroundColor(verifyIfExists(id: detail.id, verifyIn: .toWatch) ? .gray : .yellow)
                                                
                                                Text("Watch")
                                                    .foregroundColor(.black)
                                            }
                                            .padding(8)
                                            .background(.ultraThinMaterial.opacity(0.2))
                                            .cornerRadius(16)
                                        }
                                        .disabled(verifyIfExists(id: detail.id, verifyIn: .toWatch))
                                        
                                        Button {
                                            if !verifyIfExists(id: detail.id, verifyIn: .wached) {
                                                let movie = MoviesWatched(context: mocWatched)
                                                movie.id = Int64(detail.id)
                                                movie.name = detail.title
                                                movie.overview = detail.overview
                                                movie.profilePath = detail.posterPath
                                                try? mocWatched.save()
                                                
                                                buttonCheckDisabled = true
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(verifyIfExists(id: detail.id, verifyIn: .wached) ? .gray : .green)
                                                
                                                Text("Watched")
                                                    .foregroundColor(.black)
                                            }
                                            .padding(8)
                                            .background(.ultraThinMaterial.opacity(0.2))
                                            .cornerRadius(32)
                                        }
                                        .disabled(verifyIfExists(id: detail.id, verifyIn: .wached))
                                    }
                                    
                                    Text(LC.releaseDate.text + detail.releaseDate.formatString())
                                        .font(.subheadline)
                                        .foregroundColor(.black)
                                    
                                    Text(LC.average.text + "\(detail.voteAverage.description)/10")
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
}

struct DetailMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            DetailMoviesView(state: .movie, id: 287)
        }
    }
}
