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
        NavigationStack {
            if colorScheme == .dark {
                Group {
                    MoviesView()
                }
                .background(Gradient(colors: [.gray, .black]))
                .navigationTitle(LC.discover.text)
                .toolbar {
                    ToolbarItemGroup(placement: .navigationBarTrailing) {
                        NavigationLink(
                            destination: WantWatchView(),
                            label: {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.yellow)
                            }
                        )
                        
                        NavigationLink(
                            destination: WantWatchView(),
                            label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.white)
                            }
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
                            destination: WantWatchView(),
                            label: {
                                Image(systemName: "bookmark.fill")
                                    .foregroundColor(.secondary)
                            }
                        )
                        
                        NavigationLink(
                            destination: WantWatchView(),
                            label: {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.black)
                            }
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
