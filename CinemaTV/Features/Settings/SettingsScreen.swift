//
//  SettingsScreen.swift
//  CinemaTV
//
//  Configurações do app, apresentada em sheet pela toolbar da Library.
//  Dona do toggle de notificações de estreia (pedido de permissão + sync);
//  a agenda de estreias vem de quem apresenta.
//

import SwiftUI
import SwiftData
import WidgetKit
import CloudKit
import CinemaTVCore
import CinemaTVDesignSystem

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.tmdbClient) private var tmdbClient
    @Bindable var traktIntegration: TraktIntegrationModel
    /// Mesma chave lida pela WatchlistScreen no re-sync do .task.
    @AppStorage("premiereNotificationsEnabled") private var premiereNotificationsEnabled = false
    /// Override de região do TMDB (App Group); vazio = automático (região do aparelho).
    @AppStorage(TMDBRegion.overrideKey, store: TMDBRegion.store) private var regionOverride = ""
    @AppStorage(CloudSyncDiagnostics.modeKey) private var cloudStoreMode = ""
    @AppStorage(CloudSyncDiagnostics.startupErrorKey) private var cloudStartupError = ""
    @AppStorage(CloudSyncDiagnostics.lastSetupKey) private var lastCloudSetup = 0.0
    @AppStorage(CloudSyncDiagnostics.lastImportKey) private var lastCloudImport = 0.0
    @AppStorage(CloudSyncDiagnostics.lastExportKey) private var lastCloudExport = 0.0
    @AppStorage(CloudSyncDiagnostics.lastErrorKey) private var lastCloudError = ""
    @AppStorage(CloudSyncDiagnostics.lastErrorDateKey) private var lastCloudErrorDate = 0.0
    @State private var cloudAccountStatus: CKAccountStatus?
    @State private var cloudAccountError = ""

    /// Agenda atual de estreias, para (re)agendar ao mexer no toggle.
    let notificationEntries: [PremiereNotifications.Entry]

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $premiereNotificationsEnabled) {
                    Text("Premiere notifications")
                }
                .tint(DSColor.accent)
            } header: {
                Text("Notifications")
            } footer: {
                Text("Get notified on release day for shows and movies in your library.")
            }

            Section {
                Picker("Content region", selection: $regionOverride) {
                    Text("Automatic (\(TMDBRegion.localizedName(for: TMDBRegion.deviceDefault)))")
                        .tag("")
                    ForEach(TMDBRegion.selectableRegions, id: \.self) { code in
                        Text(TMDBRegion.localizedName(for: code)).tag(code)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Region")
            } footer: {
                Text("Affects release dates, what's in theaters, and where to watch.")
            }

            Section {
                LabeledContent("Library storage", value: cloudStoreLabel)
                LabeledContent("iCloud account", value: cloudAccountLabel)

                if cloudStoreMode == "cloudKit", lastCloudSetup > 0 {
                    LabeledContent("Last iCloud setup", value: cloudDate(lastCloudSetup))
                }
                if cloudStoreMode == "cloudKit", lastCloudExport > 0 {
                    LabeledContent("Last observed upload", value: cloudDate(lastCloudExport))
                }
                if cloudStoreMode == "cloudKit", lastCloudImport > 0 {
                    LabeledContent("Last observed download", value: cloudDate(lastCloudImport))
                }

                if cloudStoreMode == "local" {
                    Text("iCloud did not start. Changes saved on this iPhone are currently local.")
                        .foregroundStyle(.orange)
                } else if cloudStoreMode == "memory" {
                    Text("The library could not be opened. Changes may disappear when the app closes.")
                        .foregroundStyle(.red)
                } else if cloudStoreMode == "cloudKit", lastCloudSetup == 0,
                          lastCloudImport == 0, lastCloudExport == 0 {
                    Text("Waiting for iCloud activity.")
                        .foregroundStyle(.secondary)
                }

                if !cloudStartupError.isEmpty {
                    Text("Storage error: \(cloudStartupError)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                if !cloudAccountError.isEmpty {
                    Text("Account error: \(cloudAccountError)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
                if cloudStoreMode == "cloudKit", !lastCloudError.isEmpty {
                    Text("Sync error\(lastCloudErrorDate > 0 ? " (\(cloudDate(lastCloudErrorDate)))" : ""): \(lastCloudError)")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                Button("Check iCloud Account Again") {
                    Task { await refreshCloudAccount() }
                }
            } header: {
                Text("iCloud Sync")
            } footer: {
                Text("An available account does not mean your library has finished syncing. Both iPhones need the same Apple Account. Xcode builds and TestFlight/App Store builds use separate iCloud databases.")
            }

            Section {
                switch traktIntegration.state {
                case .unavailable:
                    LabeledContent("Trakt", value: "Not configured")
                    Text("Add valid Trakt credentials to Trakt.plist to enable this integration.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                case .disconnected:
                    Button("Connect to Trakt") {
                        Task {
                            await traktIntegration.connect(
                                tmdb: tmdbClient,
                                context: modelContext
                            )
                        }
                    }
                case .connecting:
                    LabeledContent("Trakt", value: "Connecting…")
                    ProgressView()
                case .syncing:
                    LabeledContent("Trakt", value: "Importing…")
                    ProgressView()
                case .connected(let username):
                    LabeledContent("Account", value: username ?? "Connected")
                    if let lastSyncAt = traktIntegration.lastSyncAt {
                        LabeledContent(
                            "Last sync",
                            value: lastSyncAt.formatted(date: .abbreviated, time: .shortened)
                        )
                    }
                    if let result = traktIntegration.lastResult {
                        Text("\(result.importedMovies) movies, \(result.importedShows) shows, and \(result.importedEpisodes) episodes processed.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Button("Sync Now") {
                        Task {
                            await traktIntegration.sync(
                                tmdb: tmdbClient,
                                context: modelContext
                            )
                        }
                    }
                    Button("Disconnect", role: .destructive) {
                        traktIntegration.disconnect()
                    }
                case .failed(let message):
                    Text(message)
                        .foregroundStyle(.red)
                    if traktIntegration.isConnected {
                        Button("Try Again") {
                            Task {
                                await traktIntegration.sync(
                                    tmdb: tmdbClient,
                                    context: modelContext
                                )
                            }
                        }
                        Button("Disconnect", role: .destructive) {
                            traktIntegration.disconnect()
                        }
                    } else {
                        Button("Connect Again") {
                            Task {
                                await traktIntegration.connect(
                                    tmdb: tmdbClient,
                                    context: modelContext
                                )
                            }
                        }
                    }
                }
            } header: {
                Text("Trakt")
            } footer: {
                Text("Optional. Imports your Trakt watchlist and watched progress without removing local activity or sending CinemaTV changes back to Trakt.")
            }

            AppleIntelligenceSection()

            Section {
                NavigationLink("What's New") {
                    ChangelogScreen()
                }
                NavigationLink("Coming Soon") {
                    BacklogScreen()
                }
            } header: {
                Text("Updates")
            } footer: {
                Text("See what shipped recently and what's next.")
            }

            Section {
                NavigationLink("Request a Feature") {
                    FeatureRequestScreen()
                }
                NavigationLink("My Requests") {
                    MyRequestsScreen()
                }
            } header: {
                Text("Feedback")
            } footer: {
                Text("Tell us what you'd like to see in CinemaTV.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .onChange(of: premiereNotificationsEnabled) { _, enabled in
            Task {
                if enabled {
                    guard await PremiereNotifications.requestAuthorization() else {
                        // Permissão negada: o toggle volta a refletir a verdade.
                        premiereNotificationsEnabled = false
                        return
                    }
                }
                await PremiereNotifications.sync(
                    enabled: premiereNotificationsEnabled,
                    entries: notificationEntries
                )
            }
        }
        .task { await refreshCloudAccount() }
    }

    private var cloudStoreLabel: String {
        switch cloudStoreMode {
        case "cloudKit": "iCloud configured"
        case "local": "Only on this iPhone"
        case "memory": "Temporary"
        default: "Checking…"
        }
    }

    private var cloudAccountLabel: String {
        if !cloudAccountError.isEmpty { return "Could not check" }
        guard let cloudAccountStatus else { return "Checking…" }
        switch cloudAccountStatus {
        case .available: return "Available"
        case .noAccount: return "Not signed in"
        case .restricted: return "Restricted"
        case .temporarilyUnavailable: return "Temporarily unavailable"
        case .couldNotDetermine: return "Could not determine"
        @unknown default: return "Unknown"
        }
    }

    private func cloudDate(_ timestamp: Double) -> String {
        Date(timeIntervalSince1970: timestamp).formatted(date: .abbreviated, time: .shortened)
    }

    @MainActor
    private func refreshCloudAccount() async {
#if DEBUG
        // Isolated UI tests and previews do not carry a CloudKit entitlement.
        // CKContainer(identifier:) traps before accountStatus() can throw.
        if ProcessInfo.processInfo.environment["CINEMATV_UI_TEST_STORE"] != nil
            || ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            cloudAccountStatus = .couldNotDetermine
            cloudAccountError = ""
            return
        }
#endif
        do {
            cloudAccountStatus = try await CKContainer(
                identifier: ModelContainerFactory.cloudKitContainerID
            ).accountStatus()
            cloudAccountError = ""
        } catch {
            cloudAccountStatus = nil
            cloudAccountError = error.localizedDescription
        }
    }
}

#Preview {
    NavigationStack {
        SettingsScreen(
            traktIntegration: TraktIntegrationModel(),
            notificationEntries: []
        )
    }
}
