//
//  SeasonScrubber.swift
//  CinemaTVDesignSystem
//
//  Slider de acompanhamento da temporada: capsule glass com fill accent que
//  anima a cada episódio marcado/desmarcado. Long-press engaja o scrub —
//  arrastar vai marcando (ou desmarcando) episódios em sequência via onScrub.
//

import SwiftUI

public struct SeasonScrubber: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let watched: Int
    private let total: Int
    /// Chamado a cada passo do drag (e nas ações de acessibilidade) com a
    /// contagem-alvo de episódios assistidos; quem chama aplica o diff.
    private let onScrub: (Int) -> Void

    @State private var isEngaged = false
    @State private var scrubTarget: Int?

    public init(watched: Int, total: Int, onScrub: @escaping (Int) -> Void) {
        self.watched = watched
        self.total = total
        self.onScrub = onScrub
    }

    private var fraction: Double {
        total > 0 ? Double(watched) / Double(total) : 0
    }

    public var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                if watched > 0 {
                    Capsule()
                        .fill(DSColor.accent.gradient)
                        // Abaixo da altura o capsule vira uma lasca disforme.
                        .frame(width: max(proxy.size.height, width * fraction))
                }
                // Ícone + contador sempre visíveis, na linguagem da pill
                // central da referência (ícone + label).
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "checkmark.circle")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                    Text(verbatim: "\(watched)/\(total)")
                        .font(.footnote.weight(.semibold))
                        .monospacedDigit()
                        .contentTransition(.numericText(value: Double(watched)))
                }
                .frame(maxWidth: .infinity)
            }
            // Sem o frame cheio, o hit area seria só o fill (zero com 0
            // assistidos) e o drag vazaria para o dismiss do zoom transition.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .animation(DSMotion.respecting(reduceMotion, DSMotion.snappy), value: watched)
            .clipShape(.capsule)
            .contentShape(.capsule)
            .gesture(scrubGesture(width: width))
        }
        .frame(height: 40)
        .glassEffect(.regular.interactive(), in: .capsule)
        .scaleEffect(y: isEngaged && !reduceMotion ? 1.25 : 1)
        .sensoryFeedback(.selection, trigger: scrubTarget) { _, new in new != nil }
        .accessibilityElement()
        .accessibilityLabel(Text("Season progress", bundle: .module))
        .accessibilityValue(Text("\(watched) of \(total) episodes", bundle: .module))
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onScrub(min(watched + 1, total))
            case .decrement: onScrub(max(watched - 1, 0))
            @unknown default: break
            }
        }
    }

    /// Long-press antes do drag: o toque casual não muda estado; segurar
    /// engaja (barra cresce) e aí o dedo vira o cursor de episódios.
    private func scrubGesture(width: CGFloat) -> some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .sequenced(before: DragGesture(minimumDistance: 0, coordinateSpace: .local))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                if !isEngaged {
                    withAnimation(DSMotion.respecting(reduceMotion, DSMotion.snappy)) {
                        isEngaged = true
                    }
                }
                guard let drag, total > 0, width > 0 else { return }
                let position = min(max(drag.location.x / width, 0), 1)
                let target = Int((position * Double(total)).rounded())
                if target != scrubTarget {
                    scrubTarget = target
                    onScrub(target)
                }
            }
            .onEnded { _ in
                withAnimation(DSMotion.respecting(reduceMotion, DSMotion.snappy)) {
                    isEngaged = false
                }
                scrubTarget = nil
            }
    }
}

#Preview("SeasonScrubber") {
    @Previewable @State var watched = 3

    VStack(spacing: DSSpacing.xl) {
        SeasonScrubber(watched: watched, total: 10) { watched = $0 }
        HStack {
            Button("−1") { watched = max(0, watched - 1) }
            Button("+1") { watched = min(10, watched + 1) }
        }
        .buttonStyle(.glass)
    }
    .padding(DSSpacing.lg)
}
