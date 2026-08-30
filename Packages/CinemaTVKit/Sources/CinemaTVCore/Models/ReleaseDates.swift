//
//  ReleaseDates.swift
//  CinemaTVKit
//
//  Regra única de "já foi ao ar": episódios e filmes só podem ser marcados
//  como assistidos depois da estreia. Datas do TMDB são "yyyy-MM-dd"; sem
//  data (ou data ilegível) o conteúdo conta como lançado para não travar
//  catálogo antigo com metadados incompletos.
//

import Foundation

public enum ReleaseDates {
    /// True quando a data ISO (yyyy-MM-dd) já passou, contando o próprio dia
    /// como lançado. Aceita fallback de ano solto ("2027", como o
    /// releaseYear do MovieEntity); nil/vazio/ilegível contam como lançado.
    public static func hasPassed(_ isoDate: String?, asOf now: Date = .now) -> Bool {
        guard let isoDate, !isoDate.isEmpty else { return true }
        if let date = try? Date(isoDate, strategy: .iso8601.year().month().day()) {
            // O parse cai em meia-noite UTC do dia da estreia.
            return date <= now
        }
        if let year = Int(isoDate.prefix(4)) {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .gmt
            return year <= calendar.component(.year, from: now)
        }
        return true
    }
}

public extension MediaItem {
    /// Filmes só entram em "assistido" depois da estreia.
    var isReleased: Bool {
        ReleaseDates.hasPassed(releaseDate)
    }
}

public extension EpisodeSummary {
    /// Episódios só podem ser marcados depois de irem ao ar.
    var hasAired: Bool {
        ReleaseDates.hasPassed(airDate)
    }
}
