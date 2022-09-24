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
    
    case trailer
    
    //MARK: - HomeView
    case soon
    case onCine
    case popular
    case rated
    case movies
    case seeAll
    case discover
    
    var text: String {
        return rawValue.localized(.presentation)
    }
}
