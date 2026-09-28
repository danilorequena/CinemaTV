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
    case lifetime
    case discover
    case search
}

enum ExternalMediaRoute: Hashable, Identifiable {
    case movie(id: Int)
    case tvShow(id: Int)

    var id: Self { self }
}

struct AppPresentation: Identifiable {
    enum Content {
        case libraryImport(LibraryImportRequest)
        case externalMedia(ExternalMediaRoute)
    }

    let id = UUID()
    let content: Content
}

@MainActor
@Observable
final class AppRouter {
    /// Tracking é o core do app — abre primeiro.
    var selectedTab: AppTab = .tracking
    var discoverPath = NavigationPath()
    var trackingPath = NavigationPath()
    var lifetimePath = NavigationPath()
    var searchPath = NavigationPath()
    /// Query da busca — bindada ao .searchable e alimentada por deep links.
    var searchQuery = ""
    /// One presentation at a time for Library import and externally opened media.
    var presentation: AppPresentation?
    var externalMediaPath = NavigationPath()

    func presentLibraryImport(text: String = "", destination: LibraryImportDestination = .watched) {
        selectedTab = .tracking
        externalMediaPath = NavigationPath()
        presentation = AppPresentation(
            content: .libraryImport(LibraryImportRequest(text: text, destination: destination))
        )
    }

    /// Empilha uma rota na tab ativa (navegação programática de telas que
    /// não usam NavigationLink, ex.: rail de temporadas do design system).
    func push(_ route: Route) {
        if case .externalMedia = presentation?.content {
            externalMediaPath.append(route)
            return
        }
        switch selectedTab {
        case .tracking: trackingPath.append(route)
        case .lifetime: lifetimePath.append(route)
        case .discover: discoverPath.append(route)
        case .search: searchPath.append(route)
        }
    }

    func open(_ deepLink: DeepLink) {
        presentation = nil
        externalMediaPath = NavigationPath()
        switch deepLink {
        case .boxes:
            showInLibrary(.boxes)
        case .box(let editionID):
            showInLibrary(.sharedBox(editionID: editionID))
        case .movie(let id):
            presentation = AppPresentation(content: .externalMedia(.movie(id: id)))
        case .tvShow(let id):
            presentation = AppPresentation(content: .externalMedia(.tvShow(id: id)))
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

    private func showInLibrary(_ route: Route) {
        guard selectedTab != .tracking else {
            trackingPath.append(route)
            return
        }
        selectedTab = .tracking
        Task { trackingPath.append(route) }
    }
}
