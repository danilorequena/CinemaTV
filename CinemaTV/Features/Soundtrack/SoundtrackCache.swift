//
//  SoundtrackCache.swift
//  CinemaTV
//
//  Cache local do veredito de trilha por título (TMDB id): evita re-rodar
//  busca + LLM a cada visita à tela. UserDefaults + Codable de propósito —
//  o ModelContainer do app sincroniza via CloudKit e um cache local não
//  justifica migração de schema.
//

import Foundation

struct SoundtrackCache: Sendable {
    struct Entry: Codable, Sendable, Equatable {
        /// nil = cache negativo ("não existe trilha para este título").
        var albumID: String?
        var about: String?
        /// Storefront em que o veredito foi feito; mudou de país, invalida.
        var storefront: String?
        var savedAt: Date
    }

    static let timeToLive: TimeInterval = 30 * 24 * 60 * 60

    /// Suite injetável para testes; nil = UserDefaults.standard.
    private let suiteName: String?

    init(suiteName: String? = nil) {
        self.suiteName = suiteName
    }

    private var defaults: UserDefaults {
        suiteName.flatMap(UserDefaults.init(suiteName:)) ?? .standard
    }

    func entry(
        kind: SoundtrackFinder.MediaKind,
        tmdbID: Int,
        storefront: String?,
        now: Date = .now
    ) -> Entry? {
        guard let data = defaults.data(forKey: Self.key(kind: kind, tmdbID: tmdbID)),
              let entry = try? JSONDecoder().decode(Entry.self, from: data),
              Self.isFresh(entry, storefront: storefront, now: now)
        else { return nil }
        return entry
    }

    func store(_ entry: Entry, kind: SoundtrackFinder.MediaKind, tmdbID: Int) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        defaults.set(data, forKey: Self.key(kind: kind, tmdbID: tmdbID))
    }

    func remove(kind: SoundtrackFinder.MediaKind, tmdbID: Int) {
        defaults.removeObject(forKey: Self.key(kind: kind, tmdbID: tmdbID))
    }

    /// Regra de frescor pura (testável sem UserDefaults).
    static func isFresh(_ entry: Entry, storefront: String?, now: Date) -> Bool {
        guard now.timeIntervalSince(entry.savedAt) < timeToLive else { return false }
        // Storefront desconhecido de um dos lados não invalida.
        if let cached = entry.storefront, let current = storefront, cached != current {
            return false
        }
        return true
    }

    static func key(kind: SoundtrackFinder.MediaKind, tmdbID: Int) -> String {
        // v2: entradas v1 podiam ter cache negativo gravado a partir de ERRO
        // de busca (bug corrigido) — a troca de versão as descarta.
        "soundtrack.v2.\(kind.rawValue).\(tmdbID)"
    }
}
