//
//  SeasonScreen.swift
//  CinemaTV
//
//  Lista de episódios de uma temporada com check de assistido por episódio,
//  bulk da temporada inteira no bottom bar e barra de progresso no header.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

struct SeasonScreen: View {
    @Environment(\.tmdbClient) private var client
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(AppRouter.self) private var router
    @State private var model = SeasonModel()
    @State private var isFollowing = false
    @State private var watchedNumbers: Set<Int> = []
    @State private var hasNextSeason = false
    @State private var bulkTrigger = false
    @State private var scrollPosition = ScrollPosition()
    // Compacta e centralizada como a pill da referência; escala com o texto
    // para "12/62" não truncar em tamanhos de acessibilidade.
    @ScaledMetric(relativeTo: .footnote) private var scrubberWidth: CGFloat = 168

    private let tvShowID: Int
    private let seasonNumber: Int

    init(tvShowID: Int, seasonNumber: Int) {
        self.tvShowID = tvShowID
        self.seasonNumber = seasonNumber
    }

    private var trackingStore: TVShowTrackingStore {
        TVShowTrackingStore(context: modelContext)
    }

    var body: some View {
        ScrollView {
            switch model.state {
            case .idle, .loading:
                LoadingStateView {
                    VStack(alignment: .leading, spacing: DSSpacing.lg) {
                        Text(verbatim: "Season")
                            .font(.dsHeroTitle)
                        ForEach(0..<6, id: \.self) { _ in
                            EpisodeRow(
                                episode: EpisodeSummary(
                                    id: 0,
                                    name: String(repeating: " ", count: 24),
                                    overview: String(repeating: " ", count: 80),
                                    episodeNumber: 0
                                ),
                                isWatched: false,
                                onToggle: {}
                            )
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                    .padding(.top, DSSpacing.lg)
                }
            case .loaded(let details):
                content(details)
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await model.retry(client: client, tvShowID: tvShowID, seasonNumber: seasonNumber) }
                }
                .padding(.top, DSSpacing.xxl)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        // Barra própria em vez de ToolbarItemGroup(.bottomBar): o scrubber
        // precisa de long-press + drag, gesto que o bottom bar do sistema
        // não acomoda.
        .safeAreaInset(edge: .bottom) {
            if isFollowing, case .loaded(let details) = model.state, !details.episodes.isEmpty {
                seasonToolbar(details)
            }
        }
        .scrollPosition($scrollPosition)
        .sensoryFeedback(.success, trigger: bulkTrigger)
        // Ao voltar do detalhe do episódio, os checks podem ter mudado lá.
        .onAppear { refreshTrackingState() }
        .task {
            refreshTrackingState()
            await model.load(client: client, tvShowID: tvShowID, seasonNumber: seasonNumber)
            enrichUpNextCache()
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private func content(_ details: SeasonDetails) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            headerBlock(details)

            if !isFollowing {
                followBanner
            }

            LazyVStack(alignment: .leading, spacing: DSSpacing.lg) {
                ForEach(details.episodes) { episode in
                    // Row inteira navega para o detalhe (zoom saindo do
                    // still); só o check exige follow.
                    let selection = EpisodeSelection(
                        tvShowID: tvShowID,
                        seasonNumber: seasonNumber,
                        episodes: details.episodes,
                        initialEpisodeNumber: episode.episodeNumber,
                        sourceID: "episode-\(episode.id)"
                    )
                    NavigationLink(value: selection) {
                        EpisodeRow(
                            episode: episode,
                            isWatched: watchedNumbers.contains(episode.episodeNumber),
                            isToggleEnabled: isFollowing,
                            zoomSourceID: selection.sourceID
                        ) {
                            toggle(episode)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            // Alvo do scrollTo do botão "próximo não assistido".
            .scrollTargetLayout()
            .padding(.horizontal, DSSpacing.lg)
        }
        .padding(.vertical, DSSpacing.lg)
        .padding(.bottom, DSSpacing.xxl)
    }

    @ViewBuilder
    private func headerBlock(_ details: SeasonDetails) -> some View {
        // Poster ao lado do texto; em tamanhos de acessibilidade empilha.
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: DSSpacing.md))
            : AnyLayout(HStackLayout(alignment: .top, spacing: DSSpacing.md))

        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            layout {
                if details.posterPath != nil {
                    PosterImage(path: details.posterPath, kind: .poster)
                        .frame(width: 110)
                        .clipShape(.rect(cornerRadius: DSRadius.poster))
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: DSSpacing.xs) {
                    Text(verbatim: details.name)
                        .font(.dsHeroTitle)
                        .accessibilityAddTraits(.isHeader)
                    if let year = details.airYear {
                        Text(verbatim: year)
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                    }
                    if let overview = details.overview, !overview.isEmpty {
                        Text(verbatim: overview)
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if isFollowing {
                let progress = progress(for: details)
                Text("\(progress.watched) of \(progress.total) watched")
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
                    .contentTransition(.numericText(value: Double(progress.watched)))
                    .animation(DSMotion.respecting(reduceMotion, DSMotion.snappy), value: progress.watched)
                DSProgressBar(progress: progress.fraction)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }

    /// Sem follow não há onde gravar o check; o banner resolve na hora.
    private var followBanner: some View {
        HStack(spacing: DSSpacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.title3)
                .foregroundStyle(DSColor.accent)
                .accessibilityHidden(true)
            Text("Follow this show to track episodes.")
                .font(.dsCaption)
            Spacer()
            Button("Follow") {
                followShow()
            }
            .buttonStyle(.glassProminent)
        }
        .padding(DSSpacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.card))
        .padding(.horizontal, DSSpacing.lg)
    }

    // MARK: - Bottom toolbar

    /// Círculo — pill — círculo, como a referência: Mark All à esquerda,
    /// scrubber compacto centralizado e "próximo não assistido" à direita.
    private func seasonToolbar(_ details: SeasonDetails) -> some View {
        let progress = progress(for: details)
        // Só episódios já exibidos são marcáveis; sem nenhum, as ações de
        // marcar ficam desabilitadas (temporada inédita ou toda assistida).
        let hasMarkableEpisode = details.episodes.contains {
            !watchedNumbers.contains($0.episodeNumber) && $0.hasAired
        }

        return GlassEffectContainer(spacing: DSSpacing.md) {
            HStack(spacing: DSSpacing.md) {
                Button {
                    if progress.isComplete {
                        unmarkSeason()
                    } else {
                        markSeason(details)
                    }
                } label: {
                    Image(systemName: progress.isComplete ? "circle.slash" : "checkmark.circle")
                        .font(.title3.weight(.semibold))
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .disabled(!progress.isComplete && !hasMarkableEpisode)
                .opacity(!progress.isComplete && !hasMarkableEpisode ? 0.4 : 1)
                .accessibilityLabel(
                    progress.isComplete ? Text("Unmark All") : Text("Mark Season Watched")
                )
                // O símbolo checkmark herda o trait Selected da acessibilidade.
                .accessibilityRemoveTraits(.isSelected)

                Spacer(minLength: 0)

                SeasonScrubber(watched: progress.watched, total: progress.total) { target in
                    scrub(to: target, details: details)
                }
                .frame(width: scrubberWidth)

                Spacer(minLength: 0)

                // Incompleta: marca o próximo episódio não visto (episódio a
                // episódio) e rola até o seguinte. Completa com próxima
                // temporada no skeleton: vira "próxima temporada".
                let goesToNextSeason = progress.isComplete && hasNextSeason
                Button {
                    if goesToNextSeason {
                        router.push(Route.season(
                            tvShowID: tvShowID,
                            seasonNumber: seasonNumber + 1,
                            sourceID: nil
                        ))
                    } else {
                        markNextUnwatched(in: details)
                    }
                } label: {
                    Image(systemName: goesToNextSeason ? "arrow.right" : "arrow.down")
                        .contentTransition(.symbolEffect(.replace))
                        .animation(DSMotion.respecting(reduceMotion, DSMotion.snappy), value: goesToNextSeason)
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .disabled(!goesToNextSeason && !hasMarkableEpisode)
                .opacity(!goesToNextSeason && !hasMarkableEpisode ? 0.4 : 1)
                .accessibilityLabel(
                    goesToNextSeason ? Text("Next Season") : Text("Mark Next Episode")
                )
            }
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.bottom, DSSpacing.sm)
    }

    /// Marca o primeiro episódio ainda não assistido e rola até o novo
    /// próximo — cada tap avança um episódio no acompanhamento.
    private func markNextUnwatched(in details: SeasonDetails) {
        // Pula episódios inéditos: só o próximo já exibido é marcável.
        guard let next = details.episodes.first(where: {
            !watchedNumbers.contains($0.episodeNumber) && $0.hasAired
        }) else {
            return
        }
        do {
            try trackingStore.markEpisodeWatched(next, showID: tvShowID)
        } catch {
            assertionFailure("Mark next episode failed: \(error)")
            return
        }
        withAnimation(DSMotion.respecting(reduceMotion, DSMotion.snappy)) {
            refreshTrackingState()
        }
        enrichUpNextCache()
        // watchedNumbers já reflete o episódio recém-marcado.
        if let upcoming = details.episodes.first(where: { !watchedNumbers.contains($0.episodeNumber) }) {
            withAnimation(DSMotion.respecting(reduceMotion, DSMotion.standard)) {
                scrollPosition.scrollTo(id: upcoming.id, anchor: .center)
            }
        }
    }

    /// Semântica de prefixo: alvo N = os N primeiros episódios assistidos,
    /// o resto desmarcado — arrastar para a direita marca, para a esquerda
    /// desmarca a partir do fim.
    private func scrub(to target: Int, details: SeasonDetails) {
        do {
            for (index, episode) in details.episodes.enumerated() {
                let shouldWatch = index < target
                let isWatched = watchedNumbers.contains(episode.episodeNumber)
                if shouldWatch && !isWatched {
                    try trackingStore.markEpisodeWatched(episode, showID: tvShowID)
                } else if !shouldWatch && isWatched {
                    try trackingStore.unmarkEpisodeWatched(
                        showID: tvShowID,
                        seasonNumber: seasonNumber,
                        episodeNumber: episode.episodeNumber
                    )
                }
            }
            withAnimation(DSMotion.respecting(reduceMotion, DSMotion.snappy)) {
                refreshTrackingState()
            }
            enrichUpNextCache()
        } catch {
            assertionFailure("Scrub failed: \(error)")
        }
    }

    // MARK: - Tracking

    private func progress(for details: SeasonDetails) -> WatchProgress {
        WatchProgress(watched: watchedNumbers.count, total: details.episodes.count)
    }

    private func refreshTrackingState() {
        isFollowing = trackingStore.isFollowing(showID: tvShowID)
        watchedNumbers = trackingStore.watchedEpisodeNumbers(showID: tvShowID, seasonNumber: seasonNumber)
        // O follow grava o skeleton de todas as temporadas, então a
        // existência da próxima sai do store, sem rede. isDeleted: relações
        // ainda contêm modelos deletados antes do save.
        hasNextSeason = ((try? trackingStore.show(id: tvShowID))?.seasons ?? [])
            .contains { !$0.isDeleted && $0.seasonNumber == seasonNumber + 1 }
    }

    /// Preenche nome/still do Up Next quando o próximo episódio está nesta
    /// temporada (a tab Tracking nunca busca rede).
    private func enrichUpNextCache() {
        guard isFollowing, case .loaded(let details) = model.state else { return }
        try? trackingStore.updateUpNextCache(showID: tvShowID, from: details)
    }

    private func toggle(_ episode: EpisodeSummary) {
        do {
            if watchedNumbers.contains(episode.episodeNumber) {
                try trackingStore.unmarkEpisodeWatched(
                    showID: tvShowID,
                    seasonNumber: seasonNumber,
                    episodeNumber: episode.episodeNumber
                )
            } else {
                try trackingStore.markEpisodeWatched(episode, showID: tvShowID)
            }
            refreshTrackingState()
            enrichUpNextCache()
        } catch {
            assertionFailure("Episode toggle failed: \(error)")
        }
    }

    private func markSeason(_ details: SeasonDetails) {
        do {
            try trackingStore.markSeasonWatched(details, showID: tvShowID)
            refreshTrackingState()
            enrichUpNextCache()
            bulkTrigger.toggle()
        } catch {
            assertionFailure("Mark season failed: \(error)")
        }
    }

    private func unmarkSeason() {
        do {
            try trackingStore.unmarkSeasonWatched(showID: tvShowID, seasonNumber: seasonNumber)
            refreshTrackingState()
            enrichUpNextCache()
            bulkTrigger.toggle()
        } catch {
            assertionFailure("Unmark season failed: \(error)")
        }
    }

    private func followShow() {
        Task {
            do {
                let show = try await model.fetchShowDetails(client: client, tvShowID: tvShowID)
                try trackingStore.follow(show)
                refreshTrackingState()
            } catch {
                assertionFailure("Follow from season failed: \(error)")
            }
        }
    }
}

#Preview {
    NavigationStack {
        SeasonScreen(tvShowID: 1399, seasonNumber: 1)
    }
    .environment(AppRouter())
    .modelContainer(try! ModelContainerFactory.makeInMemory())
}
