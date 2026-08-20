//
//  DeepLink.swift
//  CinemaTV
//
//  Funil único de roteamento externo: URLs cinematv://, App Intents,
//  Spotlight e taps de widget produzem um DeepLink, e o AppRouter resolve.
//

import Foundation

enum DeepLink: Equatable {
    case movie(id: Int)
    case tvShow(id: Int)
    case watchlist
    case search(query: String?)

    init?(url: URL) {
        guard url.scheme == "cinematv" else { return nil }

        switch url.host() {
        case "movie":
            let idComponent = url.pathComponents.dropFirst().first
            guard let idComponent, let id = Int(idComponent) else { return nil }
            self = .movie(id: id)
        case "tvshow":
            let idComponent = url.pathComponents.dropFirst().first
            guard let idComponent, let id = Int(idComponent) else { return nil }
            self = .tvShow(id: id)
        case "watchlist":
            self = .watchlist
        case "search":
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let query = components?.queryItems?.first(where: { $0.name == "q" })?.value
            self = .search(query: query)
        default:
            return nil
        }
    }

    /// URL correspondente — usada em widgetURL e Spotlight.
    var url: URL {
        switch self {
        case .movie(let id):
            return URL(string: "cinematv://movie/\(id)")!
        case .tvShow(let id):
            return URL(string: "cinematv://tvshow/\(id)")!
        case .watchlist:
            return URL(string: "cinematv://watchlist")!
        case .search(let query):
            var components = URLComponents(string: "cinematv://search")!
            if let query {
                components.queryItems = [URLQueryItem(name: "q", value: query)]
            }
            return components.url!
        }
    }
}
