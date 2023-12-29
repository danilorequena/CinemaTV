//
//  InformationDetailView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 02/11/23.
//

import SwiftUI

struct InformationDetailView: View {
    var detailInfos: DetailTVShow
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(detailInfos.name ?? "")
                    .font(.title)
                    .bold()
                
                Text("Release Date: \(detailInfos.firstAirDate?.formatString() ?? "").")
                    .font(.subheadline)
                    .foregroundColor(Color.blue)
                
                Text("Average: \(detailInfos.voteAverage?.formatted() ?? "")/10")
                    .font(.subheadline)
                    .foregroundColor(Color.blue)
            }
            
            Text(detailInfos.overview ?? "")
                .font(.headline)
            
        }
        .padding()
    }
}
