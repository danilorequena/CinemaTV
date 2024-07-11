//
//  CastListView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 04/10/22.
//

import SwiftUI

struct CastListView: View {
    let castList: [CastList]
    var body: some View {
        List(castList) { cast in
            MoviesListCell(
                image: URL(
                    string: Constants.basePosters + (cast.profilePath ?? "")
                ),
                title: cast.name ?? "",
                subTitle: cast.character ?? ""
            )
        }
    }
}

#Preview {
    CastListView(castList: CastModel.stubArray())
}
