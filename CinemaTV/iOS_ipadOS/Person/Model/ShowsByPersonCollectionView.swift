//
//  ShowsByPersonCollectionView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 15/10/22.
//

import SwiftUI

struct ShowsByPersonCollectionView: View {
    let data: [Cast]
    let title: String
    var body: some View {
        if data.isEmpty {
            CinemaTVProgressView()
        } else {
            VStack(alignment: .center) {
                HStack {
                    Text(title)
                        .font(.system(.headline, design: .rounded))
                        .lineLimit(1)
                        .frame(width: UIScreen.main.bounds.width, alignment: .leading)
                        .padding(.leading, 16)
                }
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(data) { movie in
                            NavigationLink(destination: DetailView(id: movie.id, state: .movie)) {
                                VStack(spacing: 2) {
                                    AsyncImage(url: URL(string: Constants.basePosters + (movie.posterPath ?? ""))) { image in
                                        image
                                            .resizable()
                                            .cornerRadius(16)
                                            .scaledToFit()
                                            .frame(width: 200, height: 240)
                                    } placeholder: {
                                        ProgressView()
                                    }

                                    Text((movie.title) ?? "")
                                        .font(.caption)
                                        .lineLimit(1)
                                        .frame(width: 180)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.init(
                        top: 0,
                        leading: 8,
                        bottom: 0,
                        trailing: 0
                    ))
                }
            }
        }
    }
}

struct ShowsByPersonCollectionView_Previews: PreviewProvider {
    static var previews: some View {
        ShowsByPersonCollectionView(
            data: CreditsByPerson.castMock(),
            title: "Title"
        )
    }
}

