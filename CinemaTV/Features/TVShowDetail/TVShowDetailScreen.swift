//
//  TVShowDetailScreen.swift
//  CinemaTV
//
//  Detail de série: backdrop + seções (pills, nota, sinopse, temporadas com
//  progresso, trailers, elenco, provedores, recomendações) + botão Follow no
//  bottom bar. Espelha o MovieDetailScreen; o tracking substitui a watchlist.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct TVShowDetailScreen: View {
    @Environment(\.tmdbClient) private var client
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(AppRouter.self) private var router
    // O gauge contém texto: frame fixo cortava a nota em tamanhos de
    // acessibilidade.
    @ScaledMetric(relativeTo: .caption) private var gaugeSize: CGFloat = 48
    @State private var model = TVShowDetailModel()
    @State private var isFollowing = false
    @State private var seasonProgress: [Int: WatchProgress] = [:]
    @State private var presentedTrailer: Video?
    @State private var confirmsUnfollow = false

    private let showID: Int
    /// Dados já conhecidos do card de origem, para pintar o header
    /// imediatamente durante a zoom transition.
    private let preview: MediaItem?

    init(item: MediaItem) {
        self.showID = item.id
        self.preview = item
    }

    init(showID: Int) {
        self.showID = showID
        self.preview = nil
    }

    private var trackingStore: TVShowTrackingStore {
        TVShowTrackingStore(context: modelContext)
    }

    var body: some View {
        ScrollView {
            switch model.state {
            case .idle, .loading:
                header(backdropPath: preview?.backdropPath, title: preview?.title ?? "")
            case .loaded(let details):
                header(backdropPath: details.show.backdropPath ?? preview?.backdropPath, title: details.show.name)
                content(details)
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await model.retry(client: client, showID: showID) }
                }
                .padding(.top, DSSpacing.xxl)
            }
        }
        .ignoresSafeArea(edges: .top)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button {
                    toggleFollow()
                } label: {
                    // HStack manual: no bottom bar o sistema colapsa Label
                    // para ícone-só, e esta ação precisa do texto.
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: isFollowing ? "checkmark.circle.fill" : "plus.circle")
                            .contentTransition(.symbolEffect(.replace))
                        Text(isFollowing ? "Following" : "Follow")
                    }
                }
                // Follow precisa do payload completo de temporadas.
                .disabled(loadedDetails == nil)
                // O símbolo checkmark herda o trait Selected da acessibilidade.
                .accessibilityRemoveTraits(.isSelected)

                Spacer()
            }
        }
        .sensoryFeedback(.success, trigger: isFollowing)
        .task {
            refreshTrackingState()
            await model.load(client: client, showID: showID)
            reconcileAfterLoad()
        }
        // Ao voltar da tela de temporada, o progresso das rails muda.
        .onAppear { refreshTrackingState() }
        .sheet(item: $presentedTrailer) { trailer in
            YouTubePlayerView(video: trailer)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Unfollow this show?",
            isPresented: $confirmsUnfollow,
            titleVisibility: .visible
        ) {
            Button("Unfollow", role: .destructive) { unfollow() }
            Button("Keep Following", role: .cancel) {}
        } message: {
            Text("Your episode progress will be removed.")
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
        // Stretchy header idêntico ao MovieDetail (efeito geométrico, ok
        // sob Reduce Motion).
        .visualEffect { content, proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let height = proxy.size.height
            return content
                .scaleEffect(minY > 0 ? 1 + minY / height : 1, anchor: .bottom)
                .offset(y: minY < 0 ? -minY * 0.5 : 0)
        }
    }

    @ViewBuilder
    private func content(_ details: TVShowDetailModel.Details) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                // Em tamanhos de acessibilidade a linha pills + gauge estoura
                // a largura; empilha na vertical (sem scroll horizontal).
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: DSSpacing.md) {
                        InfoPillRow(pills: pills(for: details.show))
                        ratingBlock(details.show)
                    }
                } else {
                    HStack(alignment: .top, spacing: DSSpacing.md) {
                        // wraps: as pills quebram linha no espaço disponível
                        // — nunca passam por baixo do gauge.
                        InfoPillRow(pills: pills(for: details.show), wraps: true)
                        Spacer(minLength: DSSpacing.md)
                        ratingBlock(details.show)
                    }
                }

                if let creators = creatorNames(details.show) {
                    Text("Created by \(creators)")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }

                if let networks = networkNames(details.show) {
                    Text(verbatim: networks)
                        .font(.dsCaption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, DSSpacing.lg)

            if let tagline = details.show.tagline, !tagline.isEmpty {
                Text(verbatim: tagline)
                    .font(.body.weight(.medium).italic())
                    .padding(.horizontal, DSSpacing.lg)
            }

            if let overview = details.show.overview, !overview.isEmpty {
                Text(verbatim: overview)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)
            }

            if let next = details.show.nextEpisodeToAir {
                nextEpisodeCallout(next)
            }

            if !regularSeasons(of: details.show).isEmpty {
                SeasonsCarousel(
                    title: "Seasons",
                    seasons: regularSeasons(of: details.show),
                    progress: { seasonProgress[$0.seasonNumber] },
                    zoomScope: "seasons"
                ) { season, sourceID in
                    router.push(Route.season(
                        tvShowID: showID,
                        seasonNumber: season.seasonNumber,
                        sourceID: sourceID
                    ))
                }
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
                MediaCarousel(title: "You Might Also Like", items: details.recommendations, zoomScope: "tvRecs")
            }
        }
        .padding(.vertical, DSSpacing.lg)
        // O bottom bar flutuante (botão ~44pt + margens) não gera safe area
        // própria; sem esta folga a última seção fica presa embaixo dele.
        .padding(.bottom, 96)
    }

    private func pills(for show: TVShowDetails) -> [InfoPillRow.Pill] {
        var pills: [InfoPillRow.Pill] = []
        if let firstAirDate = show.firstAirDate, firstAirDate.count >= 4 {
            pills.append(.init(id: "year", text: "\(firstAirDate.prefix(4))", systemImage: "calendar"))
        }
        if let seasons = show.numberOfSeasons, seasons > 0 {
            pills.append(.init(id: "seasons", text: "\(seasons) Seasons", systemImage: "square.stack"))
        }
        if let episodes = show.numberOfEpisodes, episodes > 0 {
            pills.append(.init(id: "episodes", text: "\(episodes) episodes", systemImage: "play.tv"))
        }
        for genre in show.genres ?? [] {
            pills.append(.init(id: "genre-\(genre.id)", text: "\(genre.name)"))
        }
        return pills
    }

    /// Gauge + contagem de votos logo abaixo (compacta: "21K votes").
    @ViewBuilder
    private func ratingBlock(_ show: TVShowDetails) -> some View {
        if let vote = show.voteAverage, vote > 0 {
            VStack(spacing: DSSpacing.xs) {
                RatingGauge(value: vote)
                    .frame(width: gaugeSize, height: gaugeSize)
                if let count = show.voteCount, count > 0 {
                    Text("\(count.formatted(.number.notation(.compactName))) votes")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func creatorNames(_ show: TVShowDetails) -> String? {
        let names = (show.createdBy ?? []).map(\.name)
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }

    private func networkNames(_ show: TVShowDetails) -> String? {
        let names = (show.networks ?? []).map(\.name)
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }

    /// Série em exibição: quando o TMDB anuncia o próximo episódio, o card
    /// glass antecipa "o que vem aí" antes da rail de temporadas.
    private func nextEpisodeCallout(_ next: EpisodeSummary) -> some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3)
                .foregroundStyle(DSColor.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: DSSpacing.xs) {
                Text("Next episode")
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                Text(verbatim: episodeLabel(next))
                    .font(.dsCardTitle)
                if let date = formattedAirDate(next.airDate) {
                    Text(verbatim: date)
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(DSSpacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.card))
        .padding(.horizontal, DSSpacing.lg)
        .accessibilityElement(children: .combine)
    }

    private func episodeLabel(_ episode: EpisodeSummary) -> String {
        let code = "S\(episode.seasonNumber ?? 0)E\(episode.episodeNumber)"
        return episode.name.isEmpty ? code : "\(code) · \(episode.name)"
    }

    private func formattedAirDate(_ airDate: String?) -> String? {
        guard let airDate,
              let date = try? Date(airDate, strategy: .iso8601.year().month().day())
        else { return nil }
        // O parse ISO cai em meia-noite UTC; formatar em GMT evita a data
        // regredir um dia em fusos negativos.
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: .gmt))
    }

    private func regularSeasons(of show: TVShowDetails) -> [SeasonSummary] {
        // Specials (season 0) ficam fora do tracking nesta fase.
        (show.seasons ?? []).filter { $0.seasonNumber > 0 }
    }

    // MARK: - Tracking

    private var loadedDetails: TVShowDetails? {
        if case .loaded(let details) = model.state {
            return details.show
        }
        return nil
    }

    private func refreshTrackingState() {
        isFollowing = trackingStore.isFollowing(showID: showID)
        guard isFollowing else {
            seasonProgress = [:]
            return
        }
        var progress: [Int: WatchProgress] = [:]
        if let seasons = loadedDetails.map(regularSeasons(of:)) {
            for season in seasons {
                progress[season.seasonNumber] = trackingStore.seasonProgress(
                    showID: showID,
                    seasonNumber: season.seasonNumber
                )
            }
        }
        seasonProgress = progress
    }

    /// Série já acompanhada pode ter ganhado temporadas/episódios novos
    /// desde o follow; o reload do detalhe reconcilia o skeleton local.
    private func reconcileAfterLoad() {
        guard isFollowing, let show = loadedDetails else {
            refreshTrackingState()
            return
        }
        do {
            try trackingStore.refreshMetadata(from: show)
        } catch {
            assertionFailure("Tracking metadata refresh failed: \(error)")
        }
        refreshTrackingState()
    }

    private func toggleFollow() {
        if isFollowing {
            confirmsUnfollow = true
        } else {
            guard let show = loadedDetails else { return }
            do {
                try trackingStore.follow(show)
                refreshTrackingState()
            } catch {
                assertionFailure("Follow failed: \(error)")
            }
        }
    }

    private func unfollow() {
        do {
            try trackingStore.unfollow(showID: showID)
            refreshTrackingState()
        } catch {
            assertionFailure("Unfollow failed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        TVShowDetailScreen(showID: 1399)
    }
    .environment(AppRouter())
    .modelContainer(try! ModelContainerFactory.makeInMemory())
}
