//
//  TMDBRegion.swift
//  CinemaTVKit
//
//  Fonte única da região usada nas chamadas do TMDB (release dates,
//  now playing, upcoming e watch providers). Default: a região do aparelho
//  (Ajustes > Geral > Idioma e Região); o usuário pode sobrescrever no
//  Settings do app. Persistida no App Group para que widget e App Intents
//  resolvam a mesma região que o app.
//

import Foundation

public enum TMDBRegion {
    public static let appGroupID = "group.com.danilorequena.CinemaTV"
    /// Chave lida via @AppStorage no SettingsScreen; string vazia = automático.
    public static let overrideKey = "tmdbRegionOverride"

    public static var store: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    /// Região efetiva: override do usuário, senão a região do aparelho.
    public static var current: String {
        current(in: store)
    }

    static func current(in defaults: UserDefaults) -> String {
        if let override = defaults.string(forKey: overrideKey), !override.isEmpty {
            return override
        }
        return deviceDefault
    }

    /// Região do aparelho — não `Locale.current.language.region`, que devolve
    /// a região do idioma ("US" para quem usa o iPhone em inglês no Brasil).
    public static var deviceDefault: String {
        Locale.current.region?.identifier ?? "US"
    }

    /// Códigos ISO de países selecionáveis, ordenados pelo nome localizado.
    public static var selectableRegions: [String] {
        Locale.Region.isoRegions
            .map(\.identifier)
            .filter { $0.count == 2 }
            .map { (code: $0, name: localizedName(for: $0)) }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
            .map(\.code)
    }

    public static func localizedName(for code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }
}
