//
//  IntentSupport.swift
//  CinemaTV
//
//  Utilidades compartilhadas pelos App Intents e entity queries.
//

import Foundation
import CinemaTVCore

enum IntentSupport {
    /// Cliente TMDB para intents/queries. O fallback de chave vazia mantém o
    /// intent utilizável (retorna vazio) mesmo se o TMDB.plist faltar no bundle.
    static func makeTMDBClient() -> TMDBClient {
        TMDBClient(configuration: (try? .fromBundle(.main)) ?? TMDBConfiguration(apiKey: ""))
    }
}
