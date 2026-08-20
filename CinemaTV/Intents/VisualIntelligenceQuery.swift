//
//  VisualIntelligenceQuery.swift
//  CinemaTV
//
//  Busca do Visual Intelligence (câmera/screenshot): o sistema entrega os
//  labels do que foi visto e devolvemos filmes e séries do TMDB, cada um
//  abrível pelo seu OpenIntent. O TMDB não tem busca por imagem, então o
//  pixelBuffer do descriptor não é consumido — só os labels.
//
//  O framework VisualIntelligence só existe no SDK de device; a query fica
//  atrás de canImport para o Simulator continuar compilando. O union e o
//  mapeamento (testável) dependem só de AppIntents.
//

import AppIntents
import CinemaTVCore
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
        var seen = Set<String>()
        var results: [VisualMediaResult] = []
        for item in items where item.mediaType != .person {
            guard seen.insert("\(item.mediaType)-\(item.id)").inserted else { continue }
            switch item.mediaType {
            case .movie: results.append(.movie(MovieEntity(item: item)))
            case .tvShow: results.append(.tvShow(TVShowEntity(item: item)))
            case .person: break
            }
            if results.count == 10 { break }
        }
        return results
    }
}

#if canImport(VisualIntelligence)
struct VisualMediaQuery: IntentValueQuery {
    func values(for input: SemanticContentDescriptor) async throws -> [VisualMediaResult] {
        // Labels vêm ordenados por relevância; deduplica preservando a ordem
        // e limita as chamadas de rede.
        var seenLabels = Set<String>()
        let labels = input.labels.filter { seenLabels.insert($0).inserted }.prefix(3)
        guard !labels.isEmpty else { return [] }

        let client = TMDBClient(
            configuration: (try? .fromBundle(.main)) ?? TMDBConfiguration(apiKey: "")
        )
        let items = try await withThrowingTaskGroup(of: [MediaItem].self) { group in
            for label in labels {
                group.addTask {
                    let page: PagedResponse<MediaItem> = try await client.fetch(.multiSearch, query: label)
                    return page.results
                }
            }
            return try await group.reduce(into: [MediaItem]()) { $0 += $1 }
        }
        return VisualMediaResult.results(from: items)
    }
}
#endif
