//
//  DetailMoviesModel.swift
//  CinemaTV
//
//  Created by Danilo Requena on 20/11/21.

import Foundation

// MARK: - DetailMovies
struct DetailMoviesModel: Codable, Identifiable {
    let backdropPath: String
    let genres: [Genre]
    let id: Int
    let imdbID, originalLanguage, originalTitle, overview: String
    let popularity: Double
    let posterPath: String
    let releaseDate: String
    let status, tagline, title: String
    let video: Bool
    let voteAverage: Double
    let voteCount: Int

    enum CodingKeys: String, CodingKey {
        case backdropPath = "backdrop_path"
        case genres, id
        case imdbID = "imdb_id"
        case originalLanguage = "original_language"
        case originalTitle = "original_title"
        case overview, popularity
        case posterPath = "poster_path"
        case releaseDate = "release_date"
        case status, tagline, title, video
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
    }
    
    var voteAverageFormatted: String {
        String(format: "%.1f", voteAverage) + "/10"
    }
    
    var releaseDateFormatted: String {
        releaseDate.formatString()
    }
}

// MARK: - Genre
struct Genre: Codable {
    let id: Int
    let name: String
}

extension DetailMoviesModel: CustomStringConvertible {
    var description: String {
            let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 2

            let number = NSNumber(floatLiteral: voteAverage)
            let formattedValue = formatter.string(from: number)!
        return formattedValue
        }
}

