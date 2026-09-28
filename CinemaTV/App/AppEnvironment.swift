//
//  AppEnvironment.swift
//  CinemaTV
//
//  Injeção do TMDBClient via environment — sem singletons.
//

import SwiftUI
import SwiftData
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
    static let shared: ModelContainer = {
#if DEBUG
        // The Canvas launches the app before injecting its preview content.
        // Keep that launch independent of the personal CloudKit store as well.
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            return try! ModelContainerFactory.makeInMemory()
        }
        // A dedicated on-disk store lets UI tests relaunch without touching personal data.
        if let token = ProcessInfo.processInfo.environment["CINEMATV_UI_TEST_STORE"], let id = UUID(uuidString: token) {
            let url = FileManager.default.temporaryDirectory.appending(path: "boxes-ui-\(id.uuidString).store")
            let config = ModelConfiguration(schema: ModelContainerFactory.schema, url: url, cloudKitDatabase: .none)
            let container = try! ModelContainer(for: ModelContainerFactory.schema, configurations: config)
            if ProcessInfo.processInfo.environment["CINEMATV_UI_TEST_SEED_LIFETIME"] == "1" {
                MainActor.assumeIsolated {
                    let context = container.mainContext
                    let watchedAt = ISO8601DateFormatter().date(from: "2024-03-02T12:00:00Z")
                    context.insert(MoviesWatched(id: 603, name: "The Matrix", watchedAt: watchedAt))
                    let show = TVShowWatchingModel(id: 100, name: "A Long Story", firstAirDate: "2020-01-01", totalEpisodes: 2)
                    context.insert(show)
                    let season = SeasonSD(episodeCount: 2, seasonNumber: 1, tvShow: show)
                    context.insert(season)
                    context.insert(EpisodeSD(episodeNumber: 1, name: "Pilot", runtime: 45, seasonNumber: 1, showID: 100, watchedAt: watchedAt, season: season))
                    context.insert(MovieReview(movieID: 603, rating: 5, movieTitle: "The Matrix", updatedAt: watchedAt))
                    context.insert(LifetimeProfile(birthDateISO: "1990-05-14", updatedAt: watchedAt))
                    try! context.save()
                }
            }
            return container
        }
#endif
        CloudSyncDiagnostics.start()
        let result = ModelContainerFactory.makeResilientShared()
        CloudSyncDiagnostics.recordContainerResult(result)
        return result.container
    }()
}
