//
//  SeasonModel.swift
//  CinemaTV
//

import Foundation
import CinemaTVCore
import CinemaTVDesignSystem

@MainActor
@Observable
final class SeasonModel {
    private(set) var state: LoadState<SeasonDetails> = .idle

    func load(client: TMDBClient, tvShowID: Int, seasonNumber: Int) async {
        if case .loaded = state { return }
        state = .loading
        do {
            let details: SeasonDetails = try await client.fetch(.tvShowSeason(id: tvShowID, season: seasonNumber))
            state = .loaded(details)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func retry(client: TMDBClient, tvShowID: Int, seasonNumber: Int) async {
        state = .idle
        await load(client: client, tvShowID: tvShowID, seasonNumber: seasonNumber)
    }

    /// O follow a partir daqui precisa do payload completo do show (o
    /// skeleton de temporadas vem do detalhe, não da temporada).
    func fetchShowDetails(client: TMDBClient, tvShowID: Int) async throws -> TVShowDetails {
        try await client.fetch(.tvShowDetail(id: tvShowID))
    }
}
