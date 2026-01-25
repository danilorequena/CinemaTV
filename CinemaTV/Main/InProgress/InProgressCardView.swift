//
//  InProgressCardView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 25/01/26.
//

import SwiftUI

struct InProgressCardView: View {
    let item: InProgressItem

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            AsyncImage(url: item.imageURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    Rectangle()
                        .fill(Color.clear)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 180)
            .clipped()

            // Gradient overlay
            LinearGradient(
                colors: [.clear, .black.opacity(0.6), .black.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )

            // Content
            VStack(alignment: .leading, spacing: 6) {
                if item.isMovie {
                    IncompleteBadge()
                }

                Text(item.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .lineLimit(1)

                if let episodeInfo = item.episodeInfo {
                    Text(episodeInfo)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                } else {
                    Text(item.subtitle)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                        .lineLimit(2)
                }

                if let progress = item.progress {
                    HStack(spacing: 8) {
                        ProgressView(value: progress)
                            .tint(.white)

                        Text("\(Int(progress * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
            }
            .padding(12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
    }
}

#Preview {
    VStack(spacing: 16) {
        InProgressCardView(
            item: InProgressItem(
                id: "tv-1",
                tmdbId: 1,
                type: .tvShow(seasonNumber: 2, episodeNumber: 5, episodeName: "The One Where..."),
                imageURL: URL(string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg"),
                title: "Breaking Bad",
                subtitle: "A high school chemistry teacher...",
                progress: 0.65,
                lastUpdated: Date()
            )
        )

        InProgressCardView(
            item: InProgressItem(
                id: "movie-1",
                tmdbId: 2,
                type: .movie,
                imageURL: URL(string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg"),
                title: "Inception",
                subtitle: "A thief who steals corporate secrets...",
                progress: nil,
                lastUpdated: Date()
            )
        )
    }
    .padding()
    .background(Color.black)
}
