import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

/// Collects a value for the draft. Persistence remains the composer's responsibility.
struct BoxContentPicker: View {
    let authorID: String
    let authorName: String
    let onAdd: (BoxContent) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.tmdbClient) private var client
    @State private var query = ""
    @State private var loadedQuery = ""
    @State private var results: [MediaItem] = []
    @State private var page = 1
    @State private var hasMore = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var retry = 0

    private struct SearchRequest: Hashable {
        let query: String
        let page: Int
        let retry: Int
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink(value: BoxPickerRoute.review) { Label("Write My Impression", systemImage: "square.and.pencil") }
                    NavigationLink(value: BoxPickerRoute.soundtrack) { Label("Add a Soundtrack", systemImage: "music.note") }
                }
                .listRowBackground(Color.white.opacity(0.05))

                Section("Movies and TV Shows") {
                    ForEach(results, id: \.boxCatalogID) { item in
                        NavigationLink(value: BoxPickerRoute.media(item)) {
                            BoxPickerRow(
                                title: item.title,
                                subtitle: BoxContentFactory.media(item).subtitle,
                                posterPath: item.posterPath,
                                symbol: item.mediaType == .movie ? "film" : "tv"
                            )
                        }
                    }
                    if isLoading { ProgressView().frame(maxWidth: .infinity).padding() }
                    if let errorMessage {
                        BoxPickerFailure(message: errorMessage) { retry += 1 }
                    } else if !isLoading && results.isEmpty {
                        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            ContentUnavailableView("Find Your Next Addition", systemImage: "magnifyingglass", description: Text("Search for a movie or show, then choose the work, a season, an episode or a trailer."))
                        } else {
                            ContentUnavailableView.search(text: query)
                        }
                    }
                    if hasMore && !isLoading && errorMessage == nil {
                        Button("Load More") { page += 1 }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
            }
            .scrollContentBackground(.hidden)
            .background(BoxPickerStyle.background)
            .searchable(text: $query, prompt: "Movies and TV shows")
            .navigationTitle("Add to Box")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .navigationDestination(for: BoxPickerRoute.self) { route in
                switch route {
                case .media(let item):
                    BoxCatalogItemPicker(item: item, authorID: authorID, authorName: authorName, onAdd: add)
                case .season(let show, let season):
                    BoxSeasonContentPicker(show: show, season: season, onAdd: add)
                case .review:
                    BoxReviewComposer(authorID: authorID, authorName: authorName, onAdd: add)
                case .soundtrack:
                    BoxSoundtrackPicker(onAdd: add)
                }
            }
            .onChange(of: query) { page = 1 }
            .task(id: SearchRequest(query: query, page: page, retry: retry)) { await search() }
        }
        .preferredColorScheme(.dark)
        .tint(DSColor.accent)
    }

    private func add(_ content: BoxContent) {
        onAdd(content)
        dismiss()
    }

    private func search() async {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let requestedPage = term == loadedQuery ? page : 1
        if term != loadedQuery || requestedPage == 1 { results = []; hasMore = false }
        errorMessage = nil
        guard !term.isEmpty else { isLoading = false; loadedQuery = term; return }
        isLoading = true
        do {
            if requestedPage == 1 { try await Task.sleep(for: .milliseconds(300)) }
            let response: PagedResponse<MediaItem> = try await client.fetch(.multiSearch, page: requestedPage, query: term)
            guard !Task.isCancelled else { return }
            let knownIDs = Set(results.map(\.boxCatalogID))
            results += response.results.filter { $0.mediaType != .person && !knownIDs.contains($0.boxCatalogID) }
            loadedQuery = term
            hasMore = response.hasMorePages
            isLoading = false
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = String(localized: "Couldn't load the catalog. Please try again.")
            isLoading = false
        }
    }
}

private enum BoxPickerRoute: Hashable {
    case media(MediaItem)
    case season(MediaItem, SeasonSummary)
    case review
    case soundtrack
}

private extension MediaItem {
    // TMDB IDs are scoped by media type: a movie and show can share an ID.
    var boxCatalogID: String { "\(mediaType.rawValue)-\(id)" }
}

private struct BoxCatalogItemPicker: View {
    let item: MediaItem
    let authorID: String
    let authorName: String
    let onAdd: (BoxContent) -> Void

    @Environment(\.tmdbClient) private var client
    @State private var seasons: [SeasonSummary] = []
    @State private var trailers: [Video] = []
    @State private var loadingSeasons = true
    @State private var loadingTrailers = true
    @State private var seasonsFailed = false
    @State private var trailersFailed = false
    @State private var seasonRetry = 0
    @State private var trailerRetry = 0

    var body: some View {
        List {
            Section {
                BoxPickerRow(title: item.title, subtitle: BoxContentFactory.media(item).subtitle, posterPath: item.posterPath, symbol: "film")
                Button {
                    onAdd(BoxContentFactory.media(item))
                } label: {
                    Label {
                        if item.mediaType == .movie { Text("Add Movie") }
                        else { Text("Add Entire Series") }
                    } icon: { Image(systemName: "plus.circle.fill") }
                }
                NavigationLink {
                    BoxReviewComposer(authorID: authorID, authorName: authorName, subject: item, onAdd: onAdd)
                } label: {
                    Label("Write My Impression", systemImage: "square.and.pencil")
                }
            }
            .listRowBackground(Color.white.opacity(0.05))

            if item.mediaType == .tvShow {
                Section("Seasons and Episodes") {
                    if loadingSeasons { ProgressView().padding() }
                    else if seasonsFailed {
                        BoxPickerFailure(message: String(localized: "Couldn't load seasons.")) { seasonRetry += 1 }
                    } else if seasons.isEmpty {
                        Text("No seasons are available yet.").foregroundStyle(.secondary)
                    } else {
                        ForEach(seasons) { season in
                            NavigationLink(value: BoxPickerRoute.season(item, season)) {
                                BoxPickerRow(title: season.name, subtitle: season.episodeCount.map { String(localized: "\($0) episodes") } ?? "", posterPath: season.posterPath ?? item.posterPath, symbol: "rectangle.stack")
                            }
                        }
                    }
                }
                .listRowBackground(Color.white.opacity(0.05))
            }

            Section("Trailers") {
                if loadingTrailers { ProgressView().padding() }
                else if trailersFailed {
                    BoxPickerFailure(message: String(localized: "Couldn't load trailers.")) { trailerRetry += 1 }
                } else if trailers.isEmpty {
                    Text("No trailers are available for this title.").foregroundStyle(.secondary)
                } else {
                    ForEach(trailers) { video in
                        Button {
                            if let content = BoxContentFactory.trailer(video, for: item) { onAdd(content) }
                        } label: {
                            BoxPickerRow(title: video.name, subtitle: video.site, posterPath: item.posterPath, symbol: "play.rectangle", showsAdd: true)
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(BoxPickerStyle.background)
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: seasonRetry) { await loadSeasons() }
        .task(id: trailerRetry) { await loadTrailers() }
    }

    private func loadSeasons() async {
        guard item.mediaType == .tvShow else { return }
        loadingSeasons = true
        seasonsFailed = false
        do {
            let details: TVShowDetails = try await client.fetch(.tvShowDetail(id: item.id))
            guard !Task.isCancelled else { return }
            seasons = (details.seasons ?? []).sorted { $0.seasonNumber < $1.seasonNumber }
            loadingSeasons = false
        } catch {
            guard !Task.isCancelled else { return }
            seasonsFailed = true
            loadingSeasons = false
        }
    }

    private func loadTrailers() async {
        loadingTrailers = true
        trailersFailed = false
        do {
            let endpoint: TMDBEndpoint = item.mediaType == .movie ? .movieVideos(id: item.id) : .tvShowVideos(id: item.id)
            let response: VideosResponse = try await client.fetch(endpoint)
            guard !Task.isCancelled else { return }
            trailers = response.results.filter { BoxContentFactory.trailer($0, for: item) != nil }
                .sorted { ($0.official ?? false) && !($1.official ?? false) }
            loadingTrailers = false
        } catch {
            guard !Task.isCancelled else { return }
            trailersFailed = true
            loadingTrailers = false
        }
    }
}

private struct BoxSeasonContentPicker: View {
    let show: MediaItem
    let season: SeasonSummary
    let onAdd: (BoxContent) -> Void

    @Environment(\.tmdbClient) private var client
    @State private var episodes: [EpisodeSummary] = []
    @State private var isLoading = true
    @State private var failed = false
    @State private var retry = 0

    var body: some View {
        List {
            Section {
                BoxPickerRow(title: season.name, subtitle: show.title, posterPath: season.posterPath ?? show.posterPath, symbol: "rectangle.stack")
                Button("Add Entire Season", systemImage: "plus.circle.fill") {
                    onAdd(BoxContentFactory.season(season, in: show))
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
            Section("Episodes") {
                if isLoading { ProgressView().padding() }
                else if failed {
                    BoxPickerFailure(message: String(localized: "Couldn't load episodes.")) { retry += 1 }
                } else if episodes.isEmpty {
                    Text("No episodes are available yet.").foregroundStyle(.secondary)
                } else {
                    ForEach(episodes) { episode in
                        Button {
                            onAdd(BoxContentFactory.episode(episode, in: show, seasonNumber: season.seasonNumber))
                        } label: {
                            BoxPickerRow(title: episode.name, subtitle: String(localized: "Episode \(episode.episodeNumber)"), posterPath: season.posterPath ?? show.posterPath, symbol: "play.rectangle", showsAdd: true)
                        }
                    }
                }
            }
            .listRowBackground(Color.white.opacity(0.05))
        }
        .scrollContentBackground(.hidden)
        .background(BoxPickerStyle.background)
        .navigationTitle(season.name)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: retry) {
            isLoading = true
            failed = false
            do {
                let details: SeasonDetails = try await client.fetch(.tvShowSeason(id: show.id, season: season.seasonNumber))
                guard !Task.isCancelled else { return }
                episodes = details.episodes.sorted { $0.episodeNumber < $1.episodeNumber }
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                failed = true
                isLoading = false
            }
        }
    }
}
