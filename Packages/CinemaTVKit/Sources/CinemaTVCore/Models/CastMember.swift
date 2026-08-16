//
//  CastMember.swift
//  CinemaTVKit
//

import Foundation

public struct CreditsResponse: Decodable, Sendable {
    public let id: Int
    public let cast: [CastMember]
    /// Equipe técnica (diretor, roteiro etc.). Opcional: payloads de créditos
    /// antigos/fixtures sem crew seguem decodificando.
    public let crew: [CrewMember]?
}

/// Membro da equipe técnica de um filme, série ou episódio.
public struct CrewMember: Identifiable, Hashable, Sendable, Decodable {
    public let id: Int
    public let name: String
    public let job: String?
    public let department: String?
    public let profilePath: String?

    public init(id: Int, name: String, job: String?, department: String?, profilePath: String?) {
        self.id = id
        self.name = name
        self.job = job
        self.department = department
        self.profilePath = profilePath
    }
}

public struct CastMember: Identifiable, Hashable, Sendable, Decodable {
    public let id: Int
    public let name: String
    public let character: String?
    public let profilePath: String?
    public let order: Int?

    public var profileURL: URL? { TMDBImage.url(path: profilePath, size: .profile) }

    public init(id: Int, name: String, character: String?, profilePath: String?, order: Int?) {
        self.id = id
        self.name = name
        self.character = character
        self.profilePath = profilePath
        self.order = order
    }
}
