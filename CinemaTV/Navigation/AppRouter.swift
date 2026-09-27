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
    /// Single presentation handoff for Library and Visual Intelligence imports.
    var libraryImport: LibraryImportRequest?

    func presentLibraryImport(text: String = "", destination: LibraryImportDestination = .watched) {
        selectedTab = .tracking
        libraryImport = LibraryImportRequest(text: text, destination: destination)
    }

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
        case .boxes:
            showInLibrary(.boxes)
        case .box(let editionID):
            showInLibrary(.sharedBox(editionID: editionID))
        case .movie(let id):
            showInDiscover(.movieDetail(id: id))
        case .tvShow(let id):
            showInDiscover(.tvShowDetail(id: id))
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

    /// Troca para a Discover e empilha a rota. Quando há troca de tab, o
    /// append fica para o turno seguinte do main actor: trocar a tab e
    /// empilhar na mesma transação faz a NavigationStack nascer já com o
    /// detalhe (que esconde a tab bar) — o pop congela o main thread e a
    /// tab bar não volta na raiz.
    private func showInLibrary(_ route: Route) {
        guard selectedTab != .tracking else {
            trackingPath.append(route)
            return
        }
        selectedTab = .tracking
        Task { trackingPath.append(route) }
    }

    private func showInDiscover(_ route: Route) {
        guard selectedTab != .discover else {
            discoverPath.append(route)
            return
        }
        selectedTab = .discover
        Task {
            discoverPath.append(route)
        }
    }
}
