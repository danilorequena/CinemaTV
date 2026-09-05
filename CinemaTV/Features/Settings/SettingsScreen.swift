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
