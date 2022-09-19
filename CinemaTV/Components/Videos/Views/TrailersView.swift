//
//  TrailersView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/12/21.
//

import SwiftUI
import AVKit
import WebKit

struct TrailersView: View {
    let viewModel = DetailViewModel()
    let videoID: Int?
    let videoKey: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Trailer")
                .font(.title2)
                .foregroundColor(.primary)
                VideosView(videoID: String(videoKey))
                    .cornerRadius(16)
        }
        .background(Color.clear)
        .task {
             await viewModel.fetchTrailers(movieID: videoID ?? 0)
        }
    }
}

struct TrailersView_Previews: PreviewProvider {
    static var previews: some View {
        TrailersView(videoID: 580489, videoKey: "NMzJbD53ODc").previewLayout(.fixed(width: 420, height: 260))
    }
}
