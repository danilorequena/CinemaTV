//
//  SettingsScreen.swift
//  CinemaTV
//
//  Configurações do app, apresentada em sheet pela toolbar da Library.
//  Dona do toggle de notificações de estreia (pedido de permissão + sync);
//  a agenda de estreias vem de quem apresenta.
//

import SwiftUI
import WidgetKit
import CinemaTVCore
import CinemaTVDesignSystem

struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
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
                NavigationLink("Request a Feature") {
                    FeatureRequestScreen()
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
        SettingsScreen(notificationEntries: [])
    }
}
