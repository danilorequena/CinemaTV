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
        ScrollView(.horizontal) {
            HStack(spacing: 10) {
                ForEach(viewModel.cast?.cast ?? []) { character in
                    if let char = character.profilePath {
                        CastCell(
                            image: URL(string: Constants.basePosters + char),
                            name: character.name
                        )
                            .frame(width: 60, height: 76)
                    }
                }
            }
            .task {
                await viewModel.fetchCast(movieID: castID ?? 0)
            }
        }
    }
}

struct CastView_Previews: PreviewProvider {
    static var previews: some View {
        CastView(castID: 19404).previewLayout(.fixed(width: 340, height: 100))
    }
}
