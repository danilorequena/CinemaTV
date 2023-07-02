//
//  TopVotedMoviesView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/11/21.
//

import SwiftUI
import SwiftData

struct DefaultCarouselView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Query var moviesWatched: [MoviesWatched]
    
    let data: [MoviesTVShowResult]
    let title: String
    var selectionIndex: Int
    let isLightBackground: Bool
    let state: MovieORTVShow
    var body: some View {
        if data.isEmpty {
            CinemaTVProgressView()
        } else {
            VStack(alignment: .center) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .frame(width: 260, alignment: .leading)
                        
                    NavigationLink(destination: MoviesListView(title: title, selectionIndex: selectionIndex)) {
                        Text(LC.seeAll.text)
                            .font(.subheadline)
                            .frame(width: 80, alignment: .trailing)
                    }
                }
                .frame(width: UIScreen.main.bounds.width)
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(data) { movie in
                            NavigationLink(destination: DetailView(id: movie.id, state: state)) {
                                VStack(spacing: 2) {
                                    MovieCell(image: URL(string: Constants.basePosters + (movie.backdropPath ?? "")), watched: moviesWatched.contains { $0.id ?? 0 == movie.id ?? 0 })
                                    
                                    Text((movie.title ?? movie.name) ?? "")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 180)
                                }
                                .containerRelativeFrame(
                                    .horizontal,
                                    count: sizeClass == .regular ? 2 : 1,
                                    spacing: 10
                                )
                                .aspectRatio(contentMode: .fit)
                                .padding(.bottom, 4)
                                .buttonStyle(.plain)
                                .background(.ultraThinMaterial.opacity(0.8))
                                .cornerRadius(16)
                            }
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, 20)
                .scrollIndicators(.hidden)
            }
        }
    }
}

struct TopVotedMoviesView_Previews: PreviewProvider {
    static var previews: some View {
        DefaultCarouselView(
            data: MoviesTVShowResult.stubbedJsonsMovies,
            title: "Title",
            selectionIndex: 0,
            isLightBackground: false,
            state: .movie
        )
    }
}
