//
//  IncompleteBadge.swift
//  CinemaTV
//
//  Created by Danilo Requena on 25/01/26.
//

import SwiftUI

struct IncompleteBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "play.circle.fill")
            Text(LC.incomplete.text)
        }
        .font(.caption.bold())
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
    }
}

#Preview {
    ZStack {
        Color.black
        IncompleteBadge()
    }
}
