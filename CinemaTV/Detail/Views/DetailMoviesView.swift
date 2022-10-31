//
//  DetailMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI

struct DetailMoviesView: View {
    @Environment(\.managedObjectContext) var moc
    @FetchRequest(sortDescriptors: []) var movies: FetchedResults<Movies>
    @State private var buttonMarkDisabled = false
    var state: MovieORTVShow
    @ObservedObject var viewModel = DetailViewModel()
    var id: Int?
    var body: some View {
        VStack {
            if viewModel.isDetailLoading && viewModel.isCastLoading {
                CinemaTVProgressView()
            } else {
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
                                                    let movie = Movies(context: moc)
                                                    movie.id = Int64(detail.id)
                                                    movie.name = detail.title
                                                    movie.overview = detail.overview
                                                    movie.profilePath = detail.posterPath
                                                    try? moc.save()
                                                    
                                                    buttonMarkDisabled = true
                                                } label: {
                                                    HStack {
                                                        Image(systemName: "bookmark.fill")
                                                            .foregroundColor(buttonMarkDisabled ? .gray : .yellow)
                                                        
                                                        Text("Want Watch")
                                                            .foregroundColor(.black)
                                                    }
                                                    .padding(8)
                                                    .background(.ultraThinMaterial.opacity(0.2))
                                                    .cornerRadius(32)
                                                }
                                                .disabled(buttonMarkDisabled)
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
                                    
                                    RecommendationsView(data: viewModel.moviesRecommendations?.results ?? [], title: LC.recommendations.text)
                                }
                                .background(.ultraThinMaterial)
                                .cornerRadius(16)
                            }
                        }
                    }
                }
            }
        }
        .edgesIgnoringSafeArea(.top)
        .task {
            await viewModel.loadDetails(ID: id ?? 0, state: state)
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

