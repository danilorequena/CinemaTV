//
//  Snippets.swift
//  CinemaTV
//
//  Cards interativos que a Siri mostra inline: o conteúdo aparece na própria
//  Siri e o app só abre quando o usuário toca (OpenMovieIntent/OpenTVShowIntent
//  são foreground; os demais botões agem sem sair do card).
//
//  Regra dos SnippetIntents: perform() é leitura pura — o sistema re-executa
//  a cada redraw (ex.: depois do toque num botão do card). Mutações ficam nos
//  intents de controle (AddMovieToWatchlistIntent etc.).
//

import AppIntents
import SwiftUI
import UIKit
import CinemaTVCore

// MARK: - Poster

enum SnippetPoster {
    /// Baixa o poster como Image concreta: o card é um snapshot renderizado
    /// fora do app, então AsyncImage não teria chance de carregar.
    static func load(_ path: String?) async -> Image? {
        guard let url = TMDBImage.url(path: path, size: .thumbnail),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
    }
}

// MARK: - Busca: lista de resultados no card

struct SearchResultsSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Search Results Snippet"

    // Só primitivos como parâmetro: o sistema serializa e re-hidrata os
    // parâmetros a cada redraw, e a busca é refeita aqui dentro — perform()
    // de SnippetIntent deve ser leitura idempotente mesmo.
    @Parameter(title: "Query")
    var query: String

    init() {}
    init(query: String) {
        self.query = query
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let client = IntentSupport.makeTMDBClient()
        let page: PagedResponse<MediaItem> = try await client.fetch(.multiSearch, query: query)
        let results = VisualMediaResult.results(from: page.results).prefix(3)

        let watchlist = WatchlistStore(container: AppContainer.shared)
        let tracking = TVShowTrackingStore(container: AppContainer.shared)
        var rows: [MediaSnippetRow] = []
        for result in results {
            switch result {
            case .movie(let movie):
                rows.append(MediaSnippetRow(
                    kind: .movie(movie),
                    poster: await SnippetPoster.load(movie.posterPath),
                    isSaved: watchlist.isInWatchlist(movieID: movie.id) || watchlist.isWatched(movieID: movie.id)
                ))
            case .tvShow(let show):
                rows.append(MediaSnippetRow(
                    kind: .tvShow(show),
                    poster: await SnippetPoster.load(show.posterPath),
                    isSaved: tracking.isFollowing(showID: show.id)
                ))
            }
        }
        return .result(view: SearchResultsSnippetView(query: query, rows: rows))
    }
}

struct MediaSnippetRow: Identifiable {
    enum Kind {
        case movie(MovieEntity)
        case tvShow(TVShowEntity)
    }

    let kind: Kind
    let poster: Image?
    let isSaved: Bool

    var id: String {
        switch kind {
        case .movie(let movie): "movie-\(movie.id)"
        case .tvShow(let show): "tv-\(show.id)"
        }
    }

    var title: String {
        switch kind {
        case .movie(let movie): movie.title
        case .tvShow(let show): show.title
        }
    }

    /// Linha secundária: ano + tipo, ex. "2011 · TV Show".
    var subtitle: String? {
        switch kind {
        case .movie(let movie): movie.releaseYear
        case .tvShow(let show): (show.firstAirYear.map { "\($0) · " } ?? "") + "TV Show"
        }
    }
}

struct SearchResultsSnippetView: View {
    let query: String
    let rows: [MediaSnippetRow]

    var body: some View {
        // Sem glass/Material aqui: o renderer remoto de snippets (Siri/Atalhos)
        // não desenha esses efeitos e descarta o card inteiro — mesma limitação
        // do ImageRenderer documentada no ReviewShareCard. Só cores chapadas.
        VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text("Results for “\(query)”")
                        .font(.headline)
                }

                ForEach(rows) { row in
                    HStack(spacing: 12) {
                        // Tocar no item leva para dentro do app.
                        rowContent(row)
                            .buttonStyle(.plain)

                        Spacer(minLength: 8)

                        // Salva (watchlist/follow) sem sair da Siri.
                        saveButton(row)
                            .buttonStyle(.plain)
                            .disabled(row.isSaved)
                    }
                }

                // Entrar no app é opt-in: só por este botão ou tocando num item.
                Button(intent: OpenSearchInAppIntent(query: query)) {
                    Label("See all in CinemaTV", systemImage: "arrow.up.forward.app")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.accentColor.opacity(0.12), in: .capsule)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
        }
        .padding(16)
    }

    @ViewBuilder
    private func rowContent(_ row: MediaSnippetRow) -> some View {
        switch row.kind {
        case .movie(let movie):
            Button(intent: OpenMovieIntent(target: movie)) { rowLabel(row) }
        case .tvShow(let show):
            Button(intent: OpenTVShowIntent(target: show)) { rowLabel(row) }
        }
    }

    private func rowLabel(_ row: MediaSnippetRow) -> some View {
        HStack(spacing: 12) {
            SnippetPosterView(poster: row.poster, width: 48, height: 72)
            VStack(alignment: .leading, spacing: 3) {
                Text(row.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                if let subtitle = row.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func saveButton(_ row: MediaSnippetRow) -> some View {
        switch row.kind {
        case .movie(let movie):
            Button(intent: AddMovieToWatchlistIntent(movie: movie)) { saveIcon(row.isSaved) }
        case .tvShow(let show):
            Button(intent: FollowShowIntent(show: show)) { saveIcon(row.isSaved) }
        }
    }

    private func saveIcon(_ saved: Bool) -> some View {
        Image(systemName: saved ? "checkmark" : "plus")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(saved ? Color.green : Color.accentColor)
            .frame(width: 36, height: 36)
            .background((saved ? Color.green : Color.accentColor).opacity(0.12), in: .circle)
    }
}

// MARK: - Card de filme (confirmações de watchlist)

struct MovieCardSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Movie Card Snippet"

    @Parameter(title: "Movie")
    var movie: MovieEntity

    init() {}
    init(movie: MovieEntity) {
        self.movie = movie
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let store = WatchlistStore(container: AppContainer.shared)
        let status: MovieCardStatus = if store.isWatched(movieID: movie.id) {
            .watched
        } else if store.isInWatchlist(movieID: movie.id) {
            .inWatchlist
        } else {
            .none
        }
        return .result(view: MovieCardSnippetView(
            movie: movie,
            poster: await SnippetPoster.load(movie.posterPath),
            status: status
        ))
    }
}

enum MovieCardStatus {
    case inWatchlist, watched, none

    var label: LocalizedStringResource {
        switch self {
        case .inWatchlist: "In your watchlist"
        case .watched: "Watched"
        case .none: "Not in your watchlist"
        }
    }

    var symbolName: String {
        switch self {
        case .inWatchlist: "bookmark.fill"
        case .watched: "checkmark.circle.fill"
        case .none: "bookmark"
        }
    }

    var tint: Color {
        switch self {
        case .inWatchlist: .accentColor
        case .watched: .green
        case .none: .secondary
        }
    }
}

struct MovieCardSnippetView: View {
    let movie: MovieEntity
    let poster: Image?
    let status: MovieCardStatus

    var body: some View {
        HStack(spacing: 14) {
            SnippetPosterView(poster: poster, width: 64, height: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text(movie.title)
                    .font(.headline)
                    .lineLimit(2)
                if let year = movie.releaseYear {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                SnippetStatusChip(
                    label: status.label,
                    symbolName: status.symbolName,
                    tint: status.tint
                )
            }
            Spacer(minLength: 8)
            // Só entra no app se o usuário tocar.
            Button(intent: OpenMovieIntent(target: movie)) {
                SnippetOpenIcon()
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
}

// MARK: - Card de série (follow)

struct TVShowCardSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "TV Show Card Snippet"

    @Parameter(title: "TV Show")
    var show: TVShowEntity

    init() {}
    init(show: TVShowEntity) {
        self.show = show
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        let store = TVShowTrackingStore(container: AppContainer.shared)
        return .result(view: TVShowCardSnippetView(
            show: show,
            poster: await SnippetPoster.load(show.posterPath),
            isFollowing: store.isFollowing(showID: show.id)
        ))
    }
}

struct TVShowCardSnippetView: View {
    let show: TVShowEntity
    let poster: Image?
    let isFollowing: Bool

    var body: some View {
        HStack(spacing: 14) {
            SnippetPosterView(poster: poster, width: 64, height: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text(show.title)
                    .font(.headline)
                    .lineLimit(2)
                if let year = show.firstAirYear {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                SnippetStatusChip(
                    label: isFollowing ? "Following" : "Not following",
                    symbolName: isFollowing ? "checkmark.circle.fill" : "tv",
                    tint: isFollowing ? .green : .secondary
                )
            }
            Spacer(minLength: 8)
            Button(intent: OpenTVShowIntent(target: show)) {
                SnippetOpenIcon()
            }
            .buttonStyle(.plain)
        }
        .padding(16)
    }
}

// MARK: - Peças compartilhadas dos cards

/// Chip de status: conteúdo informativo, fica plano (glass é só nos controles).
struct SnippetStatusChip: View {
    let label: LocalizedStringResource
    let symbolName: String
    let tint: Color

    var body: some View {
        Label(label, systemImage: symbolName)
            .font(.caption2.weight(.medium))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: .capsule)
    }
}

/// Botão circular de "abrir no app". Fundo chapado: o renderer remoto de
/// snippets não desenha glass/Material.
struct SnippetOpenIcon: View {
    var body: some View {
        Image(systemName: "arrow.up.forward")
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(Color.accentColor)
            .frame(width: 36, height: 36)
            .background(Color.accentColor.opacity(0.12), in: .circle)
    }
}

// MARK: - Poster view compartilhada

struct SnippetPosterView: View {
    let poster: Image?
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Group {
            if let poster {
                poster
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(.systemGray4), Color(.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "film")
                        .font(.system(size: width * 0.4))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(.separator.opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 4, y: 2)
    }
}

// MARK: - Previews

private func previewMovie(id: Int, title: String, year: String) -> MovieEntity {
    MovieEntity(item: MediaItem(
        id: id,
        title: title,
        overview: "",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 8,
        releaseDate: "\(year)-03-01",
        mediaType: .movie
    ))
}

#Preview("Search results") {
    SearchResultsSnippetView(
        query: "dune",
        rows: [
            MediaSnippetRow(kind: .movie(previewMovie(id: 1, title: "Dune: Part Two", year: "2024")), poster: nil, isSaved: false),
            MediaSnippetRow(
                kind: .tvShow(TVShowEntity(item: MediaItem(
                    id: 90228,
                    title: "Dune: Prophecy",
                    overview: "",
                    posterPath: nil,
                    backdropPath: nil,
                    voteAverage: 8,
                    releaseDate: "2024-11-17",
                    mediaType: .tvShow
                ))),
                poster: nil,
                isSaved: false
            ),
            MediaSnippetRow(kind: .movie(previewMovie(id: 2, title: "Dune", year: "2021")), poster: nil, isSaved: true),
        ]
    )
}

#Preview("Movie card") {
    MovieCardSnippetView(
        movie: previewMovie(id: 1, title: "Dune: Part Two", year: "2024"),
        poster: nil,
        status: .inWatchlist
    )
}

#Preview("TV show card") {
    TVShowCardSnippetView(
        show: TVShowEntity(item: MediaItem(
            id: 1399,
            title: "Game of Thrones",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 9,
            releaseDate: "2011-04-17",
            mediaType: .tvShow
        )),
        poster: nil,
        isFollowing: true
    )
}
