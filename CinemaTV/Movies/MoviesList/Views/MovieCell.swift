//
//  MovieCell.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct MovieCell: View {
    let image: URL?
    let id: Int
    let animation: Namespace.ID
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: image) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .matchedTransitionSource(id: id, in: animation)
                } else if phase.error != nil {
                    Image("placeholder-image")
                } else {
                    ProgressView()
                }
            }
            .scaledToFill()
            .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .cornerRadius(16)
        }
    }
}

#Preview {
    @Previewable @Namespace var animation
    MovieCell(
        image: URL(string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg"),
        id: 0,
        animation: animation
    )
    .previewLayout(.fixed(width: 246, height: 460))
}

struct ProgressViewCustom: ProgressViewStyle {
    func makeBody(configuration: Configuration) -> some View {
        ProgressView(configuration)
        
    }
}
