//
//  DetailSeasonView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 27/05/23.
//

import SwiftUI

struct DetailSeasonView: View {
    @StateObject var viewModel: SeasonViewModel
    @State private var isOn = false
    var body: some View {
        VStack {
            if let data = viewModel.data {
                List {
                    Section {
                        HStack {
                            AsyncImage(url: URL(string: Constants.basePosters + (data.posterPath))) { image in
                                image
                                    .resizable()
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(16)
                            } placeholder: {
                                Image("placeholder-image")
                                    .resizable()
                                    .frame(width: 120, height: 180)
                                    .cornerRadius(16)
                            }
                            
                            VStack{
                                Text(data.name)
                                Text(data.overview)
                                    .lineLimit(8)
                            }
                        }
                        .padding(.horizontal, 10)
                    }
                    
                    Section("episodes") {
                        ForEach(data.episodes) { episode in
                            DisclosureGroup(episode.name ?? "") {
                                Text(episode.overview ?? "")
                            }
                        }
                    }
                }
            }
        }
        .task {
            await viewModel.loadSeasonDetail()
        }
    }
}

struct DetailSeasonView_Previews: PreviewProvider {
    static var previews: some View {
        DetailSeasonView(
            viewModel: SeasonViewModel(
                tvShowID: 60735,
                tvshowSeasonNumber: 1
            )
        )
    }
}
