import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

enum BoxContentFactory {
    /// The catalog picker filters people before offering this action.
    static func media(_ item: MediaItem) -> BoxContent {
        BoxContent(
            kind: item.mediaType == .tvShow ? .series : .movie,
            title: item.title,
            subtitle: [item.mediaType == .tvShow ? String(localized: "TV Show") : String(localized: "Movie"), item.releaseYear].compactMap { $0 }.joined(separator: " · "),
            mediaID: item.id,
            seriesID: item.mediaType == .tvShow ? item.id : nil,
            posterPath: item.posterPath
        )
    }

    static func season(_ season: SeasonSummary, in show: MediaItem) -> BoxContent {
        BoxContent(kind: .season, title: season.name, subtitle: show.title, mediaID: season.id, seriesID: show.id, seasonNumber: season.seasonNumber, posterPath: season.posterPath ?? show.posterPath)
    }

    static func season(_ season: SeasonDetails, seriesID: Int, seriesTitle: String? = nil) -> BoxContent {
        // SeasonDetails exposes TMDB's opaque `_id`, not its numeric season ID.
        // Series ID and season number provide the canonical navigation identity.
        BoxContent(kind: .season, title: season.name, subtitle: seriesTitle ?? String(localized: "Season \(season.seasonNumber)"), seriesID: seriesID, seasonNumber: season.seasonNumber, posterPath: season.posterPath)
    }

    static func episode(_ episode: EpisodeSummary, in show: MediaItem, seasonNumber: Int) -> BoxContent {
        self.episode(episode, seriesID: show.id, seasonNumber: seasonNumber, seriesTitle: show.title, posterPath: show.posterPath)
    }

    static func episode(_ episode: EpisodeSummary, seriesID: Int, seasonNumber: Int, seriesTitle: String? = nil, posterPath: String? = nil) -> BoxContent {
        let position = String(localized: "Season \(seasonNumber) · Episode \(episode.episodeNumber)")
        let subtitle = [seriesTitle, position].compactMap { $0 }.joined(separator: " · ")
        return BoxContent(kind: .episode, title: episode.name, subtitle: subtitle, mediaID: episode.id, seriesID: seriesID, seasonNumber: seasonNumber, episodeNumber: episode.episodeNumber, posterPath: posterPath)
    }

    static func trailer(_ video: Video, for item: MediaItem) -> BoxContent? {
        guard video.isYouTubeTrailer, !video.key.isEmpty,
              video.key.unicodeScalars.allSatisfy({ CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-").contains($0) })
        else { return nil }
        var components = URLComponents(string: "https://www.youtube.com/watch")
        components?.queryItems = [URLQueryItem(name: "v", value: video.key)]
        guard let url = components?.url else { return nil }
        return BoxContent(kind: .trailer, title: video.name, subtitle: item.title, mediaID: item.id, seriesID: item.mediaType == .tvShow ? item.id : nil, posterPath: item.posterPath, externalURL: url)
    }

    static func soundtrack(_ album: SoundtrackCandidate) -> BoxContent? {
        guard let url = album.url.flatMap({ musicURL($0.absoluteString) }) else { return nil }
        return BoxContent(kind: .soundtrack, title: album.title, subtitle: album.artistName, externalURL: url)
    }

    /// Accept only explicit HTTPS music links, with no credentials or custom ports.
    static func musicURL(_ input: String) -> URL? {
        guard let components = URLComponents(string: input.trimmingCharacters(in: .whitespacesAndNewlines)),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              ["music.apple.com", "open.spotify.com"].contains(host),
              components.user == nil, components.password == nil,
              components.port == nil || components.port == 443
        else { return nil }
        let path = components.path.split(separator: "/").map(String.init)
        let allowedKinds: Set<String> = host == "music.apple.com" ? ["album", "song", "playlist"] : ["album", "track", "playlist"]
        guard let kindIndex = path.prefix(2).firstIndex(where: allowedKinds.contains),
              path.count > kindIndex + 1 else { return nil }
        return components.url
    }
}

enum BoxPickerStyle {
    static let background = Color(red: 0.055, green: 0.051, blue: 0.043)
}

struct BoxPickerRow: View {
    let title: String
    let subtitle: String
    let posterPath: String?
    let symbol: String
    var showsAdd = false

    var body: some View {
        HStack(spacing: 12) {
            if let posterPath {
                PosterImage(path: posterPath, kind: .thumbnail)
                    .frame(width: 42, height: 63).clipShape(.rect(cornerRadius: 5))
                    .accessibilityHidden(true)
            } else {
                Image(systemName: symbol).foregroundStyle(DSColor.accent)
                    .frame(width: 42, height: 56).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(verbatim: title).font(.subheadline.weight(.medium)).foregroundStyle(.primary)
                if !subtitle.isEmpty { Text(verbatim: subtitle).font(.caption).foregroundStyle(.secondary) }
            }
            Spacer(minLength: 0)
            if showsAdd { Image(systemName: "plus.circle").foregroundStyle(DSColor.accent).accessibilityHidden(true) }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .combine)
    }
}

struct BoxPickerFailure: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(verbatim: message).foregroundStyle(.secondary)
            Button("Try Again", systemImage: "arrow.clockwise", action: retry)
        }.padding(.vertical, 8)
    }
}

struct BoxReviewComposer: View {
    let authorID: String
    let authorName: String
    var subject: MediaItem?
    let onAdd: (BoxContent) -> Void

    @State private var subjectText = ""
    @State private var note = ""
    @State private var includesRating = false
    @State private var rating = 4.0

    private var trimmedNote: String { note.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section("About This Content") {
                if let subject { Text(verbatim: subject.title) }
                else { TextField("A title, a scene or this box", text: $subjectText) }
            }
            .listRowBackground(Color.white.opacity(0.05))
            Section("What Stayed With You?") {
                TextField("A scene, a feeling, a memory…", text: $note, axis: .vertical)
                    .lineLimit(6...16)
            }
            .listRowBackground(Color.white.opacity(0.05))
            Section {
                Toggle("Include a Rating", isOn: $includesRating)
                if includesRating {
                    Slider(value: $rating, in: 0.5...5, step: 0.5) {
                        Text("Rating")
                    }
                    .accessibilityValue(Text("\(rating.formatted()) out of 5 stars"))
                    Text("\(rating.formatted()) out of 5 stars").font(.subheadline).foregroundStyle(DSColor.accent)
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            Section {
                if !authorName.isEmpty {
                    Text("Signed by \(authorName)").font(.caption).foregroundStyle(.secondary)
                }
            }
            .listRowBackground(Color.clear)
        }
        .scrollContentBackground(.hidden)
        .background(BoxPickerStyle.background)
        .navigationTitle("My Impression")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") { addReview() }.disabled(trimmedNote.isEmpty)
            }
        }
    }

    private func addReview() {
        guard !trimmedNote.isEmpty else { return }
        let topic = subject?.title ?? subjectText.trimmingCharacters(in: .whitespacesAndNewlines)
        onAdd(BoxContent(
            kind: .review,
            title: String(localized: "My Impression"),
            subtitle: topic.isEmpty ? String(localized: "About this box") : topic,
            mediaID: subject?.id,
            seriesID: subject?.mediaType == .tvShow ? subject?.id : nil,
            posterPath: subject?.posterPath,
            text: trimmedNote,
            rating: includesRating ? rating : nil,
            authorID: authorID,
            authorName: authorName
        ))
    }
}

struct BoxSoundtrackPicker: View {
    let onAdd: (BoxContent) -> Void

    @Environment(\.appleMusicCatalog) private var catalog
    @State private var query = ""
    @State private var albums: [SoundtrackCandidate] = []
    @State private var requestedAccess = false
    @State private var authorized = false
    @State private var authorizationFinished = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var retry = 0

    private struct SearchRequest: Hashable {
        let query: String
        let authorized: Bool
        let retry: Int
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    BoxSoundtrackLinkComposer(onAdd: onAdd)
                } label: {
                    Label("Add Apple Music or Spotify Link", systemImage: "link")
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            Section("Apple Music Catalog") {
                if !requestedAccess {
                    Text("Search Apple Music to choose an album for your box.").foregroundStyle(.secondary)
                    Button("Search Apple Music", systemImage: "music.note") { requestedAccess = true }
                } else if !authorizationFinished {
                    ProgressView("Connecting to Apple Music…")
                } else if !authorized {
                    Text("Allow Apple Music access in Settings, or add a music link above.").foregroundStyle(.secondary)
                    Button("Try Again") { requestedAccess = false }
                } else {
                    catalogResults
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(BoxPickerStyle.background)
        .navigationTitle("Add a Soundtrack")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, prompt: "Album, soundtrack or artist")
        .task(id: requestedAccess) {
            guard requestedAccess else { return }
            authorizationFinished = false
            let permitted = await catalog.requestAuthorizationIfNeeded()
            guard !Task.isCancelled else { return }
            authorized = permitted
            authorizationFinished = true
        }
        .task(id: SearchRequest(query: query, authorized: authorized, retry: retry)) { await search() }
    }

    @ViewBuilder private var catalogResults: some View {
        ForEach(albums) { album in
            Button {
                if let content = BoxContentFactory.soundtrack(album) { onAdd(content) }
            } label: {
                BoxPickerRow(title: album.title, subtitle: album.artistName, posterPath: nil, symbol: "music.note.list", showsAdd: true)
            }
        }
        if isLoading { ProgressView().frame(maxWidth: .infinity).padding() }
        else if let errorMessage {
            BoxPickerFailure(message: errorMessage) { retry += 1 }
        } else if albums.isEmpty {
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("Search for an album, soundtrack or artist.").foregroundStyle(.secondary)
            } else {
                ContentUnavailableView.search(text: query)
            }
        }
    }

    private func search() async {
        guard authorized else { return }
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        albums = []
        errorMessage = nil
        guard !term.isEmpty else { isLoading = false; return }
        isLoading = true
        do {
            try await Task.sleep(for: .milliseconds(350))
            let matches = try await catalog.searchAlbums(term: term, limit: 25)
            guard !Task.isCancelled else { return }
            albums = matches.filter { BoxContentFactory.soundtrack($0) != nil }
            isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = String(localized: "Couldn't search Apple Music. Try again or add a music link.")
            isLoading = false
        }
    }
}

private struct BoxSoundtrackLinkComposer: View {
    let onAdd: (BoxContent) -> Void
    @State private var title = ""
    @State private var artist = ""
    @State private var link = ""

    private var musicURL: URL? { BoxContentFactory.musicURL(link) }
    private var trimmedTitle: String { title.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            Section("Soundtrack") {
                TextField("Title", text: $title)
                TextField("Artist (optional)", text: $artist)
            }.listRowBackground(Color.white.opacity(0.05))
            Section {
                TextField("Apple Music or Spotify URL", text: $link)
                    .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                if !link.isEmpty && musicURL == nil {
                    Text("Use an HTTPS album, song or playlist link from music.apple.com or open.spotify.com.")
                        .font(.caption).foregroundStyle(DSColor.accent)
                }
            } header: { Text("Music Link") }
            footer: { Text("Copy a share link from Apple Music or Spotify.") }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(BoxPickerStyle.background)
        .navigationTitle("Add Music Link")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Add") {
                    guard let musicURL, !trimmedTitle.isEmpty else { return }
                    onAdd(BoxContent(kind: .soundtrack, title: trimmedTitle, subtitle: artist.trimmingCharacters(in: .whitespacesAndNewlines), externalURL: musicURL))
                }.disabled(trimmedTitle.isEmpty || musicURL == nil)
            }
        }
    }
}
