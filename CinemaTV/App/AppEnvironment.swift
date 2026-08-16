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

extension EnvironmentValues {
    @Entry var tmdbClient: TMDBClient = defaultTMDBClient
}
/// Container único do processo — compartilhado entre o app e os App Intents
/// (o ModelContainer é caro; criar um por intent duplicaria stores).
enum AppContainer {
    static let shared = ModelContainerFactory.resilientShared()
}

