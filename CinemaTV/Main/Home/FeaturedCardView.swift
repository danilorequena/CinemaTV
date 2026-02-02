//
//  FeaturedCardView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct FeaturedCardView: View {
    let imageURL: URL?
    let title: String
    let subtitle: String
    var progress: Double?
    let onTap: () -> Void
    @ScaledMetric private var cardHeight: CGFloat = 380
    @ScaledMetric private var cornerRadius: CGFloat = 28
    @ScaledMetric private var contentPadding: CGFloat = 18
    @ScaledMetric private var glassInset: CGFloat = 12
    @ScaledMetric private var infoSpacing: CGFloat = 8
    @ScaledMetric private var badgeSpacing: CGFloat = 6
    @ScaledMetric private var badgeHorizontalPadding: CGFloat = 10
    @ScaledMetric private var badgeVerticalPadding: CGFloat = 6
    @ScaledMetric private var progressRingSize: CGFloat = 56
    @ScaledMetric private var progressRingLineWidth: CGFloat = 6

    var body: some View {
        let clampedProgress = max(0, min(progress ?? 0, 1))

        Button(action: onTap) {
            GlassEffectContainer(spacing: infoSpacing) {
                ZStack(alignment: .bottomLeading) {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(.ultraThinMaterial)
                                .overlay {
                                    ProgressView()
                                }
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Rectangle()
                                .fill(.quaternary)
                                .overlay {
                                    Image(systemName: "photo")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                }
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: cardHeight)
                    .visualEffect { content, geometry in
                        let offset = geometry.frame(in: .scrollView(axis: .vertical)).minY
                        return content.offset(y: -offset * 0.08)
                    }
                    .clipped()

                    LinearGradient(
                        colors: [.clear, .black.opacity(0.25), .black.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    GlassCardView(isInteractive: true, cornerRadius: cornerRadius, tint: .none) {
                        VStack(alignment: .leading, spacing: infoSpacing) {
                            if progress != nil {
                                Label("Continue Watching", systemImage: "play.fill")
                                    .font(.caption.bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, badgeHorizontalPadding)
                                    .padding(.vertical, badgeVerticalPadding)
                                    .glassEffect(
                                        .clear.tint(.white.opacity(0.2)).interactive(),
                                        in: .capsule
                                    )
                            }

                            Text(title)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .lineLimit(2)

                            if !subtitle.isEmpty {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.85))
                                    .lineLimit(2)
                            }

                            if progress != nil {
                                HStack(spacing: badgeSpacing) {
                                    Text("Season Progress")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.8))

                                    Text("\(Int(clampedProgress * 100))%")
                                        .font(.caption.bold())
                                        .foregroundStyle(.white)
                                        .contentTransition(.numericText())
                                        .monospacedDigit()
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(contentPadding)
                    }
                    .padding(glassInset)
                }
                .overlay(alignment: .topTrailing) {
                    if progress != nil {
                        HeroProgressRingView(
                            progress: clampedProgress,
                            size: progressRingSize,
                            lineWidth: progressRingLineWidth
                        )
                        .padding(glassInset)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .frame(height: cardHeight)
        .clipShape(.rect(cornerRadius: cornerRadius))
        .scrollTransition(.interactive, axis: .vertical) { content, phase in
            content
                .scaleEffect(phase.isIdentity ? 1 : 0.98)
                .opacity(phase.isIdentity ? 1 : 0.95)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(title))
        .accessibilityValue(progress != nil ? Text("\(Int(clampedProgress * 100)) percent") : Text(subtitle))
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        FeaturedCardView(
            imageURL: URL(string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg"),
            title: "Breaking Bad",
            subtitle: "A high school chemistry teacher turned methamphetamine producer.",
            progress: 0.65
        ) {
            print("Tapped")
        }
        .padding()
    }
}
