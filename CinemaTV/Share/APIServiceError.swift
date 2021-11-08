//
//  APIServiceError.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import Foundation

enum APIServiceError: Error {
    case url
    case taskError(error: Error)
    case noResponse
    case noData
    case responseStatusCode(code: Int)
    case invalidJSON
}
