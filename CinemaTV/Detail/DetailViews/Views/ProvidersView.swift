//
//  ProvidersView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 10/01/23.
//

import SwiftUI

struct ProvidersView: View {
    let data: [WatchProvider]
    let title: String
    let link: String
    var body: some View {
        VStack {
            if !data.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                    
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(data) { provider in
                                Link(destination: URL(string: link)!) {
                                    CastCell(
                                        image: URL(string: Constants.basePosters + (provider.logoPath ?? "")),
                                        name: provider.providerName
                                    )
                                    .fixedSize(horizontal: true, vertical: false)
                                }
                            }
                        }
                        .padding(.leading, 10)
                    }
                }
            } else {
                Text("No data")
                    .padding()
            }
        }
    }
}
