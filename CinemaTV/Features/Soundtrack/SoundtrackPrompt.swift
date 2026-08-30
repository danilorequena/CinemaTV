//
//  SoundtrackPrompt.swift
//  CinemaTV
//
//  Prompt e saída estruturada da desambiguação de trilha sonora. A
//  construção do prompt é pura e testável; o FoundationModels entra só
//  pelo macro @Generable (guided generation).
//

import Foundation
import FoundationModels

/// Uma única geração resolve a desambiguação E o parágrafo "sobre a
/// trilha" — metade da latência e da quota de duas chamadas.
@Generable
struct SoundtrackVerdict {
    @Guide(description: "The id of the candidate album that is the official soundtrack, or null when none of the candidates is the official soundtrack")
    var albumID: String?

    @Guide(description: "Confidence between 0 and 1 that the chosen album is the official soundtrack")
    var confidence: Double

    @Guide(description: "Two or three sentences about this soundtrack for a movie app; mention the composer when known; no plot spoilers")
    var about: String?
}

enum SoundtrackPrompt {
    /// Instruções fixas da sessão (o prompt varia por título).
    static func instructions(locale: Locale = .current) -> String {
        var lines = [
            "You match movies and TV shows to their official soundtrack album, choosing ONLY from a numbered list of candidate albums from the Apple Music catalog.",
            "Prefer albums by the title's composer and official releases such as \"Original Motion Picture Soundtrack\" or \"Music from...\".",
            "Reject karaoke, tribute, covers, lullaby, 8-bit, and \"inspired by\" albums: if only those are present, return a null albumID.",
            "Never invent an id that is not in the candidate list.",
        ]
        // Frase exata recomendada pela Apple para reduzir alucinação
        // multilíngue; o "about" sai no idioma da pessoa.
        if !Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
            lines.append("The person's locale is \(locale.identifier).")
            lines.append("You MUST write the about text in the person's language.")
        }
        return lines.joined(separator: "\n")
    }

    static func verdictPrompt(
        title: String,
        releaseYear: Int?,
        composers: [String],
        kind: SoundtrackFinder.MediaKind,
        candidates: [SoundtrackCandidate]
    ) -> String {
        var lines: [String] = []
        let kindLabel = kind == .movie ? "MOVIE" : "TV SHOW"
        let year = releaseYear.map { " (\($0))" } ?? ""
        lines.append("\(kindLabel): \(title)\(year)")
        if !composers.isEmpty {
            lines.append("COMPOSERS: \(composers.joined(separator: ", "))")
        }
        lines.append("CANDIDATES:")
        for (index, candidate) in candidates.enumerated() {
            let candidateYear = candidate.releaseYear.map(String.init) ?? "unknown"
            let tracks = candidate.trackCount.map(String.init) ?? "unknown"
            lines.append("\(index + 1). id: \(candidate.id) | title: \(candidate.title) | artist: \(candidate.artistName) | year: \(candidateYear) | tracks: \(tracks)")
        }
        lines.append("Pick the official soundtrack album for this \(kind == .movie ? "movie" : "show") and write the about text.")
        return lines.joined(separator: "\n")
    }
}
