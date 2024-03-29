//
//  LocalizedConstants.swift
//  CinemaTV
//
//  Created by Jessica Bigal on 24/09/22.
//

import Foundation
import UIKit

typealias LC = LocalizedConstants

enum LocalizedConstants: String {
    
    //MARK: - TrailerView
    case trailer
    
    //MARK: - HomeView
    case soon
    case nowPlaying
    case popular
    case rated
    case movies
    case seeAll
    case discover
    case tvShows
    case watchedTag
    
    //MARK: - TVShowsHome
    case onTheAir
    case popTVShows
    case airingToday
    
    //MARK: - CinemaTVProgressView
    case loading
    
    // MARK: - Details
    case recommendations
    case similars
    case releaseDate
    case average
    case watchButton
    case watchedButton
    case addFavorites
    
    //MARK: - Credits
    case creditsName
    case creditsParagraph

    // MARK: - Widget
    case commingSoon
    case commingSoonDescription

    
    var text: String {
        return rawValue.localized(.presentation)
    }
}
