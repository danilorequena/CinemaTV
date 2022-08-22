//
//  Utils.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/03/22.
//

import Foundation


final class Utils {
    static let jsonDecoder: JSONDecoder = {
       let jsonDecoder = JSONDecoder()
//        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        jsonDecoder.dateDecodingStrategy = .formatted(dateFormatter)
        return jsonDecoder
    }()
    
    static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-mm-yyyy"
        return dateFormatter
    }()
}
