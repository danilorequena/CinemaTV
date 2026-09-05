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

/// Uma única geração resolve a desambiguação (score E canções) mais o
/// parágrafo "sobre a trilha" — uma fração da latência e da quota de três
/// chamadas separadas.
@Generable
struct SoundtrackVerdict {
    @Guide(description: "The id of the candidate album that is the official score / instrumental soundtrack, or null when none of the candidates fits")
    var scoreAlbumID: String?

    @Guide(description: "The id of the candidate album that compiles the vocal songs featured in the title; the SAME id as scoreAlbumID when one album covers both; null when no candidate fits")
    var songsAlbumID: String?

    @Guide(description: "Confidence between 0 and 1 that the chosen albums are the official soundtrack")
    var confidence: Double

    @Guide(description: "Two or three sentences about this soundtrack for a movie app; mention the composer when known; no plot spoilers")
    var about: String?
}

/// Fallback quando o título não tem álbum de canções no catálogo (caso
/// Awesome Mix): roda APENAS no Private Cloud Compute — o modelo on-device
/// não conhece trilhas de filmes e alucina (Beyoncé em Homem-Aranha); e a
/// busca de canções do catálogo casa por palavras do título, sem ligação
/// real com o filme (Sting em Brand New Day). Cada canção listada ainda é
/// verificada no catálogo (título E artista) antes de aparecer.
@Generable
struct NotableSongsVerdict {
    @Guide(description: "Up to 8 famous VOCAL songs genuinely featured in the title (needle drops, theme songs, end-credits songs); empty when you are not certain of any")
    var songs: [NotableSong]
}

@Generable
struct NotableSong {
    @Guide(description: "The song title, without parenthetical extras")
    var title: String

    @Guide(description: "The original recording artist, never covers")
    var artist: String
}

enum SoundtrackPrompt {
    /// Instruções fixas da sessão (o prompt varia por título).
    static func instructions(locale: Locale = .current) -> String {
        var lines = [
            "You match movies and TV shows to their official soundtrack albums, choosing ONLY from a numbered list of candidate albums from the Apple Music catalog.",
            "Identify TWO albums: the score album (instrumental, usually by the title's composer, e.g. \"Original Score\") and the songs album (the compilation of vocal songs featured in the title, often by Various Artists, e.g. \"Awesome Mix\", \"Music from and Inspired by\").",
            "Some titles have a single official album mixing score and vocal songs — only then return the SAME id for scoreAlbumID and songsAlbumID. A pure composer score album is NEVER the songs album; if no vocal compilation is listed, return a null songsAlbumID.",
            "Reject karaoke, tribute, covers, lullaby, 8-bit albums: if only those are present, return null ids.",
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
        lines.append("Pick the official score album and the vocal songs album for this \(kind == .movie ? "movie" : "show") (same id when one album covers both) and write the about text.")
        return lines.joined(separator: "\n")
    }

    // MARK: - Canções avulsas (fallback)

    static func notableSongsInstructions() -> String {
        [
            "You list the famous VOCAL songs genuinely featured in a movie or TV show (needle drops, theme songs, end-credits songs).",
            "Only include songs you are certain about — a wrong song is much worse than a missing one; an empty list is a valid answer.",
            "Never include instrumental score tracks, covers, or tributes; use the original recording artist.",
            "A song merely sharing words with the title does not count; it must actually play in it.",
        ].joined(separator: "\n")
    }

    static func notableSongsPrompt(
        title: String,
        releaseYear: Int?,
        kind: SoundtrackFinder.MediaKind
    ) -> String {
        let kindLabel = kind == .movie ? "MOVIE" : "TV SHOW"
        let year = releaseYear.map { " (\($0))" } ?? ""
        return "\(kindLabel): \(title)\(year)\nList the famous vocal songs genuinely featured in this \(kind == .movie ? "movie" : "show")."
    }
}
