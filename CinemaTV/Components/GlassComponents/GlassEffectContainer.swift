//
//  GlassEffectContainer.swift
//  CinemaTV
//
//  Created by Danilo Requena on 02/02/26.
//

import SwiftUI

struct GlassEffectContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    init(spacing: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        content
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        GlassEffectContainer(spacing: 20) {
            VStack(spacing: 20) {
                Text("Container Content")
                    .padding()
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
