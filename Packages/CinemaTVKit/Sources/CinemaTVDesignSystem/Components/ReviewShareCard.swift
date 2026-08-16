//
//  ReviewShareCard.swift
//  CinemaTVKit
//
//  Card 4:5 do review pessoal, desenhado para exportar via ImageRenderer
//  (1080×1350 a 3x). Só primitivas que o ImageRenderer sabe desenhar:
//  nada de AsyncImage, glassEffect ou Material — o poster chega
//  pré-carregado como Image.
//

import SwiftUI

public struct ReviewShareCard: View {
    /// Tamanho de design em pontos; exportar com scale 3 dá 1080×1350.
    public static let size = CGSize(width: 360, height: 450)

    private let title: String
    private let rating: Double
    private let reviewText: String
    private let poster: Image?

    public init(title: String, rating: Double, reviewText: String, poster: Image?) {
        self.title = title
        self.rating = rating
        self.reviewText = reviewText
        self.poster = poster
    }

    public var body: some View {
        VStack(spacing: DSSpacing.md) {
            posterView
                .frame(width: 120, height: 180)
                .clipShape(.rect(cornerRadius: DSRadius.poster))
                .overlay {
                    RoundedRectangle(cornerRadius: DSRadius.poster)
                        .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.5), radius: 16, y: 10)

            Text(verbatim: title)
                .font(.dsSectionTitle)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            HStack(spacing: DSSpacing.sm) {
                StarRatingDisplay(rating: rating, starSize: 18)
                Text(rating, format: .number.precision(.fractionLength(0...1)))
                    .font(.dsCaption.monospacedDigit())
                    .foregroundStyle(.secondary)
            }

            if !reviewText.isEmpty {
                Text(verbatim: "\u{201C}\(reviewText)\u{201D}")
                    .font(.subheadline.italic())
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .lineLimit(4)
            }

            Spacer(minLength: 0)

            HStack(spacing: DSSpacing.xs) {
                Image(systemName: "movieclapper")
                Text(verbatim: "CinemaTV")
            }
            .font(.dsCaption)
            .foregroundStyle(DSColor.accent)
        }
        .padding(.horizontal, DSSpacing.xl)
        .padding(.vertical, DSSpacing.lg)
        .frame(width: Self.size.width, height: Self.size.height)
        .background { background }
        .clipped()
        .foregroundStyle(.white)
        .colorScheme(.dark)
    }

    @ViewBuilder
    private var posterView: some View {
        if let poster {
            poster
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.white.opacity(0.08))
                .overlay {
                    Image(systemName: "movieclapper")
                        .font(.title)
                        .foregroundStyle(DSColor.accent)
                        .accessibilityHidden(true)
                }
        }
    }

    private var background: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.16, green: 0.12, blue: 0.05), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            if let poster {
                // Eco do poster desfocado como fundo; blur renderiza bem
                // no ImageRenderer (diferente de glass/material).
                poster
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: Self.size.width, height: Self.size.height)
                    .blur(radius: 60)
                    .opacity(0.55)
                Color.black.opacity(0.45)
            }
        }
    }
}

#Preview("Com texto longo", traits: .sizeThatFitsLayout) {
    ReviewShareCard(
        title: "Everything Everywhere All at Once",
        rating: 4.5,
        reviewText: "Uma viagem absurda e emocionante pelos multiversos. A Michelle Yeoh carrega o filme inteiro e o terceiro ato é de chorar. Melhor coisa que vi no ano, sem dúvida nenhuma.",
        poster: nil
    )
    .padding()
}

#Preview("Sem texto", traits: .sizeThatFitsLayout) {
    ReviewShareCard(
        title: "The Matrix",
        rating: 5,
        reviewText: "",
        poster: nil
    )
    .padding()
}
