//
//  SearchIntents.swift
//  CinemaTV
//
//  "Procure por Duna no CinemaTV": a Siri/Apple Intelligence roteia a frase
//  para o schema .system.searchInApp. A resposta é inline — dialog + card com
//  os resultados na própria Siri (o default de foreground do schema é
//  sobrescrito para .background). O app só abre quando o usuário toca num
//  filme do card ou no botão "ver tudo", via OpenSearchInAppIntent.
//
//  Convive com o SearchMoviesIntent (que devolve entidades para Shortcuts);
//  o antigo é contrato de atalhos salvos.
//

import AppIntents
import CinemaTVCore

@AppIntent(schema: .system.searchInApp)
struct ShowSearchResultsIntent {
    static let searchScopes: [StringSearchScope] = [.general]

    // O schema exige modo foreground e o validador rejeita .background.
    // .foreground(.dynamic) adia a decisão para o runtime: como perform()
    // nunca chama continueInForeground, a resposta fica inline na Siri.
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    var criteria: StringSearchCriteria

    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        // Rodando do tile de Atalhos o critério chega vazio sem prompt — pede.
        var term = criteria.term.trimmingCharacters(in: .whitespacesAndNewlines)
        if term.isEmpty {
            term = try await $criteria.requestValue("What do you want to search for?").term
        }
        let client = IntentSupport.makeTMDBClient()
        // Multi-search cobre filmes e séries; o mapeamento do union filtra
        // pessoas e preserva a ordem de relevância do TMDB.
        let page: PagedResponse<MediaItem> = try await client.fetch(.multiSearch, query: term)
        let results = Array(VisualMediaResult.results(from: page.results).prefix(3))
        let dialog: IntentDialog = results.isEmpty
            ? "I couldn't find anything for \(term)."
            : "Here's what I found for \(term)."
        return .result(
            dialog: dialog,
            snippetIntent: SearchResultsSnippetIntent(query: term)
        )
    }
}

/// Abre a busca dentro do app — só roda quando o usuário toca no botão
/// "See all" do card da Siri.
struct OpenSearchInAppIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Search in CinemaTV"
    static let description = IntentDescription("Opens CinemaTV's search with a query.")
    static var supportedModes: IntentModes { .foreground }

    @Parameter(title: "Query")
    var query: String

    @Dependency
    private var router: AppRouter

    init() {}
    init(query: String) {
        self.query = query
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        router.open(.search(query: query))
        return .result()
    }
}
