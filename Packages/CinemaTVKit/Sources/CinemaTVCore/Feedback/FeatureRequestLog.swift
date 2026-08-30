//
//  FeatureRequestLog.swift
//  CinemaTVCore
//
//  Registro local (por aparelho) das sugestões que este app enviou
//  como issue — é o que alimenta a tela My Requests. Arquivo JSON em
//  Application Support; propositalmente fora do SwiftData/CloudKit:
//  é um histórico pequeno e local, não dado sincronizável.
//

import Foundation

public struct LoggedFeatureRequest: Codable, Sendable, Identifiable {
    public let issueNumber: Int
    public let title: String
    public let kind: SuggestionKind
    public let requesterName: String?
    public let createdAt: Date
    public var state: String
    public var milestoneTitle: String?
    public let htmlURL: URL

    public var id: Int { issueNumber }
    public var isOpen: Bool { state == "open" }

    /// Aberta e promovida à milestone do Coming Soon.
    public var isInBacklog: Bool {
        guard isOpen, let milestoneTitle else { return false }
        return milestoneTitle.caseInsensitiveCompare(GitHubFeedbackClient.backlogMilestoneTitle) == .orderedSame
    }

    public init(issue: FeedbackIssue, kind: SuggestionKind, requesterName: String?, createdAt: Date) {
        self.issueNumber = issue.number
        self.title = issue.title
        self.kind = kind
        self.requesterName = requesterName
        self.createdAt = createdAt
        self.state = issue.state
        self.milestoneTitle = issue.milestone?.title
        self.htmlURL = issue.htmlUrl
    }
}

@MainActor
public final class FeatureRequestLog {
    private let fileURL: URL

    /// Diretório injetável para testes; default = Application Support.
    public init(directory: URL? = nil) {
        let base = directory ?? FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.temporaryDirectory
        self.fileURL = base.appending(path: "FeatureRequests.json")
    }

    /// Mais recente primeiro.
    public func all() -> [LoggedFeatureRequest] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let requests = try? decoder.decode([LoggedFeatureRequest].self, from: data)
        else {
            return []
        }
        return requests.sorted { $0.createdAt > $1.createdAt }
    }

    public func append(_ request: LoggedFeatureRequest) {
        var requests = all()
        requests.removeAll { $0.issueNumber == request.issueNumber }
        requests.append(request)
        save(requests)
    }

    /// Sincroniza estado/milestone com o que veio do GitHub.
    public func apply(_ issues: [FeedbackIssue]) {
        guard !issues.isEmpty else { return }
        let byNumber = Dictionary(uniqueKeysWithValues: issues.map { ($0.number, $0) })
        var requests = all()
        for index in requests.indices {
            guard let issue = byNumber[requests[index].issueNumber] else { continue }
            requests[index].state = issue.state
            requests[index].milestoneTitle = issue.milestone?.title
        }
        save(requests)
    }

    private func save(_ requests: [LoggedFeatureRequest]) {
        guard let data = try? encoder.encode(requests) else { return }
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try? data.write(to: fileURL, options: .atomic)
    }

    private var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
