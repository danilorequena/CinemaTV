//
//  StarRatingInput.swift
//  CinemaTVKit
//
//  Nota pessoal em meias estrelas (0.5...5.0). Input por toque/arraste
//  sobre a fileira; StarRatingDisplay é a variante read-only, reusada
//  pelo ReviewShareCard.
//

import SwiftUI

public struct StarRatingInput: View {
    @Binding private var rating: Double
    private let starSize: CGFloat

    @Environment(\.layoutDirection) private var layoutDirection
    @State private var rowWidth: CGFloat = 0

    public init(rating: Binding<Double>, starSize: CGFloat = 36) {
        self._rating = rating
        self.starSize = starSize
    }

    public var body: some View {
        StarRow(rating: rating, starSize: starSize)
            .contentShape(.rect)
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.width
            } action: { width in
                rowWidth = width
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        update(with: value.location.x)
                    }
            )
            .sensoryFeedback(.selection, trigger: rating)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Rating", bundle: .module))
            .accessibilityValue(Text(rating, format: .number.precision(.fractionLength(0...1))))
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    rating = min(rating + 0.5, 5)
                case .decrement:
                    rating = max(rating - 0.5, 0.5)
                @unknown default:
                    break
                }
            }
    }

    private func update(with locationX: CGFloat) {
        guard rowWidth > 0 else { return }
        var fraction = locationX / rowWidth
        if layoutDirection == .rightToLeft {
            fraction = 1 - fraction
        }
        // Preenche até o cursor: arredonda para cima na meia estrela.
        let snapped = (fraction * 5 * 2).rounded(.up) / 2
        rating = min(max(snapped, 0.5), 5)
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
        StarRow(rating: rating, starSize: starSize)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text("Rating", bundle: .module))
            .accessibilityValue(Text(rating, format: .number.precision(.fractionLength(0...1))))
    }
}

private struct StarRow: View {
    let rating: Double
    let starSize: CGFloat

    var body: some View {
        HStack(spacing: starSize * 0.2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: symbolName(for: star))
                    .font(.system(size: starSize))
            }
        }
        .foregroundStyle(DSColor.accent)
    }

    private func symbolName(for star: Int) -> String {
        if rating >= Double(star) {
            "star.fill"
        } else if rating >= Double(star) - 0.5 {
            // leadinghalf flipa sozinho em RTL.
            "star.leadinghalf.filled"
        } else {
            "star"
        }
    }
}

#Preview("Input + Display", traits: .sizeThatFitsLayout) {
    @Previewable @State var rating = 3.5
    VStack(spacing: DSSpacing.lg) {
        StarRatingInput(rating: $rating)
        StarRatingDisplay(rating: rating)
        Text(rating, format: .number.precision(.fractionLength(0...1)))
            .font(.dsCaption)
    }
    .padding()
}
