//
//  HomeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationView {
            if colorScheme == .dark {
                Group {
                    MoviesView()
                }
                .background(Gradient(colors: [.gray, .black]))
                .navigationTitle(LC.discover.text)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        NavigationLink(
                            destination: WantWatch(),
                            label: {Image(systemName: "info.circle")}
                        )
                    }
                }
            } else {
                Group {
                    MoviesView()
                }
                .background(Gradient(colors: [.gray, .white]))
                .navigationTitle(LC.discover.text)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        NavigationLink(
                            destination: WantWatch(),
                            label: {Image(systemName: "info.circle")}
                        )
                    }
                }
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
