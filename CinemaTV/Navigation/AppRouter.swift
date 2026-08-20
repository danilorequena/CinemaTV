//
//  AppRouter.swift
//  CinemaTV
//
//  Estado de navegação do shell: tab selecionada + um path por tab.
//  Deep links, intents e Spotlight entram todos por open(_:).
//

import SwiftUI
import CinemaTVCore

enum AppTab: Hashable {
    case tracking
    case discover
    case search
}

@MainActor
@Observable
final class AppRouter {
    /// Tracking é o core do app — abre primeiro.
    var selectedTab: AppTab = .tracking
    var discoverPath = NavigationPath()
    var trackingPath = NavigationPath()
    var searchPath = NavigationPath()
    /// Query da busca — bindada ao .searchable e alimentada por deep links.
    var searchQuery = ""

    /// Empilha uma rota na tab ativa (navegação programática de telas que
    /// não usam NavigationLink, ex.: rail de temporadas do design system).
    func push(_ route: Route) {
        switch selectedTab {
        case .tracking: trackingPath.append(route)
        case .discover: discoverPath.append(route)
        case .search: searchPath.append(route)
        }
    }

    func open(_ deepLink: DeepLink) {
        switch deepLink {
        case .movie(let id):
            selectedTab = .discover
            discoverPath.append(Route.movieDetail(id: id))
        case .tvShow(let id):
            selectedTab = .discover
            discoverPath.append(Route.tvShowDetail(id: id))
        case .watchlist:
            selectedTab = .tracking
            trackingPath = NavigationPath()
        case .search(let query):
            selectedTab = .search
            searchPath = NavigationPath()
            if let query {
                searchQuery = query
            }
        }
    }
}
