//
//  WatchProvidersView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 11/12/22.
//

import SwiftUI

struct WatchProvidersView: View {
    let title: String
    let state: MovieORTVShow
    var providersData: [WatchProvider] 
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.init(top: 0, leading: 16, bottom: 0, trailing: 0))
            
            ScrollView(.horizontal) {
                HStack(spacing: 10) {
                    ForEach(providersData) { provider in
                        NavigationLink {
//                            PersonView(id: provider.id ?? 0)
                        } label: {
                            CastCell(
                                image: URL(string: Constants.basePosters + (provider.logoPath ?? "")),
                                name: provider.providerName
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
}

struct WatchProvidersView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CastView(
                state: .movie,
                castData: CastModel.stubArray()
            )
                .previewLayout(.fixed(width: 340, height: 100))
            CastView(
                state: .tvShow,
                castData: CastModel.stubArray()
            )
        }
    }
}

