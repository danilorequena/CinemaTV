//
//  MoviesEndpoint.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

enum TVShowsEndpoint {
    case popular, toRated, upcoming, nowPlaying, latest
    case detail(tvShowID: Int), recommended(movie: Int), similar(movie: Int)
    case credits(tvShow: Int), review(movie: Int), videos(videoID: Int)
    case recommendations(tvShowID: Int)
    case searchMovie, searchKeyword
    case genres
    case discover
    case person(id: Int)
    case creditByPerson(id: Int)
    case watchProviders(movieID: Int)
    case season(seasonID: Int, seasonNumber: Int)
    case airingToday
    
    func path() -> String {
        switch self {
        case .popular:
            return "tv/popular"
        case .latest:
            return "tv/latest"
        case .toRated:
            return "tv/top_rated"
        case .upcoming:
            return "tv/upcoming"
        case .airingToday:
            return "tv/airing_today"
        case .nowPlaying:
            return "tv/on_the_air"
        case let .detail(tvShow):
            return "tv/\(String(tvShow))"
        case let .credits(tvShow):
            return "tv/\(String(tvShow))/credits"
        case let .recommendations(tvShowID):
            return "tv/\(String(tvShowID))/recommendations"
        case let .review(movie):
            return "movie/\(String(movie))/reviews"
        case let .videos(videoID):
            return "movie/\(String(videoID))/videos"
        case let .recommended(movie):
            return "movie/\(String(movie))/recommendations"
        case let .similar(movie):
            return "tv/\(String(movie))/similar"
        case .searchMovie:
            return "search/movie"
        case .searchKeyword:
            return "search/keyword"
        case .genres:
            return "genre/movie/list"
        case .person(let id):
            return "person/\(String(id))"
        case .creditByPerson(let id):
            return "person/\(String(id))/tv_credits"
        case .discover:
            return "discover/tv"
        case let .watchProviders(movieID):
            return "movie/\(String(movieID))/watch/providers"
        case let .season(seasonID, seasonNumber):
            return "tv/\(seasonID)/season/\(seasonNumber)"
        }
    }
}

