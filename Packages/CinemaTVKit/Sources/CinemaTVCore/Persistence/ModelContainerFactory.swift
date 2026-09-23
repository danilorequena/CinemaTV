//
//  ModelContainerFactory.swift
//  CinemaTVKit
//
//  Único ponto de criação do ModelContainer — usado pelo app, widget e
//  AppDependencyManager (intents). Store no app group para que todos os
//  processos leiam os mesmos dados.
//

import Foundation
import OSLog
import SwiftData

public enum SharedContainerMode: String, Sendable {
    case cloudKit
    case local
    case memory
}

public struct SharedContainerResult: Sendable {
    public let container: ModelContainer
    public let mode: SharedContainerMode
    public let errorDescription: String?
}

public enum ModelContainerFactory {
    public static let appGroupID = "group.com.danilorequena.CinemaTV"
    public static let cloudKitContainerID = "iCloud.com.danilorequena.CinemaTV"

    private static let logger = Logger(
        subsystem: "com.danilorequena.CinemaTV",
        category: "ModelContainer"
    )

    public static let schema = Schema([
        MoviesToWatch.self,
        MoviesWatched.self,
        TVShowWatchingModel.self,
        TVShowWatchedModel.self,
        SeasonSD.self,
        EpisodeSD.self,
        MovieReview.self
    ])

    /// Container compartilhado (app group + CloudKit).
    public static func makeShared() throws -> ModelContainer {
        let storeURL = try storeURL()
        migrateLegacyStoreIfNeeded(to: storeURL)

        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Container local do app group para extensões sem entitlement de CloudKit.
    public static func makeLocalShared() throws -> ModelContainer {
        let storeURL = try storeURL()
        migrateLegacyStoreIfNeeded(to: storeURL)

        let configuration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// Abre o container compartilhado e informa se o processo precisou
    /// desativar o CloudKit ou, em último caso, usar armazenamento em memória.
    public static func makeResilientShared() -> SharedContainerResult {
        do {
            let container = try makeShared()
            return SharedContainerResult(container: container, mode: .cloudKit, errorDescription: nil)
        } catch {
            let originalError = errorDescription(for: error)
            logger.error("CloudKit container failed to open; falling back to the local app-group store. Error: \(originalError)")

            do {
                let container = try makeLocalShared()
                return SharedContainerResult(
                    container: container,
                    mode: .local,
                    errorDescription: originalError
                )
            } catch {
                let localError = errorDescription(for: error)
                logger.fault("Local app-group store failed to open; falling back to an in-memory store. Error: \(localError)")

                do {
                    let container = try makeInMemory()
                    return SharedContainerResult(
                        container: container,
                        mode: .memory,
                        errorDescription: "CloudKit: \(originalError). Local store: \(localError)"
                    )
                } catch {
                    let memoryError = errorDescription(for: error)
                    logger.fault("In-memory store failed to open. Error: \(memoryError)")
                    fatalError("Unable to create any CinemaTV model container: \(memoryError)")
                }
            }
        }
    }

    /// Compatibility wrapper for callers that only need the container.
    public static func resilientShared() -> ModelContainer {
        makeResilientShared().container
    }

    /// Container efêmero para testes e previews.
    public static func makeInMemory() throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func storeURL() throws -> URL {
        guard let container = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            throw CocoaError(.fileNoSuchFile)
        }
        return container.appending(path: "CinemaTV.store")
    }

    /// Copia o store legado (Application Support/default.store) para o app
    /// group no primeiro launch pós-migração, preservando dados locais de quem
    /// não usa iCloud. Roda uma única vez: no-op se o destino já existe.
    static func migrateLegacyStoreIfNeeded(to destination: URL) {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: destination.path) else { return }

        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let legacy = appSupport.appending(path: "default.store")
        guard fm.fileExists(atPath: legacy.path) else { return }

        for suffix in ["", "-shm", "-wal"] {
            let source = URL(filePath: legacy.path + suffix)
            let target = URL(filePath: destination.path + suffix)
            guard fm.fileExists(atPath: source.path) else { continue }
            try? fm.copyItem(at: source, to: target)
        }
    }

    private static func errorDescription(for error: any Error) -> String {
        let error = error as NSError
        return "\(error.domain) (\(error.code)): \(error.localizedDescription)"
    }
}
