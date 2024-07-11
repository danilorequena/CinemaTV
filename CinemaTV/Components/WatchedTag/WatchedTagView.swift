//
//  WatchedTagView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/04/23.
//

import SwiftUI

struct WatchedTagView: View {
    let watched: Bool
    var body: some View {
        if watched {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                Text(LC.watchedTag.text)
            }
            .padding(8)
            .background(.thinMaterial)
            .cornerRadius(16)
            .padding(.bottom, 16)
        }
    }
}

#Preview {
    WatchedTagView(watched: true)
}
