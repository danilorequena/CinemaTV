//
//  TMDBEndpointTests.swift
//  CinemaTVKit
//

import Testing
@testable import CinemaTVCore

@Suite struct TMDBEndpointTests {
    @Test func moviePaths() {
        #expect(TMDBEndpoint.discoverMovies.path == "discover/movie")
        #expect(TMDBEndpoint.upcomingMovies.path == "movie/upcoming")
        #expect(TMDBEndpoint.nowPlayingMovies.path == "movie/now_playing")
        #expect(TMDBEndpoint.popularMovies.path == "movie/popular")
        #expect(TMDBEndpoint.topRatedMovies.path == "movie/top_rated")
        #expect(TMDBEndpoint.movieDetail(id: 603).path == "movie/603")
        #expect(TMDBEndpoint.movieCredits(id: 603).path == "movie/603/credits")
        #expect(TMDBEndpoint.movieVideos(id: 603).path == "movie/603/videos")
        #expect(TMDBEndpoint.movieRecommendations(id: 603).path == "movie/603/recommendations")
        #expect(TMDBEndpoint.similarMovies(id: 603).path == "movie/603/similar")
        #expect(TMDBEndpoint.movieWatchProviders(id: 603).path == "movie/603/watch/providers")
        #expect(TMDBEndpoint.searchMovies.path == "search/movie")
        #expect(TMDBEndpoint.multiSearch.path == "search/multi")
        #expect(TMDBEndpoint.trendingAll.path == "trending/all/week")
    }

    @Test func personPaths() {
        #expect(TMDBEndpoint.person(id: 31).path == "person/31")
        #expect(TMDBEndpoint.personCredits(id: 31).path == "person/31/combined_credits")
    }

    @Test func tvPaths() {
        #expect(TMDBEndpoint.discoverTVShows.path == "discover/tv")
        #expect(TMDBEndpoint.airingTodayTVShows.path == "tv/airing_today")
        #expect(TMDBEndpoint.onTheAirTVShows.path == "tv/on_the_air")
        #expect(TMDBEndpoint.popularTVShows.path == "tv/popular")
        #expect(TMDBEndpoint.tvShowDetail(id: 1399).path == "tv/1399")
        #expect(TMDBEndpoint.tvShowSeason(id: 1399, season: 2).path == "tv/1399/season/2")
        #expect(TMDBEndpoint.tvShowCredits(id: 1399).path == "tv/1399/credits")
        #expect(TMDBEndpoint.tvShowVideos(id: 1399).path == "tv/1399/videos")
        #expect(TMDBEndpoint.tvShowWatchProviders(id: 1399).path == "tv/1399/watch/providers")
        #expect(TMDBEndpoint.tvShowRecommendations(id: 1399).path == "tv/1399/recommendations")
        #expect(TMDBEndpoint.similarTVShows(id: 1399).path == "tv/1399/similar")
    }
}
