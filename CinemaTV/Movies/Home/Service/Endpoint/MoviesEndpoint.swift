//
//  MoviesEndpoint.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

enum MoviesEndpoint {
    case popular, toRated, upcoming, nowPlaying, latest
    case detail(movie: Int), recommended(movie: Int), similar(movie: Int), detailTVShow(tvShow: Int)
    case credits(movie: Int), review(movie: Int), videos(videoID: Int)
    case searchMovie, searchKeyword, multiSearch
    case genres
    case discover
    case person(id: Int)
    case creditByPerson(id: Int)
    case watchProviders(movieID: Int)
    
    func path() -> String {
        switch self {
        case .popular:
            return "movie/popular"
        case .latest:
            return "movie/latest"
        case .toRated:
            return "movie/top_rated"
        case .upcoming:
            return "movie/upcoming"
        case .nowPlaying:
            return "movie/now_playing"
        case let .detail(movie):
            return "movie/\(String(movie))"
        case let .detailTVShow(tvShow):
            return "tv/\(String(tvShow))"
        case let .credits(movie):
            return "movie/\(String(movie))/credits"
        case let .review(movie):
            return "movie/\(String(movie))/reviews"
        case let .videos(videoID):
            return "movie/\(String(videoID))/videos"
        case let .recommended(movie):
            return "movie/\(String(movie))/recommendations"
        case let .similar(movie):
            return "movie/\(String(movie))/similar"
        case .multiSearch:
            return "search/multi"
        case .searchMovie:
            return "search/movie"
        case .searchKeyword:
            return "search/keyword"
        case .genres:
            return "genre/movie/list"
        case .discover:
            return "discover/movie"
        case .person(let id):
            return "person/\(String(id))"
        case .creditByPerson(let id):
            return "person/\(String(id))/movie_credits"
        case let .watchProviders(movieID):
            return "movie/\(String(movieID))/watch/providers"
        }
    }
}

