//
//  GlassCardView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

// MARK: - Glass Tint Presets
enum GlassTint {
    case none
    case movies
    case tvShows
    case watched
    case stats
    case search

    var color: Color? {
        switch self {
        case .none: return nil
        case .movies: return .blue
        case .tvShows: return .purple
        case .watched: return .green
        case .stats: return .orange
        case .search: return .indigo
        }
    }
}

struct GlassCardView<Content: View>: View {
    let content: Content
    var isInteractive: Bool
    var cornerRadius: CGFloat
    var tint: GlassTint

    init(
        isInteractive: Bool = false,
        cornerRadius: CGFloat = 20,
        tint: GlassTint = .none,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.isInteractive = isInteractive
        self.cornerRadius = cornerRadius
        self.tint = tint
    }

    var body: some View {
        content
            .modifier(GlassEffectModifier(
                cornerRadius: cornerRadius,
                tint: tint,
                isInteractive: isInteractive
            ))
    }
}

// MARK: - Glass Effect Modifier
private struct GlassEffectModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: GlassTint
    let isInteractive: Bool

    func body(content: Content) -> some View {
        if let tintColor = tint.color {
            if isInteractive {
                content.glassEffect(
                    .clear.tint(tintColor.opacity(0.5)).interactive(),
                    in: .rect(cornerRadius: cornerRadius)
                )
            } else {
                content.glassEffect(
                    .clear.tint(tintColor.opacity(0.5)),
                    in: .rect(cornerRadius: cornerRadius)
                )
            }
        } else {
            if isInteractive {
                content.glassEffect(.regular.interactive(), in: .rect(cornerRadius: cornerRadius))
            } else {
                content.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
            }
        }
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        VStack(spacing: 20) {
            GlassCardView {
                Text("Regular Glass Card")
                    .padding()
            }

            GlassCardView(isInteractive: true, tint: .movies) {
                Text("Movies Tint")
                    .padding()
            }

            GlassCardView(isInteractive: true, tint: .tvShows) {
                Text("TV Shows Tint")
                    .padding()
            }

            GlassCardView(tint: .watched) {
                Text("Watched Tint")
                    .padding()
            }

            GlassCardView(tint: .stats) {
                Text("Stats Tint")
                    .padding()
            }
        }
    }
}
