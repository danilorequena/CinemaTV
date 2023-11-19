//
//  MovieCell.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct MovieCell: View {
    let image: URL?
    var body: some View {
        ZStack(alignment: .bottom) {
            AsyncImage(url: image) { image in
                image.resizable()
            } placeholder: {
                ProgressView()
            }
            .scaledToFill()
            .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .cornerRadius(16)
        }
    }
}

#Preview {
    MovieCell(
        image: URL(
            string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg"
        )
    )
    .previewLayout(.fixed(width: 246, height: 460))
}
