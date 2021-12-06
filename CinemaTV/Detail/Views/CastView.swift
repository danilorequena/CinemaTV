//
//  CastView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 26/11/21.
//

import SwiftUI

struct CastView: View {
    @ObservedObject var viewModel = DetailViewModel()
    let castID: Int?
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Casting")
                .font(.headline)
                .foregroundColor(.gray)
                .padding(.init(top: 0, leading: 16, bottom: 0, trailing: 0))
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(viewModel.cast?.cast ?? []) { character in
                        if let char = character.profilePath {
                            CastCell(
                                image: URL(string: Constants.basePosters + char),
                                name: character.name
                            )
                                .frame(width: 60, height: 76)
                                .padding(.bottom, 20)
                                .padding(.leading, 10)
                        }
                    }
                }
                .task {
                    await viewModel.fetchCast(movieID: castID ?? 0)
                }
            }
        }
    }
}

struct CastView_Previews: PreviewProvider {
    static var previews: some View {
        CastView(castID: 19404).previewLayout(.fixed(width: 340, height: 100))
    }
}
