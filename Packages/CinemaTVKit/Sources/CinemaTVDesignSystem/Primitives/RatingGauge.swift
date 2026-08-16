//
//  RatingGauge.swift
//  CinemaTVKit
//
//  Nota 0...10 em gauge circular com draw-on animado. Substitui os textos
//  "Average: X" do detail legado.
//

import SwiftUI

@Animatable
public struct RatingGauge: View {
    public var value: Double

    @AnimatableIgnored private var showsLabel: Bool

    public init(value: Double, showsLabel: Bool = true) {
        self.value = value
        self.showsLabel = showsLabel
    }

    private var fraction: Double {
        min(max(value / 10, 0), 1)
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 4)
            Circle()
                .trim(from: 0, to: fraction)
                .stroke(
                    DSColor.rating(for: value),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            if showsLabel {
                Text(value, format: .number.precision(.fractionLength(1)))
                    .font(.dsCaption.monospacedDigit())
                    .contentTransition(.numericText(value: value))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Rating", bundle: .module))
        .accessibilityValue(Text(value, format: .number.precision(.fractionLength(1))))
    }
}

#Preview("Ratings", traits: .sizeThatFitsLayout) {
    HStack(spacing: DSSpacing.lg) {
        RatingGauge(value: 8.4).frame(width: 44, height: 44)
        RatingGauge(value: 6.1).frame(width: 44, height: 44)
        RatingGauge(value: 3.7).frame(width: 44, height: 44)
    }
    .padding()
}
