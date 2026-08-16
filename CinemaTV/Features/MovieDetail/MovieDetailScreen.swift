//
//  MovieDetailScreen.swift
//  CinemaTV
//
//  Detail de filme: backdrop + seções (pills, nota, sinopse, trailers,
//  elenco, provedores, recomendações) + action bar de watchlist em glass.
//  Substitui DetailView/DetailMoviesView/DetailCoreView.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

/// Estado do filme em relação à watchlist (antes vivia no WatchlistButton
/// do DS, removido; só esta tela usa).
enum WatchlistState: Equatable {
    case none
    case toWatch
    case watched
}

struct MovieDetailScreen: View {
    @Environment(\.tmdbClient) private var client
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    // O gauge contém texto: frame fixo cortava a nota em tamanhos de
    // acessibilidade.
    @ScaledMetric(relativeTo: .caption) private var gaugeSize: CGFloat = 48
    @State private var model = MovieDetailModel()
    @State private var watchlistState: WatchlistState = .none
    @State private var presentedTrailer: Video?
    @State private var reviewTarget: MediaItem?
    @State private var hasReview = false
    @State private var suggestsReview = false

    private let movieID: Int
    /// Dados já conhecidos do card de origem, para pintar o header
    /// imediatamente durante a zoom transition.
    private let preview: MediaItem?

    init(item: MediaItem) {
        self.movieID = item.id
        self.preview = item
    }

    init(movieID: Int) {
        self.movieID = movieID
        self.preview = nil
    }

    private var store: WatchlistStore {
        WatchlistStore(context: modelContext)
    }

    private var reviewStore: ReviewStore {
        ReviewStore(context: modelContext)
    }

    var body: some View {
        ScrollView {
            switch model.state {
            case .idle, .loading:
                header(backdropPath: preview?.backdropPath, title: preview?.title ?? "")
            case .loaded(let details):
                header(backdropPath: details.movie.backdropPath ?? preview?.backdropPath, title: details.movie.title)
                content(details)
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await model.retry(client: client, movieID: movieID) }
                }
                .padding(.top, DSSpacing.xxl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationBarTitleDisplayMode(.inline)
        // Detalhe é contexto de foco: some a tab bar e as ações da watchlist
        // viram itens do bottom bar (glass do sistema de graça).
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    toggleWatchlist()
                } label: {
                    // HStack manual: no bottom bar o sistema colapsa Label
                    // para ícone-só, e esta ação precisa do texto.
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: watchlistState == .toWatch ? "bookmark.fill" : "bookmark")
                            .contentTransition(.symbolEffect(.replace))
                        Text(watchlistState == .toWatch ? "In Watchlist" : "Add to Watchlist")
                    }
                }

                Spacer()

                if watchlistState == .watched {
                    Button {
                        reviewTarget = currentItem
                    } label: {
                        Label(
                            hasReview ? "Edit Review" : "Write Review",
                            systemImage: hasReview ? "star.bubble.fill" : "star.bubble"
                        )
                        .labelStyle(.iconOnly)
                        .contentTransition(.symbolEffect(.replace))
                    }
                    .accessibilityLabel(Text(hasReview ? "Edit Review" : "Write Review"))
                }

                Button {
                    toggleWatched()
                } label: {
                    Label(
                        watchlistState == .watched ? "Watched" : "Mark as Watched",
                        systemImage: watchlistState == .watched ? "checkmark.circle.fill" : "checkmark.circle"
                    )
                    .labelStyle(.iconOnly)
                    .contentTransition(.symbolEffect(.replace))
                }
                .tint(watchlistState == .watched ? .green : nil)
                .accessibilityLabel(Text(watchlistState == .watched ? "Watched" : "Mark as Watched"))
            }
        }
        .sensoryFeedback(.success, trigger: watchlistState == .watched)
        .sensoryFeedback(.impact(weight: .light), trigger: watchlistState == .toWatch)
        .task {
            refreshWatchlistState()
            await model.load(client: client, movieID: movieID)
            // Backfill da data de estreia para a agenda Up Next (itens
            // antigos da watchlist não a persistiam).
            if case .loaded(let details) = model.state {
                try? store.updateReleaseDate(movieID: movieID, releaseDate: details.movie.releaseDate)
            }
        }
        .sheet(item: $presentedTrailer) { trailer in
            YouTubePlayerView(video: trailer)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $reviewTarget, onDismiss: refreshWatchlistState) { item in
            ReviewComposerSheet(item: item)
        }
        .confirmationDialog(
            "Enjoyed it? Write a review",
            isPresented: $suggestsReview,
            titleVisibility: .visible
        ) {
            Button("Write a Review") { reviewTarget = currentItem }
            Button("Not Now", role: .cancel) {}
        }
    }

    // MARK: - Sections

    private func header(backdropPath: String?, title: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            PosterImage(path: backdropPath, kind: .backdrop)
                .frame(maxWidth: .infinity)
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(verbatim: title)
                .font(.dsHeroTitle)
                .foregroundStyle(.white)
                .lineLimit(3)
                .padding(DSSpacing.lg)
        }
        // Stretchy header: overscroll estica o backdrop ancorado embaixo
        // (topo fica pinado); rolando para cima ele sai a 50% da velocidade
        // (parallax). Efeito puramente geométrico — ok sob Reduce Motion.
        .visualEffect { content, proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let height = proxy.size.height
            return content
                .scaleEffect(minY > 0 ? 1 + minY / height : 1, anchor: .bottom)
                .offset(y: minY < 0 ? -minY * 0.5 : 0)
        }
    }

    @ViewBuilder
    private func content(_ details: MovieDetailModel.Details) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                // Em tamanhos de acessibilidade a linha pills + gauge estoura
                // a largura; empilha na vertical (sem scroll horizontal).
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        InfoPillRow(pills: pills(for: details.movie))
                        ratingBlock(details.movie)
                    }
                } else {
                    HStack(alignment: .top, spacing: DSSpacing.md) {
                        // wraps: as pills quebram linha no espaço disponível
                        // — nunca passam por baixo do gauge.
                        InfoPillRow(pills: pills(for: details.movie), wraps: true)
                        Spacer(minLength: DSSpacing.md)
                        ratingBlock(details.movie)
                    }
                }

                if let directors = crewNames(details.crew, job: "Director") {
                    Text("Directed by \(directors)")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DSSpacing.lg)

            if let tagline = details.movie.tagline, !tagline.isEmpty {
                Text(verbatim: tagline)
                    .font(.body.weight(.medium).italic())
                    .padding(.horizontal, DSSpacing.lg)
            }

            if let overview = details.movie.overview, !overview.isEmpty {
                Text(verbatim: overview)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)
            }

            if !details.videos.isEmpty {
                TrailerSection(videos: details.videos) { trailer in
                    presentedTrailer = trailer
                }
            }

            if !details.cast.isEmpty {
                CastCarousel(members: details.cast)
            }

            if let providers = details.providers {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    SectionHeader("Where to Watch")
                    ProviderRow(title: "Stream", providers: providers.flatrate ?? [])
                    ProviderRow(title: "Rent", providers: providers.rent ?? [])
                    ProviderRow(title: "Buy", providers: providers.buy ?? [])
                }
            }

            if !details.recommendations.isEmpty {
                MediaCarousel(title: "You Might Also Like", items: details.recommendations, zoomScope: "recs")
            }
        }
        .padding(.vertical, DSSpacing.lg)
        // O bottom bar flutuante (botões ~44pt + margens) não gera safe area
        // própria; sem esta folga a última seção fica presa embaixo dele.
        .padding(.bottom, 96)
    }

    private func pills(for movie: MovieDetails) -> [InfoPillRow.Pill] {
        var pills: [InfoPillRow.Pill] = []
        if let releaseDate = movie.releaseDate, releaseDate.count >= 4 {
            pills.append(.init(id: "year", text: "\(releaseDate.prefix(4))", systemImage: "calendar"))
        }
        if let runtime = movie.formattedRuntime {
            pills.append(.init(id: "runtime", text: "\(runtime)", systemImage: "clock"))
        }
        for genre in movie.genres ?? [] {
            pills.append(.init(id: "genre-\(genre.id)", text: "\(genre.name)"))
        }
        return pills
    }

    /// Gauge + contagem de votos logo abaixo (compacta: "26K votes").
    @ViewBuilder
    private func ratingBlock(_ movie: MovieDetails) -> some View {
        if let vote = movie.voteAverage, vote > 0 {
            VStack(spacing: DSSpacing.xs) {
                RatingGauge(value: vote)
                    .frame(width: gaugeSize, height: gaugeSize)
                if let count = movie.voteCount, count > 0 {
                    Text("\(count.formatted(.number.notation(.compactName))) votes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    /// Nomes do crew para um job, formatados como lista ("A and B").
    private func crewNames(_ crew: [CrewMember], job: String) -> String? {
        let names = crew.filter { $0.job == job }.map(\.name)
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }

    // MARK: - Watchlist

    private var currentItem: MediaItem? {
        if case .loaded(let details) = model.state {
            return details.movie.mediaItem
        }
        return preview
    }

    private func refreshWatchlistState() {
        if store.isWatched(movieID: movieID) {
            watchlistState = .watched
        } else if store.isInWatchlist(movieID: movieID) {
            watchlistState = .toWatch
        } else {
            watchlistState = .none
        }
        hasReview = reviewStore.hasReview(movieID: movieID)
    }

    private func toggleWatchlist() {
        guard let item = currentItem else { return }
        do {
            if watchlistState == .toWatch {
                try store.removeFromWatchlist(movieID: item.id)
                SpotlightIndexer.deindex(movieID: item.id)
            } else {
                try store.addToWatchlist(item)
                SpotlightIndexer.index(item)
            }
            refreshWatchlistState()
        } catch {
            assertionFailure("Watchlist toggle failed: \(error)")
        }
    }

    private func toggleWatched() {
        guard let item = currentItem else { return }
        do {
            if watchlistState == .watched {
                try store.unmarkWatched(movieID: item.id)
            } else {
                try store.markWatched(item)
                if !hasReview {
                    suggestsReview = true
                }
            }
            refreshWatchlistState()
        } catch {
            assertionFailure("Watched toggle failed: \(error)")
        }
    }
}
#Preview {
    NavigationStack {
        MovieDetailScreen(item: .dsPreview)
    }
    .modelContainer(try! ModelContainerFactory.makeInMemory())
}

