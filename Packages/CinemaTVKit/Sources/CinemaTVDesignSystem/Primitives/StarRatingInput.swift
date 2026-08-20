//
//  StarRatingInput.swift
//  CinemaTVKit
//
//  Nota pessoal em estrelas inteiras (1...5). Input por toque ou arraste;
//  StarRatingDisplay é a variante read-only, reusada
//  pelo ReviewShareCard.
//

import SwiftUI

public struct StarRatingInput: View {
    @Binding private var rating: Double
    private let starSize: CGFloat

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var bounceTriggers = Array(repeating: 0, count: 5)
    @State private var rotationTriggers = Array(repeating: 0, count: 5)
    @State private var rotationDirections = Array(repeating: 0.0, count: 5)
    @State private var lastDragLocationX: CGFloat?

    public init(rating: Binding<Double>, starSize: CGFloat = 32) {
        self._rating = rating
        self.starSize = starSize
    }

    public var body: some View {
        StarRow(
            rating: rating.rounded(),
            starSize: starSize,
            animatesChanges: true,
            bounceTriggers: bounceTriggers,
            rotationTriggers: rotationTriggers,
            rotationDirections: rotationDirections
        )
            .overlay {
                HStack(spacing: 0) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            setRating(Double(star))
                        } label: {
                            Color.clear
                                .frame(width: max(starSize, 44), height: 44)
                                .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .accessibilityHidden(true)
            }
            .highPriorityGesture(
                DragGesture(minimumDistance: 6)
                    .onChanged(updateRating(with:))
                    .onEnded { _ in
                        lastDragLocationX = nil
                    }
            )
            .sensoryFeedback(.selection, trigger: rating)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Rating", bundle: .module))
            .accessibilityValue(Text(rating.rounded(), format: .number.precision(.fractionLength(0))))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    setRating(min(rating + 1, 5))
                case .decrement:
                    setRating(max(rating - 1, 1))
                @unknown default:
                    break
                }
            }
    }

    private func updateRating(with value: DragGesture.Value) {
        let rowWidth = max(starSize, 44) * 5
        let currentX = value.location.x
        let previousX = lastDragLocationX ?? value.startLocation.x
        let rotationDirection = currentX >= previousX ? 1.0 : -1.0
        lastDragLocationX = currentX

        var fraction = min(max(currentX / rowWidth, 0), 1)
        if layoutDirection == .rightToLeft {
            fraction = 1 - fraction
        }

        let selectedRating = min(max(Int(fraction * 5) + 1, 1), 5)
        let previousRating = min(max(Int(rating.rounded()), 0), 5)
        guard selectedRating != previousRating else { return }

        if reduceMotion {
            rating = Double(selectedRating)
            return
        }

        let changedStars = selectedRating > previousRating
            ? (previousRating + 1)...selectedRating
            : (selectedRating + 1)...previousRating

        withAnimation(DSMotion.ratingSelection) {
            for star in changedStars {
                rotationDirections[star - 1] = rotationDirection
                rotationTriggers[star - 1] += 1
            }
            rating = Double(selectedRating)
        }
    }

    private func setRating(_ newRating: Double) {
        let normalizedRating = min(max(newRating.rounded(), 1), 5)
        guard normalizedRating != rating else { return }

        if reduceMotion {
            rating = normalizedRating
            return
        }

        let previousRating = min(max(Int(rating.rounded()), 0), 5)
        let selectedRating = Int(normalizedRating)

        withAnimation(DSMotion.ratingSelection) {
            if selectedRating > previousRating {
                for star in (previousRating + 1)...selectedRating {
                    bounceTriggers[star - 1] += 1
                }
            }
            rating = normalizedRating
        }
    }
}

/// Fileira de estrelas read-only (card de compartilhamento, resumos).
public struct StarRatingDisplay: View {
    private let rating: Double
    private let starSize: CGFloat

    public init(rating: Double, starSize: CGFloat = 16) {
        self.rating = rating
        self.starSize = starSize
    }

    public var body: some View {
        StarRow(
            rating: rating.rounded(),
            starSize: starSize,
            animatesChanges: false,
            bounceTriggers: [],
            rotationTriggers: [],
            rotationDirections: []
        )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Rating", bundle: .module))
            .accessibilityValue(Text(rating.rounded(), format: .number.precision(.fractionLength(0))))
    }
}

private struct StarRow: View {
    let rating: Double
    let starSize: CGFloat
    let animatesChanges: Bool
    let bounceTriggers: [Int]
    let rotationTriggers: [Int]
    let rotationDirections: [Double]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let cellSize = animatesChanges ? max(starSize, 44) : starSize
        let spacing = animatesChanges ? 0 : starSize * 0.2
        let revealScale = DSMotion.ratingRevealScale
        let glowRadius = DSMotion.ratingGlowRadius
        let rotationAngle = DSMotion.ratingDragRotation
        let reducesMotion = reduceMotion

        HStack(spacing: spacing) {
            ForEach(1...5, id: \.self) { star in
                let isFilled = rating >= Double(star)
                let triggerIndex = star - 1
                let bounceTrigger = bounceTriggers.indices.contains(triggerIndex)
                    ? bounceTriggers[triggerIndex]
                    : 0
                let rotationTrigger = rotationTriggers.indices.contains(triggerIndex)
                    ? rotationTriggers[triggerIndex]
                    : 0
                let rotationDirection = rotationDirections.indices.contains(triggerIndex)
                    ? rotationDirections[triggerIndex]
                    : 0
                let maskScale = reduceMotion || !animatesChanges
                    ? revealScale
                    : (isFilled ? revealScale : 0.01)

                ZStack {
                    Image(systemName: "star")
                        .foregroundStyle(.tertiary)

                    Image(systemName: "star.fill")
                        .foregroundStyle(DSColor.accent)
                        .mask {
                            Circle()
                                .scaleEffect(maskScale)
                        }
                        .opacity(isFilled ? 1 : 0)
                        .shadow(
                            color: DSColor.accent.opacity(isFilled && animatesChanges ? 0.4 : 0),
                            radius: isFilled && animatesChanges ? glowRadius : 0
                        )
                        .animation(animation(isFilled: isFilled), value: isFilled)
                }
                .font(.system(size: starSize))
                .frame(width: cellSize, height: cellSize)
                .symbolEffect(
                    .bounce.up.wholeSymbol,
                    options: .nonRepeating,
                    value: bounceTrigger
                )
                .symbolEffectsRemoved(reduceMotion || !animatesChanges)
                .keyframeAnimator(
                    initialValue: CGFloat.zero,
                    trigger: rotationTrigger
                ) { content, progress in
                    content.rotationEffect(
                        .degrees(
                            reducesMotion
                                ? 0
                                : Double(progress) * rotationDirection * rotationAngle
                        )
                    )
                } keyframes: { _ in
                    KeyframeTrack {
                        CubicKeyframe(1, duration: 0.36)
                    }
                }
            }
        }
    }

    private func animation(isFilled: Bool) -> Animation? {
        guard animatesChanges else { return nil }
        guard !reduceMotion else { return DSMotion.subtleFade }
        return isFilled ? DSMotion.ratingSelection : DSMotion.snappy
    }
}

#Preview("Input + Display", traits: .sizeThatFitsLayout) {
    @Previewable @State var rating = 4.0
    VStack(spacing: DSSpacing.lg) {
        StarRatingInput(rating: $rating)
        StarRatingDisplay(rating: rating)
        Text(rating, format: .number.precision(.fractionLength(0)))
            .font(.dsCaption)
    }
    .padding()
}
