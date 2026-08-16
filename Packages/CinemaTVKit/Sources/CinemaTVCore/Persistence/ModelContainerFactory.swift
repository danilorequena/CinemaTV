//
//  ModelContainerFactory.swift
//  CinemaTVKit
//
//  Único ponto de criação do ModelContainer — usado pelo app, widget e
//  AppDependencyManager (intents). Store no app group para que todos os
//  processos leiam os mesmos dados.
//

import Foundation
import SwiftData

public enum ModelContainerFactory {
    public static let appGroupID = "group.com.danilorequena.CinemaTV"

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
            cloudKitDatabase: .automatic
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// makeShared com degradação graciosa: sem CloudKit disponível (ex.:
    /// simulador sem conta) cai para store local no app group; em último
    /// caso, in-memory para o app nunca deixar de abrir.
    public static func resilientShared() -> ModelContainer {
        if let shared = try? makeShared() {
            return shared
        }
        if let url = try? storeURL(),
           let local = try? ModelContainer(
               for: schema,
               configurations: [ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)]
           ) {
            return local
        }
        return try! makeInMemory()
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
}
