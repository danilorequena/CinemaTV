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

enum RequestError: Error, CustomNSError {
    case apiError
    case invalidEndpoint
    case invalidResponse
    case noData
    case serializationError
    
    var localizedDescription: String {
        switch self {
        case .apiError:
            return "Failed to fetch data"
        case .invalidEndpoint:
            return "invalid Endpoint"
        case .invalidResponse:
            return "invalid Response"
        case .noData:
            return "No Data"
        case .serializationError:
            return "Failed to Decode data"
        }
    }
    
    var errorUserInfo: [String : Any] {
        [NSLocalizedDescriptionKey: localizedDescription]
    }
}
