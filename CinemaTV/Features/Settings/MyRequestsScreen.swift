//
//  MyRequestsScreen.swift
//  CinemaTV
//
//  Histórico local (por aparelho) das sugestões enviadas como issue,
//  com status atualizado do GitHub: Open / Coming Soon / Closed.
//  Row plana; tocar abre a issue no navegador.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct MyRequestsScreen: View {
    @Environment(\.feedbackClient) private var feedbackClient
    @Environment(\.openURL) private var openURL
    /// Injeção para previews — pula o arquivo local e a rede.
    var previewRequests: [LoggedFeatureRequest]?

    @State private var requests: [LoggedFeatureRequest] = []

    var body: some View {
        Group {
            if requests.isEmpty {
                EmptyStateView(
                    title: "No Requests Yet",
                    message: "Suggestions you send from this device appear here.",
                    systemImage: "paperplane"
                )
            } else {
                List {
                    Section {
                        ForEach(requests) { request in
                            row(for: request)
                        }
                    } footer: {
                        Text("Tap a request to follow the conversation on GitHub.")
                    }
                }
            }
        }
        .navigationTitle("My Requests")
        .navigationBarTitleDisplayMode(.inline)
        .task { await refresh() }
    }

    /// Button + openURL em vez de Link: o Link tinge a row inteira de
    /// azul e quebra o padrão de rows planas com texto .primary.
    private func row(for request: LoggedFeatureRequest) -> some View {
        Button {
            openURL(request.htmlURL)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.md) {
                Image(systemName: request.kind.symbolName)
                    .foregroundStyle(DSColor.accent)
                    .frame(width: 24)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(verbatim: request.title)
                        .foregroundStyle(.primary)
                    HStack(spacing: DSSpacing.sm) {
                        statusText(for: request)
                        Text(request.createdAt, format: .dateTime.day().month().year())
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.dsCaption)
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the request on GitHub")
    }

    private func statusText(for request: LoggedFeatureRequest) -> some View {
        Group {
            if !request.isOpen {
                // Key própria: "Done" já existe como botão de toolbar
                // ("OK" em pt-BR) — contexto errado para status de issue.
                Text("Closed")
                    .foregroundStyle(.secondary)
            } else if request.isInBacklog {
                Text("Coming Soon")
                    .foregroundStyle(DSColor.accent)
            } else {
                Text("Open")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.dsCaption)
    }

    private func refresh() async {
        if let previewRequests {
            requests = previewRequests
            return
        }
        let log = FeatureRequestLog()
        requests = log.all()
        guard !requests.isEmpty else { return }
        // Melhor esforço: offline mantém o último status conhecido.
        let issues = await feedbackClient.fetchIssues(numbers: requests.map(\.issueNumber))
        log.apply(issues)
        requests = log.all()
    }
}

#Preview("My Requests") {
    NavigationStack {
        MyRequestsScreen(previewRequests: [
            LoggedFeatureRequest(
                issue: FeedbackIssue(
                    number: 12,
                    title: "Home Screen widgets for your watchlist",
                    state: "open",
                    milestone: .init(title: "Backlog"),
                    htmlUrl: URL(string: "https://github.com/danilorequena/CinemaTV/issues/12")!
                ),
                kind: .feature,
                requesterName: "@moviebuff",
                createdAt: .now
            ),
            LoggedFeatureRequest(
                issue: FeedbackIssue(
                    number: 8,
                    title: "Faster iCloud sync for large libraries",
                    state: "open",
                    htmlUrl: URL(string: "https://github.com/danilorequena/CinemaTV/issues/8")!
                ),
                kind: .improvement,
                requesterName: nil,
                createdAt: .now
            ),
            LoggedFeatureRequest(
                issue: FeedbackIssue(
                    number: 3,
                    title: "Fix crash when opening a season",
                    state: "closed",
                    htmlUrl: URL(string: "https://github.com/danilorequena/CinemaTV/issues/3")!
                ),
                kind: .bug,
                requesterName: nil,
                createdAt: .now
            )
        ])
    }
}

#Preview("My Requests — Empty") {
    NavigationStack {
        MyRequestsScreen(previewRequests: [])
    }
}
