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
            AsyncImage(url: image) { image in
                image.resizable()
            } placeholder: {
                Image("placeholder-image")
                    .resizable()
                    .clipShape(Circle())
                    .scaledToFill()
            }
            .scaledToFill()
            .clipShape(Circle())
            .frame(width: 80, height: 80)
            
            Text(name ?? "")
                .multilineTextAlignment(.leading)
                .font(.caption)
        }
    }
}

struct CastCell_Previews: PreviewProvider {
    static var previews: some View {
        CastCell(image: URL(string: "\(Constants.basePosters)/iAr3NRkU9KuPX7jI9ePPeq7zVsc.jpg"), name: "Name").previewLayout(.fixed(width: 100, height: 100))
            .previewLayout(.fixed(width: 340, height: 120))
    }
}
