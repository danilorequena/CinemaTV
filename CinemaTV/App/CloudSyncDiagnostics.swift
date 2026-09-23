//
//  CloudSyncDiagnostics.swift
//  CinemaTV
//
//  Records the persistent-store mode and the asynchronous CloudKit events.
//  Opening a ModelContainer only proves that the local store opened; imports
//  and exports can fail later, so keep those outcomes visible in Settings.
//

import CloudKit
import CoreData
import Foundation
import OSLog
import CinemaTVCore

enum CloudSyncDiagnostics {
    static let modeKey = "cloudSync.storeMode"
    static let startupErrorKey = "cloudSync.startupError"
    static let lastSetupKey = "cloudSync.lastSetup"
    static let lastImportKey = "cloudSync.lastImport"
    static let lastExportKey = "cloudSync.lastExport"
    static let lastErrorKey = "cloudSync.lastError"
    static let lastErrorDateKey = "cloudSync.lastErrorDate"
    static let lastErrorKindKey = "cloudSync.lastErrorKind"

    private static let logger = Logger(subsystem: "com.danilorequena.CinemaTV", category: "CloudKit")

    // The notification can arrive after ModelContainer initialization returns.
    // Register before opening the store so setup failures are captured as well.
    private static let isObserving: Bool = {
        _ = NotificationCenter.default.addObserver(
            forName: NSPersistentCloudKitContainer.eventChangedNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard let event = notification.userInfo?[
                NSPersistentCloudKitContainer.eventNotificationUserInfoKey
            ] as? NSPersistentCloudKitContainer.Event else { return }
            record(event)
        }
        return true
    }()

    static func start() {
        // A failure from an earlier launch may already have recovered. Report
        // errors observed by this process, while keeping dated successes.
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: lastErrorKey)
        defaults.removeObject(forKey: lastErrorDateKey)
        defaults.removeObject(forKey: lastErrorKindKey)
        _ = isObserving
    }

    static func recordContainerResult(_ result: SharedContainerResult) {
        let mode: String
        switch result.mode {
        case .cloudKit: mode = "cloudKit"
        case .local: mode = "local"
        case .memory: mode = "memory"
        }

        let defaults = UserDefaults.standard
        defaults.set(mode, forKey: modeKey)
        defaults.set(result.errorDescription ?? "", forKey: startupErrorKey)
        if mode != "cloudKit" {
            logger.error("Shared store opened in \(mode, privacy: .public) mode: \(result.errorDescription ?? "Unknown error")")
        }
    }

    private static func record(_ event: NSPersistentCloudKitContainer.Event) {
        guard let endDate = event.endDate else { return }

        let kind: String
        let successKey: String
        switch event.type {
        case .setup:
            kind = "setup"
            successKey = lastSetupKey
        case .import:
            kind = "import"
            successKey = lastImportKey
        case .export:
            kind = "export"
            successKey = lastExportKey
        @unknown default:
            return
        }

        let defaults = UserDefaults.standard
        if event.succeeded {
            defaults.set(endDate.timeIntervalSince1970, forKey: successKey)
            if defaults.string(forKey: lastErrorKindKey) == kind {
                defaults.removeObject(forKey: lastErrorKey)
                defaults.removeObject(forKey: lastErrorDateKey)
                defaults.removeObject(forKey: lastErrorKindKey)
            }
            logger.info("CloudKit \(kind, privacy: .public) completed")
        } else {
            let message: String
            if let error = event.error as NSError? {
                message = "\(error.domain) (\(error.code)): \(error.localizedDescription)"
            } else {
                message = "CloudKit operation failed."
            }
            defaults.set(message, forKey: lastErrorKey)
            defaults.set(endDate.timeIntervalSince1970, forKey: lastErrorDateKey)
            defaults.set(kind, forKey: lastErrorKindKey)
            logger.error("CloudKit \(kind, privacy: .public) failed: \(message)")
        }
    }
}
