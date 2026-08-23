//
//  SearchScreen.swift
//  CinemaTV
//
//  Busca multi (filmes, séries e pessoas) — substitui SearchView. Com a
//  query vazia mostra sugestões: chips das buscas recentes (histórico
//  local) + trending da semana no MESMO grid dos resultados.
//  Busca composta: tokens de gênero fixam no campo (searchable tokens) e
//  combinam com o termo digitado — texto via search/multi filtrado por
//  genre_ids; só gêneros via discover com with_genres.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

/// Token de gênero: fixa no campo de busca e restringe os resultados.
/// IDs do TMDB divergem entre filme e série (ex.: Action 28 vs
/// Action & Adventure 10759); nil = o gênero não existe naquele tipo.
private struct GenreToken: Identifiable, Hashable {
    let id: String
    let label: Text
    let movieID: Int?
    let tvID: Int?

    var allIDs: Set<Int> {
        Set([movieID, tvID].compactMap(\.self))
    }

    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

/// Catálogo estático (os IDs de gênero do TMDB são estáveis há anos).
private let genreCatalog: [GenreToken] = [
    GenreToken(id: "action", label: Text("Action"), movieID: 28, tvID: 10759),
    GenreToken(id: "adventure", label: Text("Adventure"), movieID: 12, tvID: 10759),
    GenreToken(id: "animation", label: Text("Animation"), movieID: 16, tvID: 16),
    GenreToken(id: "comedy", label: Text("Comedy"), movieID: 35, tvID: 35),
    GenreToken(id: "crime", label: Text("Crime"), movieID: 80, tvID: 80),
    GenreToken(id: "documentary", label: Text("Documentary"), movieID: 99, tvID: 99),
    GenreToken(id: "drama", label: Text("Drama"), movieID: 18, tvID: 18),
    GenreToken(id: "family", label: Text("Family"), movieID: 10751, tvID: 10751),
    GenreToken(id: "fantasy", label: Text("Fantasy"), movieID: 14, tvID: 10765),
    GenreToken(id: "horror", label: Text("Horror"), movieID: 27, tvID: nil),
    GenreToken(id: "mystery", label: Text("Mystery"), movieID: 9648, tvID: 9648),
    GenreToken(id: "romance", label: Text("Romance"), movieID: 10749, tvID: nil),
    GenreToken(id: "scifi", label: Text("Science Fiction"), movieID: 878, tvID: 10765),
    GenreToken(id: "thriller", label: Text("Thriller"), movieID: 53, tvID: nil)
]

struct SearchScreen: View {
    @Environment(\.tmdbClient) private var client
    @Environment(AppRouter.self) private var router
    @State private var results: [MediaItem] = []
    @State private var isSearching = false
    @State private var suggestions = SearchSuggestionsModel()
    /// Gêneros fixados no campo de busca.
    @State private var genreTokens: [GenreToken] = []
    /// Últimas buscas (JSON de [String]); local por design, sem sync.
    @AppStorage("recentSearches") private var recentSearchesData = Data()

    private let columns = [
        GridItem(.adaptive(minimum: 110), spacing: DSSpacing.md)
    ]

    /// Identidade da busca corrente: retrigga o task quando o termo OU os
    /// tokens mudam (o task(id:) cancela a busca anterior).
    private struct SearchRequest: Hashable {
        let query: String
        let tokenIDs: [String]
    }

    var body: some View {
        @Bindable var router = router

        Group {
            if router.searchQuery.isEmpty && genreTokens.isEmpty {
                suggestionsContent
            } else if results.isEmpty && !isSearching {
                EmptyStateView(
                    title: "No Results",
                    message: "Try a different title or name.",
                    systemImage: "questionmark.circle"
                )
            } else {
                ScrollView {
                    resultsGrid(results, scope: "search")
                }
                .animation(DSMotion.standard, value: results.map(\.id))
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $router.searchQuery,
            tokens: $genreTokens,
            suggestedTokens: .constant(genreCatalog.filter { !genreTokens.contains($0) }),
            prompt: Text("Movies, shows and people")
        ) { token in
            token.label
        }
        .searchToolbarBehavior(.minimize)
        // Submit do teclado = busca "de verdade"; o debounce por tecla não
        // polui o histórico.
        .onSubmit(of: .search) {
            recordSearch(router.searchQuery)
        }
        .task {
            await suggestions.load(client: client)
        }
        .task(id: SearchRequest(query: router.searchQuery, tokenIDs: genreTokens.map(\.id))) {
            await performSearch()
        }
    }

    /// Grid único para resultados e sugestões — trocar de um para o outro
    /// não muda o layout.
    private func resultsGrid(_ items: [MediaItem], scope: String) -> some View {
        LazyVGrid(columns: columns, spacing: DSSpacing.lg) {
            ForEach(items) { item in
                let selection = MediaSelection(item: item, scope: scope)
                NavigationLink(value: selection) {
                    if item.mediaType == .person {
                        PersonResultCard(item: item, zoomSourceID: selection.sourceID)
                    } else {
                        MediaCard(item: item, zoomSourceID: selection.sourceID)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }

    // MARK: - Sugestões (query vazia)

    @ViewBuilder
    private var suggestionsContent: some View {
        switch suggestions.state {
        case .failed:
            // Sugestão é bônus: sem rede, volta o estado vazio clássico.
            EmptyStateView(
                title: "Search",
                message: "Find movies, TV shows and people from TMDB.",
                systemImage: "magnifyingglass"
            )
        default:
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    if !recentSearches.isEmpty {
                        recentSection
                    }

                    SectionHeader("Trending")

                    switch suggestions.state {
                    case .loaded(let items):
                        resultsGrid(items, scope: "trending")
                    default:
                        LoadingStateView {
                            resultsGrid(skeletonItems, scope: "trending")
                        }
                    }
                }
                .padding(.vertical, DSSpacing.lg)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            HStack {
                Text("Recent")
                    .font(.dsSectionTitle)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button("Clear") {
                    clearRecentSearches()
                }
                .font(.dsCaption)
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DSSpacing.lg)

            ScrollView(.horizontal) {
                GlassEffectContainer(spacing: DSSpacing.sm) {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(recentSearches, id: \.self) { term in
                            Button {
                                router.searchQuery = term
                            } label: {
                                Text(verbatim: term)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .padding(.vertical, DSSpacing.sm)
                                    .padding(.horizontal, DSSpacing.md)
                                    .contentShape(.capsule)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .capsule)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private var skeletonItems: [MediaItem] {
        (1...9).map { index in
            MediaItem(
                id: index,
                title: "Placeholder",
                overview: "",
                posterPath: nil,
                backdropPath: nil,
                voteAverage: 0,
                releaseDate: nil,
                mediaType: .movie
            )
        }
    }

    // MARK: - Histórico de buscas

    private var recentSearches: [String] {
        (try? JSONDecoder().decode([String].self, from: recentSearchesData)) ?? []
    }

    private func recordSearch(_ query: String) {
        let term = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        var terms = recentSearches.filter { $0.caseInsensitiveCompare(term) != .orderedSame }
        terms.insert(term, at: 0)
        if let data = try? JSONEncoder().encode(Array(terms.prefix(8))) {
            recentSearchesData = data
        }
    }

    private func clearRecentSearches() {
        recentSearchesData = Data()
    }

    // MARK: - Busca

    private func performSearch() async {
        let query = router.searchQuery
        let tokens = genreTokens
        guard !query.isEmpty || !tokens.isEmpty else {
            results = []
            return
        }
        // Debounce: espera a digitação parar; task(id:) cancela a anterior.
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }

        isSearching = true
        defer { isSearching = false }
        do {
            if query.isEmpty {
                // Só gêneros: discover é o endpoint que filtra na origem.
                results = try await discoverByGenres(tokens)
            } else {
                // Termo (com ou sem gêneros): busca textual, gêneros
                // refinam localmente via genre_ids do payload.
                let response: PagedResponse<MediaItem> = try await client.fetch(.multiSearch, query: query)
                results = filterByTokens(response.results, tokens: tokens)
            }
        } catch is CancellationError {
            // Busca substituída por outra; mantém os resultados atuais.
        } catch {
            results = []
        }
    }

    /// AND entre gêneros (with_genres com vírgula). Um token sem ID de TV
    /// (ex.: Horror) não pode ser satisfeito por séries — pula o discover/tv;
    /// o inverso vale para filmes.
    private func discoverByGenres(_ tokens: [GenreToken]) async throws -> [MediaItem] {
        let movieIDs = tokens.compactMap(\.movieID)
        let tvIDs = tokens.compactMap(\.tvID)
        var combined: [MediaItem] = []

        if movieIDs.count == tokens.count {
            let response: PagedResponse<MediaItem> = try await client.fetch(
                .discoverMovies,
                parameters: [
                    "sort_by": "popularity.desc",
                    "with_genres": Set(movieIDs).sorted().map(String.init).joined(separator: ",")
                ]
            )
            combined += response.results
        }
        if tvIDs.count == tokens.count {
            let response: PagedResponse<MediaItem> = try await client.fetch(
                .discoverTVShows,
                parameters: [
                    "sort_by": "popularity.desc",
                    "with_genres": Set(tvIDs).sorted().map(String.init).joined(separator: ",")
                ]
            )
            combined += response.results
        }
        return combined
    }

    /// Cada token precisa bater em pelo menos um genre_id do item (AND
    /// entre tokens); pessoas não têm gênero e saem quando há filtro.
    private func filterByTokens(_ items: [MediaItem], tokens: [GenreToken]) -> [MediaItem] {
        guard !tokens.isEmpty else { return items }
        return items.filter { item in
            guard item.mediaType != .person, let genreIds = item.genreIds else { return false }
            let itemGenres = Set(genreIds)
            return tokens.allSatisfy { !$0.allIDs.isDisjoint(with: itemGenres) }
        }
    }
}

// MARK: - Sugestões (trending da semana)

@MainActor
@Observable
final class SearchSuggestionsModel {
    private(set) var state: LoadState<[MediaItem]> = .idle

    func load(client: TMDBClient) async {
        if case .loaded = state { return }
        state = .loading
        do {
            let response: PagedResponse<MediaItem> = try await client.fetch(.trendingAll)
            state = .loaded(response.results)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

// MARK: - Card de pessoa

/// Resultado de pessoa no grid: foto de perfil circular + nome. O MediaCard
/// (poster 2:3) esticava a foto de perfil, que é quadrada.
private struct PersonResultCard: View {
    @Environment(\.mediaZoomNamespace) private var zoomNamespace

    let item: MediaItem
    var zoomSourceID: String?

    var body: some View {
        VStack(spacing: DSSpacing.sm) {
            PosterImage(path: item.posterPath, kind: .profile)
                .frame(width: 88, height: 88)
                .clipShape(.circle)
            Text(verbatim: item.title)
                .font(.dsCaption)
                .lineLimit(2, reservesSpace: true)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .modifier(ZoomSourceModifier(id: zoomSourceID, namespace: zoomNamespace))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text(verbatim: item.title))
    }
}

#Preview("Results Grid") {
    let movies: [MediaItem] = [
        .dsPreview,
        MediaItem(
            id: 604,
            title: "The Matrix Reloaded",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 7.1,
            releaseDate: "2003-05-15",
            mediaType: .movie
        )
    ]
    let people: [MediaItem] = [
        MediaItem(
            id: 6384,
            title: "Keanu Reeves",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: nil,
            mediaType: .person
        ),
        MediaItem(
            id: 530,
            title: "Carrie-Anne Moss",
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: nil,
            mediaType: .person
        )
    ]

    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 110), spacing: DSSpacing.md)], spacing: DSSpacing.lg) {
            ForEach(movies + people) { item in
                if item.mediaType == .person {
                    PersonResultCard(item: item)
                } else {
                    MediaCard(item: item)
                }
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }
}
