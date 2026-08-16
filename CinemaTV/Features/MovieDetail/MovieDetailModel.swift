//
//  MovieDetailModel.swift
//  CinemaTV
//

import Foundation
import CinemaTVCore
import CinemaTVDesignSystem

@MainActor
@Observable
final class MovieDetailModel {
    struct Details: Sendable {
        let movie: MovieDetails
        let cast: [CastMember]
        let crew: [CrewMember]
        let videos: [Video]
        let providers: RegionProviders?
        let recommendations: [MediaItem]
    }

    private(set) var state: LoadState<Details> = .idle

    func load(client: TMDBClient, movieID: Int) async {
        if case .loaded = state { return }
        state = .loading
        do {
            async let movie: MovieDetails = client.fetch(.movieDetail(id: movieID))
            async let credits: CreditsResponse = client.fetch(.movieCredits(id: movieID))
            async let videos: VideosResponse = client.fetch(.movieVideos(id: movieID))
            async let providers: WatchProvidersResponse = client.fetch(.movieWatchProviders(id: movieID))
            async let recommendations: PagedResponse<MediaItem> = client.fetch(.movieRecommendations(id: movieID))

            state = .loaded(
                Details(
                    movie: try await movie,
                    cast: try await credits.cast,
                    crew: try await credits.crew ?? [],
                    videos: try await videos.results.filter(\.isYouTubeTrailer),
                    providers: try await providers.currentRegion,
                    recommendations: try await recommendations.results
                )
            )
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func retry(client: TMDBClient, movieID: Int) async {
        state = .idle
        await load(client: client, movieID: movieID)
    }
}
