//
//  GitHubFeedbackModels.swift
//  CinemaTVCore
//
//  Modelos da API de issues do GitHub usados pelo feedback: só os
//  campos que o app consome. Decode com convertFromSnakeCase.
//

import Foundation

public struct FeedbackIssue: Identifiable, Sendable, Decodable {
    public struct Label: Sendable, Decodable {
        public let name: String

        public init(name: String) {
            self.name = name
        }
    }

    public struct Milestone: Sendable, Decodable {
        public let title: String

        public init(title: String) {
            self.title = title
        }
    }

    /// A API de issues devolve PRs junto; a presença desta chave é o
    /// jeito documentado de filtrá-los.
    public struct PullRequestMarker: Sendable, Decodable {}

    public let number: Int
    public let title: String
    public let state: String
    public let body: String?
    public let labels: [Label]
    public let milestone: Milestone?
    public let htmlUrl: URL
    public let pullRequest: PullRequestMarker?

    public var id: Int { number }
    public var isOpen: Bool { state == "open" }

    /// Categoria inferida das labels; sem label conhecida vira feature.
    public var kind: SuggestionKind {
        let names = Set(labels.map { $0.name.lowercased() })
        if names.contains("bug") { return .bug }
        if names.contains("improvement") { return .improvement }
        return .feature
    }

    /// Crédito extraído da linha "From:" que o app escreve no corpo
    /// da issue; "—" é o marcador de anônimo.
    public var credit: String? {
        guard let body else { return nil }
        for line in body.split(separator: "\n") where line.hasPrefix("From:") {
            let value = line.dropFirst("From:".count).trimmingCharacters(in: .whitespaces)
            return (value.isEmpty || value == "—") ? nil : value
        }
        return nil
    }

    public init(
        number: Int,
        title: String,
        state: String,
        body: String? = nil,
        labels: [Label] = [],
        milestone: Milestone? = nil,
        htmlUrl: URL
    ) {
        self.number = number
        self.title = title
        self.state = state
        self.body = body
        self.labels = labels
        self.milestone = milestone
        self.htmlUrl = htmlUrl
        self.pullRequest = nil
    }
}

public struct GitHubMilestone: Sendable, Decodable {
    public let number: Int
    public let title: String
}

public enum GitHubFeedbackError: Error, Sendable {
    case missingToken
    case transport(description: String)
    case invalidResponse(statusCode: Int?)
    case decodingFailed(description: String)
}
