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

struct CastListView_Previews: PreviewProvider {
    static var previews: some View {
        CastListView(castList: CastModel.stubArray())
    }
}
