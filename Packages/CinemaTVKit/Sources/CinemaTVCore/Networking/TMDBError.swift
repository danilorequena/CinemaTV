//
//  TMDBError.swift
//  CinemaTVKit
//

import Foundation

public enum TMDBError: Error, Equatable, Sendable {
    case invalidEndpoint
    case invalidResponse(statusCode: Int?)
    case noData
    case decodingFailed(description: String)
    case transport(description: String)
}

extension TMDBError: LocalizedError {
    // Mensagens técnicas; o texto voltado ao usuário vem do ErrorStateView
    // do design system, que usa o String Catalog do app.
    public var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            "Invalid endpoint."
        case .invalidResponse(let statusCode):
            "Invalid server response (\(statusCode.map(String.init) ?? "unknown"))."
        case .noData:
            "No data received."
        case .decodingFailed(let description):
            "Could not read the server response: \(description)"
        case .transport(let description):
            "Network error: \(description)"
        }
    }
}
