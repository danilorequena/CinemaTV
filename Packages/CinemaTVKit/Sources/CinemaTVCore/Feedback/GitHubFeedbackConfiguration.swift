//
//  GitHubFeedbackConfiguration.swift
//  CinemaTVCore
//
//  Config do canal de feedback via GitHub Issues. O repo é público:
//  leitura (backlog do Coming Soon) funciona sem token; criação de
//  issue usa um fine-grained PAT (permissão só de Issues deste repo)
//  lido de um GitHub.plist FORA do git — commitado num repo público,
//  o secret scanning do GitHub revoga o token automaticamente.
//

import Foundation

public struct GitHubFeedbackConfiguration: Sendable {
    public let owner: String
    public let repo: String
    /// nil = sem token: leitura continua funcionando, criação desabilita
    /// e a tela de request volta a usar só o e-mail.
    public let token: String?

    public init(owner: String = "danilorequena", repo: String = "CinemaTV", token: String? = nil) {
        self.owner = owner
        self.repo = repo
        self.token = token
    }

    public var canCreateIssues: Bool { token != nil }

    /// Lê o token de um GitHub.plist no bundle (chave ISSUES_TOKEN).
    /// Plist ausente, vazio ou com placeholder → somente leitura.
    public static func fromBundle(_ bundle: Bundle) -> GitHubFeedbackConfiguration {
        guard
            let url = bundle.url(forResource: "GitHub", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let token = plist["ISSUES_TOKEN"] as? String,
            !token.isEmpty,
            !token.hasPrefix("PASTE_")
        else {
            return GitHubFeedbackConfiguration()
        }
        return GitHubFeedbackConfiguration(token: token)
    }
}
