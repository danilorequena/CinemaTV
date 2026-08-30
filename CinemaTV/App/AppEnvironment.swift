//
//  AppEnvironment.swift
//  CinemaTV
//
//  Injeção do TMDBClient via environment — sem singletons.
//

import SwiftUI
import CinemaTVCore

// Default estável (struct Sendable): criado uma vez, não invalida dependentes.
private let defaultTMDBClient = TMDBClient(
    configuration: (try? TMDBConfiguration.fromBundle(.main)) ?? TMDBConfiguration(apiKey: "")
)

/// Feedback via GitHub Issues: sem GitHub.plist (ou com placeholder),
/// vira somente leitura e a tela de request cai no e-mail.
private let defaultFeedbackClient = GitHubFeedbackClient(
    configuration: .fromBundle(.main)
)

/// Motor de IA (FoundationModels): stateless, roteia on-device vs Private
/// Cloud Compute por chamada — nenhum estado mutável no default.
private let defaultAgentEngine = AgentEngine()

/// Catálogo do Apple Music (MusicKit): busca de trilhas + hidratação de álbum.
private let defaultAppleMusicCatalog = AppleMusicCatalog()

extension EnvironmentValues {
    @Entry var tmdbClient: TMDBClient = defaultTMDBClient
    @Entry var feedbackClient: GitHubFeedbackClient = defaultFeedbackClient
    @Entry var agentEngine: AgentEngine = defaultAgentEngine
    @Entry var appleMusicCatalog: AppleMusicCatalog = defaultAppleMusicCatalog
}
/// Container único do processo — compartilhado entre o app e os App Intents
/// (o ModelContainer é caro; criar um por intent duplicaria stores).
enum AppContainer {
    static let shared = ModelContainerFactory.resilientShared()
}

