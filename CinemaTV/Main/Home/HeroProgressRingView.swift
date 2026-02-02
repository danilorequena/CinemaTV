//
//  HeroProgressRingView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 02/02/26.
//

import SwiftUI

struct HeroProgressRingView: View {
    let progress: Double
    var size: CGFloat = 56
    var lineWidth: CGFloat = 6

    var body: some View {
        let clampedProgress = max(0, min(progress, 1))

        ZStack {
            Circle()
                .glassEffect(
                    .clear.tint(.white.opacity(0.25)).interactive(),
                    in: .circle
                )

            Circle()
                .stroke(lineWidth: lineWidth)
                .foregroundStyle(.white.opacity(0.2))

            Circle()
                .trim(from: 0, to: clampedProgress)
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .foregroundStyle(.white)

            Text("\(Int(clampedProgress * 100))%")
                .font(.caption2.bold())
                .foregroundStyle(.white)
                .contentTransition(.numericText())
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: clampedProgress)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Progress"))
        .accessibilityValue(Text("\(Int(clampedProgress * 100)) percent"))
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.black, .gray], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        HeroProgressRingView(progress: 0.72)
    }
}
