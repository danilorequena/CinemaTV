//
//  PremiereNotifications.swift
//  CinemaTV
//
//  Notificações locais de estreia: uma por item da agenda Up Next, às 9h
//  locais do dia da estreia. A cada sincronização os pedidos pendentes com
//  prefixo "premiere-" são reconstruídos do zero (fonte de verdade = agenda).
//

import Foundation
import UserNotifications

@MainActor
enum PremiereNotifications {
    struct Entry {
        let id: String
        let title: String
        let body: String
        /// Meia-noite GMT do dia da estreia (mesma convenção da agenda).
        let date: Date
    }

    private static let identifierPrefix = "premiere-"

    /// Pede permissão; false = negado (o toggle deve voltar a off).
    static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// Reconstrói os agendamentos a partir da agenda atual.
    static func sync(enabled: Bool, entries: [Entry]) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pending)

        guard enabled else { return }

        // O dia vem do calendário GMT (a data ISO do TMDB vive em meia-noite
        // UTC); o gatilho dispara às 9h no fuso LOCAL desse dia.
        var gmtCalendar = Calendar(identifier: .gregorian)
        gmtCalendar.timeZone = .gmt

        for entry in entries {
            var components = gmtCalendar.dateComponents([.year, .month, .day], from: entry.date)
            components.calendar = nil
            components.timeZone = nil
            components.hour = 9

            let content = UNMutableNotificationContent()
            content.title = entry.title
            content.body = entry.body
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: identifierPrefix + entry.id,
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            )
            try? await center.add(request)
        }
    }
}
