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
                                #warning("Verificar isso pra inserir uma WebView, e não tirar o usuário do App")
                                Link(destination: URL(string: link)!) {
                                    CastCell(
                                        image: URL(string: Constants.basePosters + (provider.logoPath ?? "")),
                                        name: provider.providerName
                                    )
                                    .frame(width: 100, height: 100, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                }
                            }
                        }
                        .padding(.leading, 10)
                    }
                }
            } else {
                #warning("Retirar isso, e desaparecer com essa view, caso venha vazio")
                Text("No data")
                    .padding()
            }
        }
    }
}

struct ProvidersView_Previews: PreviewProvider {
    static var previews: some View {
        ProvidersView(
            data: [
                WatchProvider(
                    logoPath: "/peURlLlr8jggOwK53fJ5wdQl05y.jpg",
                    id: 123,
                    providerName: "bla bla bla bla bla bla ",
                    displayPriority: 1
                ),
                WatchProvider(
                    logoPath: "/peURlLlr8jggOwK53fJ5wdQl05y.jpg",
                    id: 123,
                    providerName: "bla bla",
                    displayPriority: 2
                ),
                WatchProvider(
                    logoPath: "/peURlLlr8jggOwK53fJ5wdQl05y.jpg",
                    id: 123,
                    providerName: "bla bla",
                    displayPriority: 3
                )
            ],
            title: "title",
            link: "www.apple.com"
        )
    }
}

