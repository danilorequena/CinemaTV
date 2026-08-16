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
import AppIntents
import CinemaTVCore

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
