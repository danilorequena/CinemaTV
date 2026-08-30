//
//  RoadmapData.swift
//  CinemaTVCore
//
//  Changelog curado, autorado a cada release no mesmo PR. Textos
//  passam por String(localized:) para extração no catálogo do módulo
//  no build; ids são slugs estáveis (RoadmapDataTests valida).
//  O backlog (Coming Soon) não vive mais aqui: vem das issues do
//  GitHub na milestone "Backlog" — ver GitHubFeedbackClient.
//

import Foundation

public enum AppRoadmap {
    /// Releases da mais nova para a mais antiga.
    public static let releases: [ChangelogRelease] = [
        ChangelogRelease(
            version: "1.1",
            date: date(2026, 8, 29),
            entries: [
                ChangelogEntry(
                    id: "movie-soundtracks",
                    kind: .feature,
                    text: String(localized: "Soundtracks on movie and show details: play full tracks with Apple Music (or previews), in a card that morphs into a mini player — with a note about each score written by Apple Intelligence.", bundle: .module),
                    credit: "Danilo Requena"
                ),
                ChangelogEntry(
                    id: "siri-ai-integration",
                    kind: .feature,
                    text: String(localized: "Siri AI integration (v1): ask Siri to search, open, and manage your movies and shows — with rich snippets in the results.", bundle: .module),
                    credit: "Danilo Requena"
                ),
                ChangelogEntry(
                    id: "apple-intelligence-status",
                    kind: .feature,
                    text: String(localized: "Apple Intelligence in Settings: see on-device and Private Cloud Compute availability and your daily usage.", bundle: .module),
                    credit: "Danilo Requena"
                ),
                ChangelogEntry(
                    id: "app-icon-refresh",
                    kind: .improvement,
                    text: String(localized: "A brand-new app icon.", bundle: .module),
                    credit: "Marcus Mendes"
                )
            ]
        )
    ]

    /// Data fixa em UTC: conteúdo autoral não depende do fuso de quem
    /// builda. .distantPast sinaliza erro de autoria (coberto por teste).
    private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents(year: year, month: month, day: day)
        components.calendar = Calendar(identifier: .gregorian)
        components.timeZone = .gmt
        return components.date ?? .distantPast
    }
}
