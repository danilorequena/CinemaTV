//
//  CollapsedSearchView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct CollapsedSearchView: View {
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.medium))
                    .foregroundStyle(.secondary)

                Text("Search movies & TV shows")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background {
                Capsule()
                    .glassEffect(.regular.interactive())
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        VStack {
            Spacer()
            CollapsedSearchView {
                print("Tapped")
            }
            .padding(.bottom, 20)
        }
    }
}
