//
//  InformationDetailView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 02/11/23.
//

import SwiftUI

struct InformationDetailView: View {
    let name: String
    let firstAirDate: String
    let overview: String
    let voteAverage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.title)
                    .bold()
                
                Text("Release Date: \(firstAirDate).")
                    .font(.subheadline)
                    .foregroundColor(Color.blue)
                
                Text("Average: \(voteAverage)/10")
                    .font(.subheadline)
                    .foregroundColor(Color.blue)
            }
            
            Text(overview)
                .font(.headline)
            
        }
        .padding()
    }
}
