import AuthenticationServices
import Foundation
import Observation
import Security
import SwiftData
import CinemaTVCore

struct TraktCredentials: Codable, Sendable {
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case createdAt = "created_at"
    }

    init(accessToken: String, refreshToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
        let expiresIn = try values.decode(TimeInterval.self, forKey: .expiresIn)
        let createdAt = try values.decodeIfPresent(TimeInterval.self, forKey: .createdAt)
            ?? Date.now.timeIntervalSince1970
        expiresAt = Date(timeIntervalSince1970: createdAt + expiresIn)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(accessToken, forKey: .accessToken)
        try values.encode(refreshToken, forKey: .refreshToken)
        try values.encode(expiresAt.timeIntervalSinceNow, forKey: .expiresIn)
        try values.encode(Date.now.timeIntervalSince1970, forKey: .createdAt)
    }
}

enum TraktCredentialStore {
    private static let service = "com.danilorequena.CinemaTV.trakt"
    private static let account = "oauth"

    static func load() -> TraktCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return try? JSONDecoder().decode(TraktCredentials.self, from: data)
    }

    static func save(_ credentials: TraktCredentials) throws {
        let data = try JSONEncoder().encode(credentials)
        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let status = SecItemUpdate(identity as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var insertion = identity
            attributes.forEach { insertion[$0.key] = $0.value }
            guard SecItemAdd(insertion as CFDictionary, nil) == errSecSuccess else {
                throw CocoaError(.fileWriteUnknown)
            }
        } else if status != errSecSuccess {
            throw CocoaError(.fileWriteUnknown)
        }
    }

    static func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

struct TraktSyncResult: Sendable {
    var importedMovies = 0
    var importedShows = 0
    var importedEpisodes = 0
    var skippedWithoutTMDBID = 0
}

@MainActor
@Observable
final class TraktIntegrationModel: NSObject {
    enum State: Equatable {
        case unavailable
        case disconnected
        case connecting
        case syncing
        case connected(username: String?)
        case failed(message: String)
    }

    private(set) var state: State
    private(set) var lastResult: TraktSyncResult?
    private(set) var lastSyncAt: Date?
    private var webSession: ASWebAuthenticationSession?
    private let configuration: TraktConfiguration?

    var isConnected: Bool {
        TraktCredentialStore.load() != nil
    }

    override init() {
        configuration = TraktConfiguration.fromBundle()
        lastSyncAt = UserDefaults.standard.object(forKey: "traktLastSyncAt") as? Date
        if configuration == nil {
            state = .unavailable
        } else if TraktCredentialStore.load() != nil {
            state = .connected(username: UserDefaults.standard.string(forKey: "traktUsername"))
        } else {
            state = .disconnected
        }
        super.init()
    }

    func connect(tmdb: TMDBClient, context: ModelContext) async {
        guard let configuration else {
            state = .unavailable
            return
        }
        state = .connecting
        do {
            let code = try await authorize(configuration: configuration)
            let credentials = try await exchange(
                configuration: configuration,
                values: [
                    "code": code,
                    "client_id": configuration.clientID,
                    "client_secret": configuration.clientSecret,
                    "redirect_uri": configuration.redirectURI,
                    "grant_type": "authorization_code"
                ]
            )
            try TraktCredentialStore.save(credentials)
            let client = TraktClient(configuration: configuration)
            let settings: TraktUserSettings = try await client.fetch(
                .userSettings,
                accessToken: credentials.accessToken
            )
            let username = settings.user.username ?? settings.user.name
            UserDefaults.standard.set(username, forKey: "traktUsername")
            state = .connected(username: username)
            await sync(tmdb: tmdb, context: context)
        } catch is CancellationError {
            state = .disconnected
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func sync(tmdb: TMDBClient, context: ModelContext) async {
        guard let configuration else {
            state = .unavailable
            return
        }
        state = .syncing
        do {
            let credentials = try await validCredentials(configuration: configuration)
            let result = try await importLibrary(
                client: TraktClient(configuration: configuration),
                accessToken: credentials.accessToken,
                tmdb: tmdb,
                context: context
            )
            lastResult = result
            lastSyncAt = .now
            UserDefaults.standard.set(lastSyncAt, forKey: "traktLastSyncAt")
            state = .connected(username: UserDefaults.standard.string(forKey: "traktUsername"))
        } catch {
            state = .failed(message: error.localizedDescription)
        }
    }

    func syncIfNeeded(tmdb: TMDBClient, context: ModelContext) async {
        guard isConnected else { return }
        if let lastSyncAt, Date.now.timeIntervalSince(lastSyncAt) < 24 * 60 * 60 {
            return
        }
        await sync(tmdb: tmdb, context: context)
    }

    func disconnect() {
        webSession?.cancel()
        webSession = nil
        TraktCredentialStore.delete()
        UserDefaults.standard.removeObject(forKey: "traktUsername")
        UserDefaults.standard.removeObject(forKey: "traktLastSyncAt")
        lastSyncAt = nil
        lastResult = nil
        state = configuration == nil ? .unavailable : .disconnected
    }

    private func authorize(configuration: TraktConfiguration) async throws -> String {
        let stateToken = UUID().uuidString
        guard var components = URLComponents(
            url: configuration.authBaseURL.appending(path: "authorize"),
            resolvingAgainstBaseURL: false
        ) else { throw TraktError.invalidURL }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "state", value: stateToken)
        ]
        guard let url = components.url,
              let callbackScheme = URL(string: configuration.redirectURI)?.scheme
        else { throw TraktError.invalidURL }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { callback, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callback,
                      let values = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems,
                      values.first(where: { $0.name == "state" })?.value == stateToken,
                      let code = values.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: TraktError.unauthorized)
                    return
                }
                continuation.resume(returning: code)
            }
            session.prefersEphemeralWebBrowserSession = false
            self.webSession = session
            guard session.start() else {
                continuation.resume(throwing: TraktError.unauthorized)
                return
            }
        }
    }

    private func validCredentials(configuration: TraktConfiguration) async throws -> TraktCredentials {
        guard let credentials = TraktCredentialStore.load() else {
            throw TraktError.unauthorized
        }
        guard credentials.expiresAt.timeIntervalSinceNow < 60 else {
            return credentials
        }
        let refreshed = try await exchange(
            configuration: configuration,
            values: [
                "refresh_token": credentials.refreshToken,
                "client_id": configuration.clientID,
                "client_secret": configuration.clientSecret,
                "redirect_uri": configuration.redirectURI,
                "grant_type": "refresh_token"
            ]
        )
        // O refresh token do Trakt é single-use: ambos são substituídos juntos.
        try TraktCredentialStore.save(refreshed)
        return refreshed
    }

    private func exchange(
        configuration: TraktConfiguration,
        values: [String: String]
    ) async throws -> TraktCredentials {
        guard let url = URL(string: "https://auth.trakt.tv/oauth/token") else {
            throw TraktError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(values)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw TraktError.unauthorized
        }
        return try JSONDecoder().decode(TraktCredentials.self, from: data)
    }

    private func importLibrary(
        client: TraktClient,
        accessToken: String,
        tmdb: TMDBClient,
        context: ModelContext
    ) async throws -> TraktSyncResult {
        let movieWatchlist: [TraktWatchlistItem] = try await client.fetchAll(
            .watchlistMovies,
            accessToken: accessToken
        )
        let watchedMovies: [TraktWatchedMovie] = try await client.fetchAll(
            .watchedMovies,
            accessToken: accessToken
        )
        let showWatchlist: [TraktWatchlistItem] = try await client.fetchAll(
            .watchlistShows,
            accessToken: accessToken
        )
        let watchedShows: [TraktWatchedShow] = try await client.fetchAll(
            .watchedShows,
            accessToken: accessToken,
            limit: 100
        )

        var result = TraktSyncResult()
        let movieIDs = Set(movieWatchlist.compactMap(\.canonicalTMDBID))
            .union(watchedMovies.compactMap { $0.movie.ids.tmdb })
        var movieDetails: [Int: MovieDetails] = [:]
        for id in movieIDs {
            movieDetails[id] = try await tmdb.fetch(.movieDetail(id: id))
        }

        var showIDs = Set(showWatchlist.compactMap(\.canonicalTMDBID))
        showIDs.formUnion(watchedShows.compactMap { $0.show.ids.tmdb })
        var showDetails: [Int: TVShowDetails] = [:]
        for id in showIDs {
            showDetails[id] = try await tmdb.fetch(.tvShowDetail(id: id))
        }

        // Toda a rede termina antes da primeira mutação local. Assim uma falha
        // de página ou hidratação não deixa uma importação parcial.
        var seasonDetails: [String: SeasonDetails] = [:]
        for remote in watchedShows {
            guard let showID = remote.show.ids.tmdb else { continue }
            for season in remote.seasons ?? [] where season.number > 0 {
                let key = "\(showID)-\(season.number)"
                seasonDetails[key] = try await tmdb.fetch(
                    .tvShowSeason(id: showID, season: season.number)
                )
            }
        }
        try Task.checkCancellation()

        let movieStore = WatchlistStore(context: context)
        for remote in movieWatchlist {
            guard let id = remote.canonicalTMDBID,
                  let details = movieDetails[id]
            else {
                result.skippedWithoutTMDBID += 1
                continue
            }
            try movieStore.importToWatchlist(details.mediaItem, listedAt: remote.listedAt)
            result.importedMovies += 1
        }
        for remote in watchedMovies {
            guard let id = remote.movie.ids.tmdb,
                  let details = movieDetails[id]
            else {
                result.skippedWithoutTMDBID += 1
                continue
            }
            try movieStore.importWatched(details.mediaItem, watchedAt: remote.lastWatchedAt)
            result.importedMovies += 1
        }

        let trackingStore = TVShowTrackingStore(context: context)
        result.skippedWithoutTMDBID += showWatchlist.filter { $0.canonicalTMDBID == nil }.count
        result.skippedWithoutTMDBID += watchedShows.filter { $0.show.ids.tmdb == nil }.count
        for id in showIDs {
            guard let details = showDetails[id] else { continue }
            if trackingStore.isFollowing(showID: id) {
                try trackingStore.refreshMetadata(from: details)
            } else {
                try trackingStore.follow(details)
            }
            result.importedShows += 1
        }

        for remote in watchedShows {
            guard let showID = remote.show.ids.tmdb else { continue }
            for season in remote.seasons ?? [] where season.number > 0 {
                let key = "\(showID)-\(season.number)"
                guard let details = seasonDetails[key] else { continue }
                let watchedByNumber = Dictionary(
                    uniqueKeysWithValues: season.episodes.map { ($0.number, $0) }
                )
                for episode in details.episodes {
                    guard let remoteEpisode = watchedByNumber[episode.episodeNumber] else { continue }
                    try trackingStore.importEpisodeWatched(
                        episode,
                        showID: showID,
                        watchedAt: remoteEpisode.completedAt ?? remoteEpisode.lastWatchedAt
                    )
                    result.importedEpisodes += 1
                }
            }
        }
        return result
    }
}
