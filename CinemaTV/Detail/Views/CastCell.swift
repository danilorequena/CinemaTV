//
//  CastCell.swift
//  CinemaTV
//
//  Created by Danilo Requena on 26/11/21.
//

import SwiftUI

struct CastCell: View {
    let image: URL?
    let name: String?
    var body: some View {
        VStack(spacing: 2) {
            if let image = image, let imageData = try? Data(contentsOf: image), let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .clipShape(Circle())
                    .frame(width: 60, height: 60)
            } else {
                Image("placeholder-image")
            }
            Text(name ?? "")
                .multilineTextAlignment(.leading)
                .font(.caption)
        }
    }
}

struct CastCell_Previews: PreviewProvider {
    static var previews: some View {
        CastCell(image: URL(string: "\(Constants.basePosters)/iAr3NRkU9KuPX7jI9ePPeq7zVsc.jpg"), name: "Name").previewLayout(.fixed(width: 100, height: 100))
    }
}
