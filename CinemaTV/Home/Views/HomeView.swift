//
//  HomeView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI

struct HomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = HomeViewModel()
    
    var body: some View {
        NavigationStack {
            Group {
                MoviesView()
                    .environmentObject(viewModel)
            }
            .background(Gradient(colors: colorScheme == .dark ? [.gray, .black] : [.gray, .white]))
            .navigationTitle(LC.discover.text)
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: WantWatchView(),
                        label: {
                            Image(systemName: "star.fill")
                                .foregroundColor(colorScheme == .light ? .white : .secondary)
                        }
                    )
                }
                
                ToolbarItemGroup(placement: .navigationBarLeading) {
                    NavigationLink(
                        destination: CreditsView(),
                        label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(colorScheme == .light ? .white : .secondary)
                        }
                    )
                }
            }
        }
    }
}

#Preview {
        HomeView()
            .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self])
            .preferredColorScheme(.light)
}

#Preview {
        HomeView()
            .modelContainer(for: [MoviesWatched.self, MoviesToWatch.self])
            .preferredColorScheme(.dark)
}
