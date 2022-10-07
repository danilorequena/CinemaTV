//
//  CastView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 26/11/21.
//

import SwiftUI

struct CastView: View {
    let state: MovieORTVShow
    var data: [CastList]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Casting")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.init(top: 0, leading: 16, bottom: 0, trailing: 0))
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(data) { character in
                        CastCell(
                            image: URL(string: Constants.basePosters + (character.profilePath ?? "")),
                            name: character.name
                        )
                        .frame(width: 60, height: 76)
                        .padding(.bottom, 20)
                        .padding(.leading, 10)
                    }
                }
            }
        }
    }
}

struct CastView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CastView(state: .movie, data: CastModel.stubArray())
                .previewLayout(.fixed(width: 340, height: 100))
            CastView(state: .tvShow, data: CastModel.stubArray())
                .previewLayout(.fixed(width: 340, height: 100))
        }
    }
}
