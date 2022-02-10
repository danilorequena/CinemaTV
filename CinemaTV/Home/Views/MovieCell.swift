//
//  MovieCell.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI
import Kingfisher

struct MovieCell: View {
    let image: URL?
    var body: some View {
        if let image = image, let imageData = try? Data(contentsOf: image), let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .background(.ultraThinMaterial)
                .mask(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .cornerRadius(16)
//            KFImage(image)
//                .resizable()
//                .loadDiskFileSynchronously()
//                .cacheMemoryOnly()
//                .fade(duration: 0.25)
//                .scaledToFill()
        } else {
            Image("placeholder-image")
        }
    }
}

struct MovieCell_Previews: PreviewProvider {
    static var previews: some View {
        MovieCell(image: URL(string: "\(Constants.basePosters)/qAZ0pzat24kLdO3o8ejmbLxyOac.jpg"))
    }
}
