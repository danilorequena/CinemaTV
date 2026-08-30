//
//  CinemaTVWidget.swift
//  CinemaTVWidget
//
//  Widget de filmes com categoria configurável (AppIntentTimelineProvider),
//  usando o TMDBClient do CinemaTVCore. Taps abrem o app via deep link
//  cinematv://movie/{id}.
//

import WidgetKit
import SwiftUI
import SwiftData
import AppIntents
import CinemaTVCore

/// Container SwiftData do app group — mesma store que o app e os intents.
enum WidgetContainer {
    static let shared = ModelContainerFactory.resilientShared()
}

// MARK: - Configuração

enum WidgetMovieCategory: String, AppEnum {
    case upcoming
    case nowPlaying
    case popular

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static let caseDisplayRepresentations: [WidgetMovieCategory: DisplayRepresentation] = [
        .upcoming: "Upcoming",
        .nowPlaying: "Now Playing",
        .popular: "Popular"
    ]

    var movieCategory: MovieCategory {
        switch self {
        case .upcoming: .upcoming
        case .nowPlaying: .nowPlaying
        case .popular: .popular
        }
    }
}

struct MovieWidgetConfigIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Movies"
    static let description = IntentDescription("Choose which movies to show.")

    @Parameter(title: "Category", default: .upcoming)
    var category: WidgetMovieCategory
}

// MARK: - Timeline

struct MovieWidgetEntry: TimelineEntry {
    struct MovieSnapshot: Identifiable {
        let id: Int
        let title: String
        let poster: Image?

        var deepLinkURL: URL {
            URL(string: "cinematv://movie/\(id)")!
        }
    }

    let date: Date
    let category: WidgetMovieCategory
    let movies: [MovieSnapshot]

    static let placeholder = MovieWidgetEntry(
        date: .now,
        category: .upcoming,
        movies: (1...4).map { .init(id: $0, title: "Movie Title", poster: nil) }
    )
}

struct MovieTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> MovieWidgetEntry {
        .placeholder
    }

    func snapshot(for configuration: MovieWidgetConfigIntent, in context: Context) async -> MovieWidgetEntry {
        (try? await fetchEntry(for: configuration)) ?? .placeholder
    }

    func timeline(for configuration: MovieWidgetConfigIntent, in context: Context) async -> Timeline<MovieWidgetEntry> {
        let entry = (try? await fetchEntry(for: configuration)) ?? .placeholder
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 6, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func fetchEntry(for configuration: MovieWidgetConfigIntent) async throws -> MovieWidgetEntry {
        let client = TMDBClient(configuration: try .fromBundle(.main))
        let page: PagedResponse<MediaItem> = try await client.fetch(configuration.category.movieCategory.endpoint)

        var snapshots: [MovieWidgetEntry.MovieSnapshot] = []
        for item in page.results.prefix(4) {
            // Widgets não podem carregar imagem async na view: baixa aqui.
            var poster: Image?
            if let url = TMDBImage.url(path: item.posterPath, size: .thumbnail),
               let (data, _) = try? await URLSession.shared.data(from: url),
               let uiImage = UIImage(data: data) {
                poster = Image(uiImage: uiImage)
            }
            snapshots.append(.init(id: item.id, title: item.title, poster: poster))
        }
        return MovieWidgetEntry(date: .now, category: configuration.category, movies: snapshots)
    }
}

// MARK: - Widget

@main
struct BundleWidgets: WidgetBundle {
    var body: some Widget {
        MoviesWidget()
        LibraryWidget()
        LauncherWidget()
    }
}

struct MoviesWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CinemaTVMovies",
            intent: MovieWidgetConfigIntent.self,
            provider: MovieTimelineProvider()
        ) { entry in
            MovieWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Movies")
        .description("Keep up with upcoming, now playing, or popular movies.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular])
    }
}

// MARK: - Views

struct MovieWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: MovieWidgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        case .systemLarge:
            largeView
        case .accessoryRectangular:
            accessoryView
        default:
            smallView
        }
    }

    private var smallView: some View {
        ZStack(alignment: .bottomLeading) {
            if let first = entry.movies.first {
                poster(first.poster)
                LinearGradient(colors: [.clear, .black.opacity(0.8)], startPoint: .center, endPoint: .bottom)
                Text(verbatim: first.title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .padding(8)
            }
        }
        .widgetURL(entry.movies.first?.deepLinkURL)
    }

    private var mediumView: some View {
        HStack(spacing: 8) {
            ForEach(entry.movies.prefix(3)) { movie in
                Link(destination: movie.deepLinkURL) {
                    VStack(spacing: 4) {
                        poster(movie.poster)
                            .clipShape(.rect(cornerRadius: 8))
                        Text(verbatim: movie.title)
                            .font(.caption2.weight(.medium))
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(4)
    }

    private var largeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(entry.category.displayTitle)
                .font(.headline)
            ForEach(entry.movies.prefix(4)) { movie in
                Link(destination: movie.deepLinkURL) {
                    HStack(spacing: 10) {
                        poster(movie.poster)
                            .frame(width: 36, height: 54)
                            .clipShape(.rect(cornerRadius: 6))
                        Text(verbatim: movie.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(2)
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(4)
    }

    private var accessoryView: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.category.displayTitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(verbatim: entry.movies.first?.title ?? "—")
                .font(.headline)
                .lineLimit(2)
        }
        .widgetURL(entry.movies.first?.deepLinkURL)
    }

    @ViewBuilder
    private func poster(_ image: Image?) -> some View {
        if let image {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "movieclapper")
                        .foregroundStyle(.tertiary)
                }
        }
    }
}

private extension WidgetMovieCategory {
    var displayTitle: LocalizedStringKey {
        switch self {
        case .upcoming: "Coming Soon"
        case .nowPlaying: "Now Playing"
        case .popular: "Popular"
        }
    }
}
// MARK: - Library widget (Up Next / Watchlist)

enum LibraryWidgetScope: String, AppEnum {
    case upNext
    case watchlist

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Content"
    static let caseDisplayRepresentations: [LibraryWidgetScope: DisplayRepresentation] = [
        .upNext: "Up Next (TV Shows)",
        .watchlist: "Watchlist (Movies)"
    ]
}

struct LibraryWidgetConfigIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Library"
    static let description = IntentDescription("Your shows up next or your movie watchlist.")

    @Parameter(title: "Content", default: .upNext)
    var scope: LibraryWidgetScope
}

/// Marca assistido direto do widget. Vive no target do widget (Button(intent:)
/// exige o tipo compilado aqui); a store é a mesma do app via app group.
struct MarkWatchedFromWidgetIntent: AppIntent {
    static let title: LocalizedStringResource = "Mark Movie as Watched"
    static let isDiscoverable = false

    @Parameter(title: "Movie ID")
    var movieID: Int

    @Parameter(title: "Title")
    var movieTitle: String

    @Parameter(title: "Poster Path")
    var posterPath: String?

    @Parameter(title: "Release Date")
    var releaseDate: String?

    init() {}
    init(movieID: Int, movieTitle: String, posterPath: String?, releaseDate: String?) {
        self.movieID = movieID
        self.movieTitle = movieTitle
        self.posterPath = posterPath
        self.releaseDate = releaseDate
    }

    @MainActor
    func perform() async throws -> some IntentResult {
        let store = WatchlistStore(container: WidgetContainer.shared)
        let item = MediaItem(
            id: movieID,
            title: movieTitle,
            overview: "",
            posterPath: posterPath,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: releaseDate,
            mediaType: .movie
        )
        try store.markWatched(item)
        WidgetCenter.shared.reloadTimelines(ofKind: "CinemaTVLibrary")
        return .result()
    }
}

struct LibraryEntry: TimelineEntry {
    struct Item: Identifiable {
        let id: Int
        let title: String
        /// "S2 E5 · Nome" (próximo episódio) ou nil.
        let subtitle: String?
        let poster: Image?
        let isMovie: Bool
        let posterPath: String?
        let releaseDate: String?

        var deepLinkURL: URL {
            URL(string: "cinematv://\(isMovie ? "movie" : "tvshow")/\(id)")!
        }
    }

    let date: Date
    let scope: LibraryWidgetScope
    let items: [Item]

    static let placeholder = LibraryEntry(
        date: .now,
        scope: .upNext,
        items: (1...4).map {
            .init(id: $0, title: "Show Title", subtitle: "S1 E\($0)", poster: nil,
                  isMovie: false, posterPath: nil, releaseDate: nil)
        }
    )
}

struct LibraryTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LibraryEntry {
        .placeholder
    }

    func snapshot(for configuration: LibraryWidgetConfigIntent, in context: Context) async -> LibraryEntry {
        await fetchEntry(for: configuration)
    }

    func timeline(for configuration: LibraryWidgetConfigIntent, in context: Context) async -> Timeline<LibraryEntry> {
        let entry = await fetchEntry(for: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    @MainActor
    private func fetchEntry(for configuration: LibraryWidgetConfigIntent) async -> LibraryEntry {
        var items: [LibraryEntry.Item] = []
        switch configuration.scope {
        case .upNext:
            let shows = (try? TVShowTrackingStore(container: WidgetContainer.shared).watchingShows()) ?? []
            for show in shows.prefix(4) {
                guard let id = show.id else { continue }
                var subtitle: String?
                if let season = show.nextEpisodeSeason, let episode = show.nextEpisodeNumber {
                    subtitle = "S\(season) E\(episode)" + (show.nextEpisodeName.map { " · \($0)" } ?? "")
                }
                items.append(.init(
                    id: id,
                    title: show.name ?? "—",
                    subtitle: subtitle,
                    poster: await downloadPoster(show.imagePath),
                    isMovie: false,
                    posterPath: show.imagePath,
                    releaseDate: nil
                ))
            }
        case .watchlist:
            let movies = (try? WatchlistStore(container: WidgetContainer.shared).moviesToWatch()) ?? []
            for movie in movies.prefix(4) {
                guard let id = movie.id else { continue }
                items.append(.init(
                    id: Int(id),
                    title: movie.name ?? "—",
                    subtitle: movie.releaseDate.map { String($0.prefix(4)) },
                    poster: await downloadPoster(movie.profilePath),
                    isMovie: true,
                    posterPath: movie.profilePath,
                    releaseDate: movie.releaseDate
                ))
            }
        }
        return LibraryEntry(date: .now, scope: configuration.scope, items: items)
    }

    private func downloadPoster(_ path: String?) async -> Image? {
        guard let url = TMDBImage.url(path: path, size: .thumbnail),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
}

struct LibraryWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CinemaTVLibrary",
            intent: LibraryWidgetConfigIntent.self,
            provider: LibraryTimelineProvider()
        ) { entry in
            LibraryWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Library")
        .description("Your shows up next or your movie watchlist, with quick actions.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct LibraryWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LibraryEntry

    private var visibleItems: [LibraryEntry.Item] {
        Array(entry.items.prefix(family == .systemLarge ? 4 : 2))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: entry.scope == .upNext ? "play.tv" : "bookmark")
                    .font(.caption.weight(.semibold))
                Text(entry.scope == .upNext ? "Up Next" : "Watchlist")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(.secondary)

            if visibleItems.isEmpty {
                Spacer()
                Text(entry.scope == .upNext ? "Follow a show to see it here." : "Your watchlist is empty.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ForEach(visibleItems) { item in
                    row(item)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(2)
    }

    private func row(_ item: LibraryEntry.Item) -> some View {
        HStack(spacing: 10) {
            Link(destination: item.deepLinkURL) {
                HStack(spacing: 10) {
                    poster(item.poster)
                        .frame(width: 32, height: 48)
                        .clipShape(.rect(cornerRadius: 6))
                    VStack(alignment: .leading, spacing: 1) {
                        Text(verbatim: item.title)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(1)
                        if let subtitle = item.subtitle {
                            Text(verbatim: subtitle)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }

            if item.isMovie {
                // Marca assistido sem abrir o app.
                Button(intent: MarkWatchedFromWidgetIntent(
                    movieID: item.id,
                    movieTitle: item.title,
                    posterPath: item.posterPath,
                    releaseDate: item.releaseDate
                )) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 26, height: 26)
                        .background(Color.accentColor.opacity(0.12), in: .circle)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func poster(_ image: Image?) -> some View {
        if let image {
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Rectangle()
                .fill(.quaternary)
                .overlay {
                    Image(systemName: "movieclapper")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
        }
    }
}

// MARK: - Quick Action widget (SystemShortcut, iOS 27)

struct LauncherWidgetConfigIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Quick Action"
    static let description = IntentDescription("Run a shortcut or open an app.")

    @Parameter(title: "Action")
    var shortcut: SystemShortcut?
}

struct LauncherEntry: TimelineEntry {
    let date: Date
    let configuration: LauncherWidgetConfigIntent
}

struct LauncherTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> LauncherEntry {
        LauncherEntry(date: .now, configuration: LauncherWidgetConfigIntent())
    }

    func snapshot(for configuration: LauncherWidgetConfigIntent, in context: Context) async -> LauncherEntry {
        LauncherEntry(date: .now, configuration: configuration)
    }

    func timeline(for configuration: LauncherWidgetConfigIntent, in context: Context) async -> Timeline<LauncherEntry> {
        Timeline(entries: [LauncherEntry(date: .now, configuration: configuration)], policy: .never)
    }
}

struct LauncherWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: "CinemaTVLauncher",
            intent: LauncherWidgetConfigIntent.self,
            provider: LauncherTimelineProvider()
        ) { entry in
            LauncherWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Quick Action")
        .description("A button that runs any shortcut, App Shortcut, or opens an app.")
        .supportedFamilies([.systemSmall])
    }
}

struct LauncherWidgetView: View {
    let entry: LauncherEntry

    var body: some View {
        if let shortcut = entry.configuration.shortcut {
            Button(intent: RunSystemShortcutIntent(shortcut: shortcut)) {
                label(title: Text(shortcut.displayRepresentation.title))
            }
            .buttonStyle(.plain)
        } else {
            // Sem ação configurada: long-press → Edit Widget para escolher.
            label(title: Text("Choose an action"))
                .foregroundStyle(.secondary)
        }
    }

    private func label(title: Text) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.largeTitle)
                .foregroundStyle(Color.accentColor)
            title
                .font(.caption.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Previews

#Preview("Library · Up Next", as: .systemLarge) {
    LibraryWidget()
} timeline: {
    LibraryEntry.placeholder
}

#Preview("Library · Watchlist", as: .systemMedium) {
    LibraryWidget()
} timeline: {
    LibraryEntry(
        date: .now,
        scope: .watchlist,
        items: [
            .init(id: 1, title: "Dune: Part Two", subtitle: "2024", poster: nil,
                  isMovie: true, posterPath: nil, releaseDate: "2024-03-01"),
            .init(id: 2, title: "The Batman", subtitle: "2022", poster: nil,
                  isMovie: true, posterPath: nil, releaseDate: "2022-03-04"),
        ]
    )
}

#Preview("Quick Action", as: .systemSmall) {
    LauncherWidget()
} timeline: {
    LauncherEntry(date: .now, configuration: LauncherWidgetConfigIntent())
}

