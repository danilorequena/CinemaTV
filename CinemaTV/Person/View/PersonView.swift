//
//  PersonView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 08/10/22.
//

import SwiftUI

struct PersonView: View {
    var id: Int
    @ObservedObject var viewModel = PersonViewModel()
    var body: some View {
        ScrollView {
            ZStack {
                VStack {
                    VStack {
                        AsyncImage(url: URL(string: Constants.basePosters + (viewModel.person?.profilePath ?? ""))) { image in
                            image
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                        } placeholder: {
                            Image("placeholder-image")
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                        }
                    }
                    .padding(.horizontal, 32)
                    VStack(spacing: 16) {
                        Text(viewModel.person?.name ?? "")
                            .font(.title)
                            .bold()
                        
                        VStack(spacing: 16) {
                            Text("Nasceu em \(viewModel.person?.placeOfBirth ?? "") em \(viewModel.person?.birthday?.formatString() ?? "").")
                            if let deathday = viewModel.person?.deathday {
                                Text("Morreu em \(deathday.formatString()).")
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Biografy")
                                    .font(.title3)
                                    .bold()
                                    .padding(.top)
                                    .padding(.leading)
                                
                                if let biografy = viewModel.person?.biography,
                                   !biografy.text.isEmpty {
                                    Text(biografy)
                                        .padding(.horizontal)
                                        .padding(.bottom)
                                } else {
                                    Text("Sem biografia")
                                        .padding(.horizontal)
                                        .padding(.bottom)
                                }
                            }
                            .background(.ultraThinMaterial)
                            .cornerRadius(16)
                        }
                        ShowsByPersonCollectionView(data: viewModel.creditByPerson?.cast ?? [], title: "Shows by \(viewModel.person?.name ?? "")")
                    }
                    .frame(width: UIScreen.main.bounds.width - 16)
                }
            }
        }
        .task {
            await viewModel.loadPerson(id: id )
            await viewModel.loadCreditByPerson(id: id)
        }
    }
}

struct PersonView_Previews: PreviewProvider {
    static var previews: some View {
        PersonView(id: 287)
    }
}
