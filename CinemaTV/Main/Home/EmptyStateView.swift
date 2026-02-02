//
//  EmptyStateView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct EmptyStateView: View {
    let expandSheet: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "film.stack")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            VStack(spacing: 8) {
                Text("No Content Yet")
                    .font(.title2.bold())

                Text("Start tracking movies and TV shows to see them here.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            discoverButton
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var discoverButton: some View {
        Button(action: expandSheet) {
            Label("Discover Content", systemImage: "magnifyingglass")
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
        }
        .buttonStyle(.glassProminent)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.gray, .black], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

        EmptyStateView {
            print("Expand sheet")
        }
    }
}
