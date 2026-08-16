//
//  PagedResponse.swift
//  CinemaTVKit
//
//  Envelope padrão de listas paginadas do TMDB (discover, search, etc.).
//  Substitui DiscoverMovies/UpcomingMovies/NowPlayingMovies/PopularMovies/
//  TopVotedMovies/SearchModel/MultiSearch, que eram o mesmo shape repetido.
//

import Foundation

public struct PagedResponse<Element: Decodable & Sendable>: Decodable, Sendable {
    public let page: Int
    public let results: [Element]
    public let totalPages: Int
    public let totalResults: Int

    public var hasMorePages: Bool { page < totalPages }
}
