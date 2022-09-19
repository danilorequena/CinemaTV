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

struct MovieCell_Previews: PreviewProvider {
    static var previews: some View {
        MovieCell(image: URL(string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg"))
    }
}
