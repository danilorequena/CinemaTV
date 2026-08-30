//
//  TVShowIntents.swift
//  CinemaTV
//
//  Intents de séries. FollowShowIntent é o análogo de "adicionar à watchlist"
//  para TV: com a série na tela (onscreen entity do TVShowDetailScreen),
//  "siga essa série" resolve direto pela Siri.
//

import Foundation
import AppIntents
import CinemaTVCore

struct FollowShowIntent: AppIntent {
    static let title: LocalizedStringResource = "Follow TV Show"
    static let description = IntentDescription("Follows a TV show in CinemaTV to track episodes.")

    @Parameter(title: "TV Show")
    var show: TVShowEntity

    init() {}
    init(show: TVShowEntity) {
        self.show = show
    }

    static var parameterSummary: some ParameterSummary {
        Summary("Follow \(\.$show)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetIntent {
        // Follow grava uma SeasonSD por temporada, então precisa do payload
        // completo do detalhe — a entidade só carrega id/título/poster.
        let client = IntentSupport.makeTMDBClient()
        let details: TVShowDetails = try await client.fetch(.tvShowDetail(id: show.id))
        let store = TVShowTrackingStore(container: AppContainer.shared)
        try store.follow(details)
        return .result(
            dialog: "Now following \(show.title).",
            snippetIntent: TVShowCardSnippetIntent(show: show)
        )
    }
}
