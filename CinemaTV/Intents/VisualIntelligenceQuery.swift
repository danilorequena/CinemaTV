//
//  VisualIntelligenceQuery.swift
//  CinemaTV
//
//  Busca do Visual Intelligence (câmera/screenshot): o sistema entrega o que
//  foi visto e devolvemos filmes e séries do TMDB, cada um abrível pelo seu
//  OpenIntent. O TMDB não tem busca por imagem, então a identificação combina
//  duas fontes: os labels do sistema e OCR do pixelBuffer (Vision) — num print
//  da Netflix/Apple TV o título está escrito na tela, e é ele que buscamos.
//
//  O framework VisualIntelligence só existe no SDK de device; a query fica
//  atrás de canImport para o Simulator continuar compilando. O union, o
//  mapeamento e a extração de termos (testáveis) não dependem dele.
//

import AppIntents
import CinemaTVCore
import CoreImage
import CoreVideo
import Vision
#if canImport(VisualIntelligence)
import VisualIntelligence
#endif

@UnionValue
enum VisualMediaResult {
    case movie(MovieEntity)
    case tvShow(TVShowEntity)
}

extension VisualMediaResult {
    /// Mapeamento puro (testável sem rede): filtra pessoas, deduplica por
    /// tipo+id (filme e série podem compartilhar o mesmo id numérico) e
    /// limita a 10 resultados.
    static func results(from items: [MediaItem]) -> [VisualMediaResult] {
        results(from: items, preferringTitlesMatching: [])
    }

    /// Variante com ranking: itens cujo título casa com algum termo do OCR
    /// vêm primeiro (partição estável), porque texto lido da tela é mais
    /// específico que um label genérico do sistema.
    static func results(
        from items: [MediaItem],
        preferringTitlesMatching terms: [String]
    ) -> [VisualMediaResult] {
        let normalizedTerms = terms.map(normalized)
        var preferred: [VisualMediaResult] = []
        var others: [VisualMediaResult] = []
        var seen = Set<String>()
        for item in items where item.mediaType != .person {
            guard seen.insert("\(item.mediaType)-\(item.id)").inserted else { continue }
            let result: VisualMediaResult
            switch item.mediaType {
            case .movie: result = .movie(MovieEntity(item: item))
            case .tvShow: result = .tvShow(TVShowEntity(item: item))
            case .person: continue
            }
            let title = normalized(item.title)
            if normalizedTerms.contains(where: { $0.contains(title) || title.contains($0) }) {
                preferred.append(result)
            } else {
                others.append(result)
            }
            if preferred.count == 10 { break }
        }
        return Array((preferred + others).prefix(10))
    }

    private static func normalized(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

/// Ponte com o Vision: só precisa de CoreVideo + Vision + CoreImage, então
/// compila (e é verificável) também no Simulator, fora do canImport.
enum VisualTextRecognizer {
    /// OCR do print/frame. Qualquer falha degrada para labels-only ([]).
    static func recognizedLines(
        in pixelBuffer: CVReadOnlyPixelBuffer
    ) async -> [VisualTextExtractor.RecognizedLine] {
        // O CVPixelBuffer não pode escapar do withUnsafeBuffer (contrato de
        // ownership + region isolation), então materializa um CGImage —
        // imutável e Sendable — e roda o Vision sobre ele.
        let cgImage = pixelBuffer.withUnsafeBuffer { buffer -> CGImage? in
            let ciImage = CIImage(cvPixelBuffer: buffer)
            return CIContext().createCGImage(ciImage, from: ciImage.extent)
        }
        guard let cgImage else { return [] }

        var request = RecognizeTextRequest()
        request.recognitionLanguages = [
            Locale.Language(identifier: "en-US"),
            Locale.Language(identifier: "pt-BR"),
        ]
        request.usesLanguageCorrection = true
        do {
            let observations = try await request.perform(on: cgImage)
            return observations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return VisualTextExtractor.RecognizedLine(
                    text: candidate.string,
                    boundingBox: observation.boundingBox.cgRect,
                    confidence: candidate.confidence
                )
            }
        } catch {
            return []
        }
    }
}

#if canImport(VisualIntelligence)
struct VisualMediaQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [VisualMediaResult] {
        // Labels vêm ordenados por relevância; deduplica preservando a ordem.
        var seenLabels = Set<String>()
        let labels = Array(input.labels.filter { seenLabels.insert($0).inserted }.prefix(2))

        // OCR do print: os termos lidos da tela buscam primeiro por serem
        // mais específicos ("Dune: Part Two") que os labels ("movie poster").
        var ocrTerms: [String] = []
        if let pixelBuffer = input.pixelBuffer {
            let lines = await VisualTextRecognizer.recognizedLines(in: pixelBuffer)
            ocrTerms = VisualTextExtractor.searchTerms(from: lines, excluding: labels, limit: 3)
        }

        // Orçamento total de 4 buscas por invocação.
        let terms = Array((ocrTerms + labels).prefix(4))
        guard !terms.isEmpty else { return [] }

        let client = IntentSupport.makeTMDBClient()
        // Coleta por termo e achata na ordem original (task group não
        // preserva ordem) para manter os resultados do OCR na frente.
        let itemsByTerm = try await withThrowingTaskGroup(
            of: (Int, [MediaItem]).self
        ) { group in
            for (index, term) in terms.enumerated() {
                group.addTask {
                    let page: PagedResponse<MediaItem> = try await client.fetch(.multiSearch, query: term)
                    return (index, page.results)
                }
            }
            return try await group.reduce(into: [[MediaItem]](repeating: [], count: terms.count)) {
                $0[$1.0] = $1.1
            }
        }
        return VisualMediaResult.results(
            from: itemsByTerm.flatMap(\.self),
            preferringTitlesMatching: ocrTerms
        )
    }
}
#endif
