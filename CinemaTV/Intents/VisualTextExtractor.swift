//
//  VisualTextExtractor.swift
//  CinemaTV
//
//  Transforma o OCR de um print/foto (Netflix, Apple TV, poster no cinema)
//  em termos de busca para o TMDB. Prints de apps de streaming são ruidosos —
//  botões ("Play", "Minha Lista"), marcadores de episódio, badges de
//  classificação — então filtra o lixo e ranqueia pelo tamanho do texto:
//  o título é quase sempre a maior linha da tela.
//
//  Sem imports de Vision/VisualIntelligence de propósito: a lógica é pura
//  e testável no Simulator; a ponte com o Vision fica na VisualMediaQuery.
//

import Foundation
import CoreGraphics

enum VisualTextExtractor {
    /// Linha reconhecida pelo OCR, desacoplada do tipo de observação do Vision.
    struct RecognizedLine: Equatable {
        var text: String
        /// Box normalizado (0–1), origem no canto inferior esquerdo (convenção do Vision).
        var boundingBox: CGRect
        var confidence: Float
    }

    /// Textos de UI de streaming que nunca são título (en + pt-BR).
    private static let uiStopwords: Set<String> = [
        "play", "resume", "my list", "episodes", "trailers", "more info",
        "more like this", "download", "downloads", "share", "watch now",
        "continue watching", "new episode", "recap", "skip intro",
        "assistir", "reproduzir", "retomar", "minha lista", "episódios",
        "trailers e mais", "baixar", "compartilhar", "continuar assistindo",
        "novo episódio", "mais como este", "pular abertura",
    ]

    /// Badges/marcadores que aparecem perto do título mas não são busca útil.
    /// Regex não é Sendable, então os padrões vivem como literais locais.
    private static func isJunk(_ text: String) -> Bool {
        let patterns: [String] = [
            #"(?i)^\s*S\d+\s*[:.,·]?\s*E\d+\s*$"#,                   // S1 E4
            #"(?i)^\s*(temporada|season)\s*\d+\s*$"#,                // Temporada 2
            #"^\s*[\d:.,%hm\s]+\s*$"#,                               // 2:15, 97%, 1h 45m
            #"(?i)^\s*(tv-?(ma|14|pg|y7?|g)|pg-?13|nc-?17|hd|4k|uhd|hdr|cc|sdh|[lr]|\d{1,2}\+?)\s*$"#,
        ]
        return patterns.contains { pattern in
            guard let regex = try? Regex(pattern) else { return false }
            return text.wholeMatch(of: regex) != nil
        }
    }

    /// Filtra, ranqueia por proeminência e devolve até `limit` termos de busca,
    /// sem duplicar os `labels` que o sistema já forneceu.
    static func searchTerms(
        from lines: [RecognizedLine],
        excluding labels: [String],
        limit: Int = 3
    ) -> [String] {
        let candidates = lines
            .filter { $0.confidence >= 0.5 }
            .map { RecognizedLine(
                text: $0.text.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacing(#/\s+/#) { _ in " " },
                boundingBox: $0.boundingBox,
                confidence: $0.confidence
            ) }
            .filter { line in
                line.text.count(where: \.isLetter) >= 3
                    && !uiStopwords.contains(line.text.lowercased())
                    && !isJunk(line.text)
            }
            .sorted { lhs, rhs in
                // Título = texto mais alto; empate por área, depois mais acima na tela.
                if lhs.boundingBox.height != rhs.boundingBox.height {
                    return lhs.boundingBox.height > rhs.boundingBox.height
                }
                let lhsArea = lhs.boundingBox.width * lhs.boundingBox.height
                let rhsArea = rhs.boundingBox.width * rhs.boundingBox.height
                if lhsArea != rhsArea { return lhsArea > rhsArea }
                return lhs.boundingBox.minY > rhs.boundingBox.minY
            }

        var seen = Set(labels.map(normalized))
        var terms: [String] = []
        for candidate in candidates {
            guard seen.insert(normalized(candidate.text)).inserted else { continue }
            terms.append(candidate.text)
            if terms.count == limit { break }
        }
        return terms
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
