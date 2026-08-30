//
//  RoadmapScreens.swift
//  CinemaTV
//
//  What's New (changelog por versão, com créditos) alimentada pelo
//  AppRoadmap estático; Coming Soon (backlog curado) vem das issues
//  abertas na milestone "Backlog" do GitHub — o que você marca lá é o
//  que aparece aqui. Rows planas: glass fica só em controle interativo.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct ChangelogScreen: View {
    var releases: [ChangelogRelease] = AppRoadmap.releases

    var body: some View {
        Group {
            if releases.isEmpty {
                EmptyStateView(
                    title: "No Updates Yet",
                    message: "Release notes will appear here.",
                    systemImage: "sparkles"
                )
            } else {
                List {
                    ForEach(releases) { release in
                        Section {
                            ForEach(release.entries) { entry in
                                RoadmapEntryRow(
                                    kind: entry.kind,
                                    text: entry.text,
                                    credit: entry.credit
                                )
                            }
                        } header: {
                            HStack {
                                Text("Version \(release.version)")
                                Spacer()
                                Text(release.date, format: .dateTime.month(.wide).year())
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("What's New")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BacklogScreen: View {
    @Environment(\.feedbackClient) private var feedbackClient
    /// Injeção para previews — pula a rede.
    var previewIssues: [FeedbackIssue]?

    @State private var loadState: LoadState<[FeedbackIssue]> = .idle

    var body: some View {
        Group {
            switch loadState {
            case .idle, .loading:
                LoadingStateView { skeleton }
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await load(force: true) }
                }
            case .loaded(let issues):
                if issues.isEmpty {
                    EmptyStateView(
                        title: "Nothing Planned Yet",
                        message: "Accepted suggestions will appear here.",
                        systemImage: "hourglass"
                    )
                } else {
                    list(issues)
                }
            }
        }
        .navigationTitle("Coming Soon")
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func list(_ issues: [FeedbackIssue]) -> some View {
        List {
            Section {
                ForEach(issues) { issue in
                    RoadmapEntryRow(
                        kind: issue.kind,
                        text: issue.title,
                        credit: issue.credit
                    )
                }
            } footer: {
                Text("These ideas came from people like you. Have one? Request a feature from Settings.")
            }
        }
    }

    private var skeleton: some View {
        List {
            ForEach(0..<3, id: \.self) { _ in
                RoadmapEntryRow(
                    kind: .feature,
                    text: "Placeholder backlog item text",
                    credit: "placeholder"
                )
            }
        }
    }

    private func load(force: Bool = false) async {
        if let previewIssues {
            loadState = .loaded(previewIssues)
            return
        }
        if case .loaded = loadState, !force { return }
        loadState = .loading
        do {
            loadState = .loaded(try await feedbackClient.fetchBacklog())
        } catch {
            loadState = .failed(String(localized: "Couldn't load what's coming. Check your connection."))
        }
    }
}

/// Row plana compartilhada: ícone da categoria + texto + crédito.
private struct RoadmapEntryRow: View {
    let kind: SuggestionKind
    let text: String
    let credit: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.md) {
            Image(systemName: kind.symbolName)
                .foregroundStyle(DSColor.accent)
                .frame(width: 24)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                // Texto já resolvido no catálogo do Core — verbatim evita
                // segunda resolução no catálogo do app.
                Text(verbatim: text)
                if let credit {
                    // Nome interpola verbatim; o scaffold "Suggested by %@"
                    // continua traduzível com a ordem certa em pt-BR.
                    Text("Suggested by \(credit)")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("What's New") {
    NavigationStack {
        ChangelogScreen()
    }
}

#Preview("Coming Soon") {
    NavigationStack {
        BacklogScreen(previewIssues: [
            FeedbackIssue(
                number: 1,
                title: "Home Screen widgets for your watchlist",
                state: "open",
                body: "From: @moviebuff",
                htmlUrl: URL(string: "https://github.com/danilorequena/CinemaTV/issues/1")!
            ),
            FeedbackIssue(
                number: 2,
                title: "Faster iCloud sync for large libraries",
                state: "open",
                labels: [.init(name: "improvement")],
                htmlUrl: URL(string: "https://github.com/danilorequena/CinemaTV/issues/2")!
            )
        ])
    }
}

#Preview("Coming Soon — Empty") {
    NavigationStack {
        BacklogScreen(previewIssues: [])
    }
}
