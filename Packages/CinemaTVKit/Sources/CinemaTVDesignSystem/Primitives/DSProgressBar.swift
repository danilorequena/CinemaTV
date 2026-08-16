//
//  DSProgressBar.swift
//  CinemaTVKit
//
//  Barra de progresso fina para tracking de séries (temporadas e shows).
//

import SwiftUI

public struct DSProgressBar: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let progress: Double

    /// progress em 0...1 (valores fora da faixa são clampados).
    public init(progress: Double) {
        self.progress = progress.isFinite ? min(max(progress, 0), 1) : 0
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                Capsule()
                    .fill(DSColor.accent)
                    .frame(width: proxy.size.width * progress)
            }
        }
        .frame(height: 5)
        // Animação interna: quem marca episódios não precisa envolver a
        // mutação em withAnimation para a barra deslizar.
        .animation(DSMotion.respecting(reduceMotion, DSMotion.standard), value: progress)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: progress.formatted(.percent.precision(.fractionLength(0)))))
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: DSSpacing.lg) {
        DSProgressBar(progress: 0)
        DSProgressBar(progress: 0.4)
        DSProgressBar(progress: 1)
    }
    .padding()
    .frame(width: 240)
}
