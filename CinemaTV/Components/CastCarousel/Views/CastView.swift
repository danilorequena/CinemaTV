//
//  CastView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 26/11/21.
//

import SwiftUI

struct CastView: View {
    let state: MovieORTVShow
    var castData: [CastList]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Casting")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(castData) { character in
                        NavigationLink {
                            PersonView(id: character.id ?? 0)
                        } label: {
                            CastCell(
                                image: URL(string: Constants.basePosters + (character.profilePath ?? "")),
                                name: character.name
                            )
                            .fixedSize(horizontal: true, vertical: false)
                        }
                    }
                }
                .padding(.leading, 10)
            }
        }
    }
}

struct CastView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CastView(
                state: .movie,
                castData: CastModel.stubArray()
            )
                .previewLayout(.fixed(width: 340, height: 120))
            CastView(
                state: .tvShow,
                castData: CastModel.stubArray()
            )
            .previewLayout(.fixed(width: 340, height: 120))
        }
    }
}
