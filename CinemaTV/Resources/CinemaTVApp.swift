//
//  CinemaTVApp.swift
//  CinemaTV
//
//  Created by Danilo Requena on 07/11/21.
//

import SwiftUI
import SwiftData
import AppIntents
import CinemaTVCore
import CinemaTVDesignSystem

@main
struct CinemaTVApp: App {
    /// Container compartilhado (app group + CloudKit) do CinemaTVCore —
    /// o mesmo que widget e App Intents usam.
    private let container = AppContainer.shared
    // Sem valor na declaração: atribuído no init (regra da macro @State).
    @State private var router: AppRouter

    init() {
        let router = AppRouter()
        self.router = router
        // Intents de abertura (OpenMovie/OpenWatchlist) roteiam pelo mesmo
        // funil dos deep links.
        AppDependencyManager.shared.add(dependency: router)
    }

    var body: some Scene {
        WindowGroup {
            AppShellView()
                .environment(router)
                .dsImagePipeline()
                .defaultAppStorage(Self.appDefaults)
        }
        .modelContainer(container)
    }

    private static let appDefaults: UserDefaults = {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if let token = environment["CINEMATV_UI_TEST_STORE"],
           let id = UUID(uuidString: token),
           let defaults = UserDefaults(suiteName: "CinemaTV.UITests.\(id.uuidString)") {
            return defaults
        }
#endif
        return .standard
    }()
}
