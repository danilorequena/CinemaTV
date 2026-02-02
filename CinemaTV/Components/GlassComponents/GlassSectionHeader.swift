//
//  GlassSectionHeader.swift
//  CinemaTV
//
//  Created by Danilo Requena on 05/01/26.
//

import SwiftUI

struct GlassSectionHeader: View {
    let title: String
    var showSeeAll: Bool = true
    var seeAllAction: (() -> Void)?

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            if showSeeAll, let action = seeAllAction {
                Button(action: action) {
                    Text(LC.seeAll.text)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }
}

#Preview {
    VStack {
        GlassSectionHeader(title: "Popular", showSeeAll: true) {
            print("See all tapped")
        }

        GlassSectionHeader(title: "No Action", showSeeAll: false)
    }
}
