//
//  EpisodeCellView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 12/31/23.
//

import SwiftUI

struct EpisodeCellView: View {
    let imagePath: String
    let overview: String
    
    var body: some View {
        HStack {
            AsyncImage(url: URL(string: imagePath)) { image in
                image
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(16)
            } placeholder: {
                Image("placeholder-image")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .cornerRadius(16)
            }
            
            VStack{
                Text(overview)
                    .lineLimit(4)
                    .font(.headline)
            }
        }
    }
}

#Preview {
    EpisodeCellView(imagePath: Constants.basePosters + "/eeNYnyVdAGdBzVDCIspxlFHNAtb.jpg", overview: "Blas boanjnf")
}
