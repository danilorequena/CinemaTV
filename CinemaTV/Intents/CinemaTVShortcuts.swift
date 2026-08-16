//
//  CinemaTVShortcuts.swift
//  CinemaTV
//
//  Frases de Siri/Shortcuts. Localizáveis via String Catalog (EN/pt-BR).
//

import AppIntents

struct CinemaTVShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenWatchlistIntent(),
            phrases: [
                "Open my \(.applicationName) watchlist",
                "Show my \(.applicationName) watchlist"
            ],
            shortTitle: "Open Watchlist",
            systemImageName: "bookmark"
        )
        AppShortcut(
            intent: AddMovieToWatchlistIntent(),
            phrases: [
                "Add a movie to my \(.applicationName) watchlist"
            ],
            shortTitle: "Add to Watchlist",
            systemImageName: "plus.circle"
        )
        AppShortcut(
            intent: SearchMoviesIntent(),
            phrases: [
                "Search movies in \(.applicationName)",
                "Find a movie in \(.applicationName)"
            ],
            shortTitle: "Search Movies",
            systemImageName: "magnifyingglass"
        )
        AppShortcut(
            intent: MarkMovieWatchedIntent(),
            phrases: [
                "Mark a movie as watched in \(.applicationName)"
            ],
            shortTitle: "Mark Watched",
            systemImageName: "checkmark.circle"
        )
    }
}
