//
//  GitHubFeedbackClient.swift
//  CinemaTVCore
//
//  Cliente mínimo da API de issues do GitHub, no molde do TMDBClient
//  (struct Sendable + URLSession + typed throws). Leitura funciona sem
//  token (repo público); criação exige o token da configuration.
//

import Foundation

public struct GitHubFeedbackClient: Sendable {
    /// Título da milestone que promove uma issue ao Coming Soon do app.
    public static let backlogMilestoneTitle = "Backlog"

    public let configuration: GitHubFeedbackConfiguration
    private let session: URLSession
    private let decoder: JSONDecoder

    public init(configuration: GitHubFeedbackConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    // MARK: - API

    /// Cria a issue com o token embutido — o autor no GitHub é a conta
    /// dona do token; quem pediu fica na linha "From:" do corpo.
    public func createIssue(
        title: String,
        body: String,
        labels: [String]
    ) async throws(GitHubFeedbackError) -> FeedbackIssue {
        guard configuration.canCreateIssues else { throw .missingToken }

        struct Payload: Encodable {
            let title: String
            let body: String
            let labels: [String]
        }
        let payload: Data
        do {
            payload = try JSONEncoder().encode(Payload(title: title, body: body, labels: labels))
        } catch {
            throw .decodingFailed(description: String(describing: error))
        }

        let request = try makeRequest(path: "issues", method: "POST", httpBody: payload)
        return try await perform(request)
    }

    /// Issues abertas na milestone "Backlog" — o que aparece no
    /// Coming Soon. Milestone inexistente = backlog vazio, sem erro.
    public func fetchBacklog() async throws(GitHubFeedbackError) -> [FeedbackIssue] {
        let milestones: [GitHubMilestone] = try await perform(
            try makeRequest(path: "milestones", queryItems: [
                URLQueryItem(name: "state", value: "open"),
                URLQueryItem(name: "per_page", value: "100")
            ])
        )
        guard let backlog = milestones.first(where: {
            $0.title.caseInsensitiveCompare(Self.backlogMilestoneTitle) == .orderedSame
        }) else {
            return []
        }

        let issues: [FeedbackIssue] = try await perform(
            try makeRequest(path: "issues", queryItems: [
                URLQueryItem(name: "milestone", value: String(backlog.number)),
                URLQueryItem(name: "state", value: "open"),
                URLQueryItem(name: "per_page", value: "100")
            ])
        )
        return issues.filter { $0.pullRequest == nil }
    }

    public func fetchIssue(number: Int) async throws(GitHubFeedbackError) -> FeedbackIssue {
        try await perform(try makeRequest(path: "issues/\(number)"))
    }

    /// Atualização de status das requests locais: melhor esforço,
    /// falha individual só pula a issue (offline devolve vazio).
    public func fetchIssues(numbers: [Int]) async -> [FeedbackIssue] {
        var issues: [FeedbackIssue] = []
        for number in numbers {
            if let issue = try? await fetchIssue(number: number) {
                issues.append(issue)
            }
        }
        return issues
    }

    // MARK: - Plumbing

    private func makeRequest(
        path: String,
        queryItems: [URLQueryItem] = [],
        method: String = "GET",
        httpBody: Data? = nil
    ) throws(GitHubFeedbackError) -> URLRequest {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.github.com"
        components.path = "/repos/\(configuration.owner)/\(configuration.repo)/\(path)"
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else {
            throw .invalidResponse(statusCode: nil)
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = httpBody
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        // Leitura também manda o token quando existe: rate limit de
        // 5000/h em vez de 60/h por IP.
        if let token = configuration.token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return request
    }

    private func perform<T: Decodable & Sendable>(_ request: URLRequest) async throws(GitHubFeedbackError) -> T {
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw .transport(description: error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw .invalidResponse(statusCode: nil)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw .invalidResponse(statusCode: http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw .decodingFailed(description: String(describing: error))
        }
    }
}
