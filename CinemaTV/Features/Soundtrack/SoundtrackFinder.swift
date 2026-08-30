//
//  SoundtrackFinder.swift
//  CinemaTV
//
//  Heurísticas puras para achar a trilha sonora certa entre os candidatos
//  do catálogo (molde do VisualTextExtractor: sem MusicKit/FoundationModels,
//  tudo testável). O LLM só entra quando o pick heurístico não é confiante.
//

import Foundation
import CinemaTVCore

enum SoundtrackFinder {
    enum MediaKind: String, Sendable {
        case movie
        case tv
    }

    struct Scored: Sendable, Equatable {
        let candidate: SoundtrackCandidate
        let score: Double
    }

    /// Termos de busca em ordem de precisão; o chamador tenta até um
    /// devolver candidatos.
    static func searchTerms(title: String, originalTitle: String?, kind: MediaKind) -> [String] {
        var terms: [String] = []
        switch kind {
        case .movie:
            terms.append("\(title) Original Motion Picture Soundtrack")
            terms.append("\(title) soundtrack")
        case .tv:
            terms.append("\(title) soundtrack")
            terms.append("\(title) Original Series Soundtrack")
        }
        if let originalTitle,
           originalTitle.caseInsensitiveCompare(title) != .orderedSame {
            terms.append("\(originalTitle) soundtrack")
        }
        return terms
    }

    /// Compositores no crew do TMDB (jobs variam entre filme e TV).
    static func composers(in crew: [CrewMember]) -> [String] {
        var seen = Set<String>()
        return crew.compactMap { member in
            guard let job = member.job else { return nil }
            let isComposer = job == "Original Music Composer"
                || job == "Music"
                || job.localizedCaseInsensitiveContains("composer")
            guard isComposer, seen.insert(member.name).inserted else { return nil }
            return member.name
        }
    }

    /// Ranqueia candidatos por sinais baratos; roda antes do LLM.
    static func rank(
        _ candidates: [SoundtrackCandidate],
        title: String,
        releaseYear: Int?,
        composers: [String]
    ) -> [Scored] {
        let normalizedTitle = normalize(title)
        let normalizedComposers = composers.map(normalize)

        return candidates.map { candidate in
            var score = 0.0
            let albumTitle = normalize(candidate.title)
            let artist = normalize(candidate.artistName)

            if albumTitle.contains(normalizedTitle) { score += 2 }

            if albumTitle.contains("original motion picture soundtrack")
                || albumTitle.contains("original soundtrack")
                || albumTitle.contains("original score")
                || albumTitle.contains("original series soundtrack")
                || albumTitle.contains("music from") {
                score += 1.5
            } else if albumTitle.contains("soundtrack") || albumTitle.contains("banda sonora")
                || albumTitle.contains("trilha sonora") {
                score += 1
            }

            if normalizedComposers.contains(where: { artist.contains($0) || $0.contains(artist) }) {
                score += 2.5
            }

            if let releaseYear, let candidateYear = candidate.releaseYear {
                let distance = abs(candidateYear - releaseYear)
                if distance <= 1 {
                    score += 1
                } else if distance <= 2 {
                    score += 0.5
                } else if distance > 10 {
                    score -= 0.5
                }
            }

            let junkMarkers = [
                "karaoke", "tribute", "inspired by", "8-bit", "8 bit",
                "lullaby", "made famous", "cover version", "covers",
                "in the style of", "ringtone",
            ]
            if junkMarkers.contains(where: albumTitle.contains) {
                score -= 3
            }

            return Scored(candidate: candidate, score: score)
        }
        .sorted { $0.score > $1.score }
    }

    /// Reduz aos melhores candidatos para o prompt do LLM.
    static func shortlist(_ scored: [Scored], limit: Int = 5) -> [SoundtrackCandidate] {
        scored.lazy
            .filter { $0.score > 0 }
            .prefix(limit)
            .map(\.candidate)
    }

    /// Pick sem LLM: topo com nota alta e folga sobre o segundo. É o fast
    /// path (pula o modelo) e o fallback quando a IA está indisponível.
    static func confidentPick(_ scored: [Scored]) -> SoundtrackCandidate? {
        guard let top = scored.first, top.score >= 3.5 else { return nil }
        if scored.count == 1 { return top.candidate }
        let runnerUp = scored[1]
        return top.score - runnerUp.score >= 1 ? top.candidate : nil
    }

    /// Minúsculas + sem diacríticos, para comparações lenientes.
    static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
