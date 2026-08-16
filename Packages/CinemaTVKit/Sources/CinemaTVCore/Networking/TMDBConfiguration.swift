//
//  TMDBConfiguration.swift
//  CinemaTVKit
//

import Foundation

public struct TMDBConfiguration: Sendable {
    public let apiKey: String
    public let baseURL: URL

    public init(apiKey: String, baseURL: URL = URL(string: "https://api.themoviedb.org/3")!) {
        self.apiKey = apiKey
        self.baseURL = baseURL
    }

    /// Lê a chave de um TMDB.plist presente no bundle informado
    /// (o app e o widget mantêm o plist como resource próprio).
    public static func fromBundle(_ bundle: Bundle) throws(TMDBError) -> TMDBConfiguration {
        guard
            let url = bundle.url(forResource: "TMDB", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let key = plist["API_KEY"] as? String
        else {
            throw TMDBError.invalidEndpoint
        }
        return TMDBConfiguration(apiKey: key)
    }
}

/// URLs de imagens do TMDB, tipadas por tamanho — consumido pelo PosterImage
/// do design system e pelos widgets.
public enum TMDBImage {
    public enum Size: String, Sendable {
        case thumbnail = "w92"
        case profile = "w185"
        case poster = "w500"
        case backdrop = "w780"
        case original = "original"
    }

    public static func url(path: String?, size: Size) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        return URL(string: "https://image.tmdb.org/t/p/\(size.rawValue)\(path)")
    }
}
