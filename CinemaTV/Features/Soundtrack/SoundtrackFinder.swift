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

    /// Reduz aos melhores candidatos para o prompt do LLM. Limite 6: com o
    /// pool unindo todos os termos de busca, sobra folga para a compilação
    /// de canções entrar mesmo atrás de dois ou três álbuns de score.
    static func shortlist(_ scored: [Scored], limit: Int = 6) -> [SoundtrackCandidate] {
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

    /// Sinais de que o álbum é uma compilação de canções (vocais) e não o
    /// score do compositor: Various Artists ou títulos "music from and
    /// inspired by"/"songs from". Álbum do próprio compositor nunca conta.
    static func isSongsCompilation(_ candidate: SoundtrackCandidate, composers: [String]) -> Bool {
        let artist = normalize(candidate.artistName)
        let normalizedComposers = composers.map(normalize)
        if normalizedComposers.contains(where: { artist.contains($0) || $0.contains(artist) }) {
            return false
        }
        let title = normalize(candidate.title)
        // "varios" cobre os nomes localizados do catálogo: "Vários
        // intérpretes" (pt), "Varios artistas" (es) — normalize já tirou
        // os acentos.
        return artist.contains("various")
            || artist.contains("varios")
            || title.contains("music from and inspired")
            || title.contains("songs from")
    }

    /// Pick heurístico do álbum de canções: a melhor compilação claramente
    /// vocal com nota positiva. nil quando o catálogo só tem score — o
    /// caminho single-album com splitTracks cobre esse caso.
    static func songsPick(_ scored: [Scored], composers: [String]) -> SoundtrackCandidate? {
        scored.first { $0.score > 0 && isSongsCompilation($0.candidate, composers: composers) }?
            .candidate
    }

    // MARK: - Vocal vs. instrumental

    struct TrackSplit: Sendable {
        let songs: [SoundtrackTrack]
        let instrumental: [SoundtrackTrack]
    }

    /// Separa as faixas do álbum em canções (vocais) e instrumentais para
    /// as duas fileiras da seção. Heurística barata: faixa cujo artista é o
    /// compositor (ou uma orquestra) é score; artista diferente — Céline
    /// Dion em Titanic, Whitney Houston em O Guarda-Costas — é canção.
    /// Sem compositor conhecido, o artista do álbum serve de referência;
    /// se nem isso houver (Various Artists), não separa.
    static func splitTracks(
        _ tracks: [SoundtrackTrack],
        albumArtist: String,
        composers: [String]
    ) -> TrackSplit {
        var references = composers.map(normalize)
        if references.isEmpty {
            let album = normalize(albumArtist)
            if !album.contains("various") { references = [album] }
        }
        guard !references.isEmpty else {
            return TrackSplit(songs: tracks, instrumental: [])
        }

        var songs: [SoundtrackTrack] = []
        var instrumental: [SoundtrackTrack] = []
        for track in tracks {
            if isInstrumental(track, references: references) {
                instrumental.append(track)
            } else {
                songs.append(track)
            }
        }
        return TrackSplit(songs: songs, instrumental: instrumental)
    }

    /// Uma faixa é score quando TODOS os créditos são o compositor ou uma
    /// orquestra: "James Horner & Orchestra" é score; "James Horner &
    /// Céline Dion" é canção — o vocalista convidado no crédito é o sinal
    /// (o álbum do Titanic credita a Céline exatamente assim).
    private static func isInstrumental(_ track: SoundtrackTrack, references: [String]) -> Bool {
        if normalize(track.title).contains("instrumental") { return true }
        let instrumentalMarkers = [
            "orchestra", "philharmonic", "symphony", "ensemble", "quartet",
        ]
        let components = artistComponents(track.artistName)
        guard !components.isEmpty else { return false }
        return components.allSatisfy { component in
            references.contains { component.contains($0) || $0.contains(component) }
                || instrumentalMarkers.contains(where: component.contains)
        }
    }

    /// Créditos individuais de um campo de artista ("A & B feat. C" → 3),
    /// normalizados.
    static func artistComponents(_ artist: String) -> [String] {
        var text = normalize(artist)
        for separator in [" feat. ", " feat ", " featuring ", " with ", " and ", " x "] {
            text = text.replacingOccurrences(of: separator, with: "&")
        }
        return text.split(whereSeparator: { $0 == "&" || $0 == "," })
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// Melhor resultado do catálogo para uma canção citada pelo modelo:
    /// título e artista precisam se conter mutuamente (normalizados).
    /// Canção alucinada com esse par exato é rara; sem match, ela some.
    static func bestSongMatch(
        title: String,
        artist: String,
        in candidates: [SoundtrackTrack]
    ) -> SoundtrackTrack? {
        let wantedTitle = normalize(title)
        let wantedArtist = normalize(artist)
        return candidates.first { candidate in
            let candidateTitle = normalize(candidate.title)
            let candidateArtist = normalize(candidate.artistName)
            let titleMatches = candidateTitle.contains(wantedTitle) || wantedTitle.contains(candidateTitle)
            let artistMatches = candidateArtist.contains(wantedArtist) || wantedArtist.contains(candidateArtist)
            return titleMatches && artistMatches
        }
    }

    /// Remove do pool de canções o lixo óbvio (karaokê, tributo, lullaby…)
    /// antes do prompt — menos ruído para o modelo rejeitar.
    static func plausibleSongCandidates(_ tracks: [SoundtrackTrack]) -> [SoundtrackTrack] {
        let junkMarkers = [
            "karaoke", "tribute", "8-bit", "8 bit", "lullaby", "lullabies",
            "made famous", "in the style of", "ringtone", "music box",
            "originally performed",
        ]
        return tracks.filter { track in
            let haystack = normalize("\(track.title) \(track.artistName) \(track.albumTitle ?? "")")
            return !junkMarkers.contains(where: haystack.contains)
        }
    }

    /// Minúsculas + sem diacríticos, para comparações lenientes.
    static func normalize(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
