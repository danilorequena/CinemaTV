//
//  TVShowDetailModel.swift
//  CinemaTV
//

import Foundation
import CinemaTVCore
import CinemaTVDesignSystem

@MainActor
@Observable
final class TVShowDetailModel {
    struct Details: Sendable {
        let show: TVShowDetails
        let cast: [CastMember]
        let videos: [Video]
        let providers: RegionProviders?
        let recommendations: [MediaItem]
    }

    private(set) var state: LoadState<Details> = .idle

    func load(client: TMDBClient, showID: Int) async {
        if case .loaded = state { return }
        state = .loading
        do {
            async let show: TVShowDetails = client.fetch(.tvShowDetail(id: showID))
            async let credits: CreditsResponse = client.fetch(.tvShowCredits(id: showID))
            async let videos: VideosResponse = client.fetch(.tvShowVideos(id: showID))
            async let providers: WatchProvidersResponse = client.fetch(.tvShowWatchProviders(id: showID))
            async let recommendations: PagedResponse<MediaItem> = client.fetch(.tvShowRecommendations(id: showID))

            state = .loaded(
                Details(
                    show: try await show,
                    cast: try await credits.cast,
                    videos: try await videos.results.filter(\.isYouTubeTrailer),
                    providers: try await providers.currentRegion,
                    recommendations: try await recommendations.results
                )
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func retry(client: TMDBClient, showID: Int) async {
        state = .idle
        await load(client: client, showID: showID)
    }
}
