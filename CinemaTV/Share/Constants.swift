//
//  Constants.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

struct Constants {
    //URLs
    static let baseUrl = "https://api.themoviedb.org/3/"
    static let basePosters = "https://image.tmdb.org/t/p/w500"
    static let basePostersMin = "https://image.tmdb.org/t/p/w92"
    static let baseTrailers = "https://www.youtube.com/embed/"
    
    //Screen Titles
    static let discover = "Discover"
    static let detail = "Detail"
    
    static var apikey: String {
        get {
            guard let filePath = Bundle.main.path(forResource: "TMDB", ofType: "plist") else {
                fatalError("Couldn't find file 'TMDB-Info.plist'.")
            }
            
            let plist = NSDictionary(contentsOfFile: filePath)
            guard let value = plist?.object(forKey: "API_KEY") as? String else {
                fatalError("Couldn't find key 'API_KEY' in 'TMDB-Info.plist'.")
            }
            return value
        }
    }
}
