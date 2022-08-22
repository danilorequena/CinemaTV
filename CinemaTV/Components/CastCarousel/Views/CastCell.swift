//
//  CastCell.swift
//  CinemaTV
//
//  Created by Danilo Requena on 26/11/21.
//

import SwiftUI
import Kingfisher

struct CastCell: View {
    let image: URL?
    let name: String?
    var body: some View {
        VStack(spacing: 2) {
            KFImage.url(image)
                .placeholder {
                    Circle().fill(Color.gray)
                        .frame(width: 60, height: 60)
                }
                .resizable()
                .setProcessor(ResizingImageProcessor(referenceSize: CGSize(width: 60 * UIScreen.main.scale, height: 60 * UIScreen.main.scale), mode: .aspectFit))
                .onFailure({ _ in
                    Image("placeholder-image")
                        .frame(width: 60, height: 60)
                        .scaledToFill()
                        .clipShape(Circle())
                })
                .scaledToFill()
                .clipShape(Circle())
                .frame(width: 60, height: 60)
            
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
