//
//  DiscoverySectionView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct DiscoverySectionView: View {
    let title: String
    let data: [MoviesTVShowResult]
    let state: MovieORTVShow
    var selectionIndex: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GlassSectionHeader(title: title, showSeeAll: true) {
                // Navigate to full list
            }

            if data.isEmpty {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .frame(height: 150)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(data) { item in
                            NavigationLink(destination: DetailView(id: item.id, state: state, showAddFavoritesButton: true)) {
                                VStack(spacing: 0) {
                                    MovieCell(image: URL(string: Constants.basePosters + (item.posterPath ?? "")))
                                        .frame(width: 120, height: 180)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))

                                    Text((item.title ?? item.name) ?? "")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .lineLimit(2)
                                        .multilineTextAlignment(.center)
                                        .frame(width: 120)
                                        .foregroundStyle(.primary)
                                        .padding(.vertical, 8)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DiscoverySectionView(
            title: "Popular",
            data: [],
            state: .movie
        )
    }
}
