//
//  HomeScreen.swift
//  CinemaTV
//
//  Home de Movies: hero (now playing) + rails por categoria.
//  Substitui HomeView/MoviesView/DiscoverView.
//

import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct HomeScreen: View {
    /// Segmento da Discover: filmes (conteúdo original) ou séries.
    private enum MediaKind: Hashable {
        case movies
        case shows
    }

    @Environment(\.tmdbClient) private var client
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = HomeScreenModel()
    @State private var tvModel = TVHomeModel()
    @State private var mediaKind: MediaKind = .movies
    @State private var motion = MotionTiltManager()
    @State private var streamingRefreshID = 0

    var body: some View {
        Group {
            switch mediaKind {
            case .movies:
                moviesBody
            case .shows:
                showsBody
            }
        }
        // O picker vive num safeAreaInset (não mais num VStack acima do
        // scroll): o feed rola POR TRÁS dele e da nav bar, com o edge
        // effect .soft suavizando a faixa do header. O controle continua
        // o segmented nativo de sempre.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .safeAreaInset(edge: .top) {
            Picker("Media Type", selection: $mediaKind) {
                Text("Movies").tag(MediaKind.movies)
                Text("TV Shows").tag(MediaKind.shows)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DSSpacing.lg)
        }
        .navigationTitle("Discover")
        .toolbarMinimizationBehavior(.onScrollDown, for: .navigationBar)
        .onAppear {
            if !reduceMotion {
                motion.start()
            }
        }
        .onDisappear {
            motion.stop()
        }
        // Carga lazy por segmento: séries só buscam rede na primeira visita.
        .task(id: mediaKind) {
            switch mediaKind {
            case .movies:
                await model.load(client: client)
            case .shows:
                await tvModel.load(client: client)
            }
        }
    }

    // MARK: - Movies

    private var moviesBody: some View {
        Group {
            switch model.state {
            case .idle, .loading:
                LoadingStateView {
                    homeSkeleton
                }
            case .loaded(let content):
                loadedContent(content)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.blurReplace))
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await model.retry(client: client) }
                }
            }
        }
        .animation(DSMotion.respecting(reduceMotion, DSMotion.entrance), value: model.isLoaded)
    }

    private func loadedContent(_ content: HomeScreenModel.Content) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DSSpacing.xl) {
                TiltedHeroCarousel(items: Array(content.nowPlaying.prefix(6)), motion: motion)

                MediaCarousel(title: "Upcoming", items: content.upcoming, zoomScope: "upcoming") {
                    router.discoverPath.append(Route.movieList(category: .upcoming))
                }
                MediaCarousel(title: "Popular", items: content.popular, zoomScope: "popular") {
                    router.discoverPath.append(Route.movieList(category: .popular))
                }
                StreamingDiscoverySection(kind: .movie, refreshID: streamingRefreshID)
                MediaCarousel(title: "Top Rated", items: content.topRated, zoomScope: "topRated") {
                    router.discoverPath.append(Route.movieList(category: .topRated))
                }
                DiscoverPortalCard(items: Array(content.discover.prefix(3))) {
                    router.discoverPath.append(Route.discoverDeck)
                }
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .accessibilityIdentifier("discover.movies.feed")
        .refreshable {
            await model.refresh(client: client)
            streamingRefreshID += 1
        }
    }

    private var homeSkeleton: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DSSpacing.xl) {
                HeroCarousel(items: [.dsPreview])
                MediaCarousel(title: "Upcoming", items: skeletonItems)
                MediaCarousel(title: "Popular", items: skeletonItems)
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .scrollDisabled(true)
    }

    private var skeletonItems: [MediaItem] {
        (1...6).map { index in
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

    // MARK: - TV Shows

    private var showsBody: some View {
        Group {
            switch tvModel.state {
            case .idle, .loading:
                LoadingStateView {
                    showsSkeleton
                }
            case .loaded(let content):
                loadedShowsContent(content)
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition(.blurReplace))
            case .failed(let message):
                ErrorStateView(message: message) {
                    Task { await tvModel.retry(client: client) }
                }
            }
        }
        .animation(DSMotion.respecting(reduceMotion, DSMotion.entrance), value: tvModel.isLoaded)
    }

    private func loadedShowsContent(_ content: TVHomeModel.Content) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DSSpacing.xl) {
                TiltedHeroCarousel(items: Array(content.airingToday.prefix(6)), motion: motion)

                MediaCarousel(title: "Airing Today", items: content.airingToday, zoomScope: "tvAiring") {
                    router.discoverPath.append(Route.tvShowList(category: .airingToday))
                }
                MediaCarousel(title: "On the Air", items: content.onTheAir, zoomScope: "tvOnAir") {
                    router.discoverPath.append(Route.tvShowList(category: .onTheAir))
                }
                MediaCarousel(title: "Popular", items: content.popular, zoomScope: "tvPopular") {
                    router.discoverPath.append(Route.tvShowList(category: .popular))
                }
                StreamingDiscoverySection(kind: .tv, refreshID: streamingRefreshID)
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .accessibilityIdentifier("discover.tv.feed")
        .refreshable {
            await tvModel.refresh(client: client)
            streamingRefreshID += 1
        }
    }

    private var showsSkeleton: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DSSpacing.xl) {
                HeroCarousel(items: [.dsPreview])
                MediaCarousel(title: "Airing Today", items: skeletonItems)
                MediaCarousel(title: "Popular", items: skeletonItems)
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .scrollDisabled(true)
    }
}
// MARK: - Hero com tilt confinado

/// Confina a leitura do tilt ao hero: motion.roll/pitch mudam a ~30Hz, e
/// lê-los direto no body da HomeScreen re-avaliava a tela inteira (picker,
/// rails, portal) a cada tick do giroscópio — os engasgos ao entrar na Home.
private struct TiltedHeroCarousel: View {
    let items: [MediaItem]
    let motion: MotionTiltManager

    var body: some View {
        HeroCarousel(items: items)
            .environment(\.dsTilt, DSTiltValue(roll: motion.roll, pitch: motion.pitch))
    }
}

// MARK: - Portal do Discover

/// Card full-width que leva ao fluxo Discover: colagem dos primeiros posters
/// do discover ao fundo, título + convite + chevron glass.
private struct DiscoverPortalCard: View {
    let items: [MediaItem]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                LinearGradient(
                    colors: [Color(white: 0.16), .black],
                    startPoint: .topLeading,
                    endPoint: .bottom
                )

                // Colagem decorativa: posters rotacionados, apagados.
                HStack(spacing: -DSSpacing.xl) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        PosterImage(path: item.posterPath, kind: .thumbnail)
                            .frame(width: 76)
                            .clipShape(.rect(cornerRadius: DSRadius.poster))
                            .rotationEffect(.degrees(Double(index - 1) * 10))
                            .offset(y: CGFloat(abs(index - 1)) * 8)
                    }
                }
                .opacity(0.35)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, DSSpacing.xxl)

                HStack(spacing: DSSpacing.lg) {
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text("Discover")
                            .font(.dsSectionTitle)
                            .foregroundStyle(.white)
                        Text("Swipe to find your next movie")
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .padding(DSSpacing.md)
                        .glassEffect(.regular, in: .circle)
                        .accessibilityHidden(true)
                }
                .padding(DSSpacing.lg)
            }
            .frame(height: 150)
            .clipShape(.rect(cornerRadius: DSRadius.card))
            .padding(.horizontal, DSSpacing.lg)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Discover"))
        .accessibilityHint(Text("Swipe to find your next movie"))
    }
}


#Preview {
    NavigationStack {
        HomeScreen()
    }
    .environment(AppRouter())
    .modelContainer(try! ModelContainerFactory.makeInMemory())
}

/// Loaded when its position in Discover becomes visible, separately from the
/// main feed so provider requests cannot delay the hero and existing rails.
private struct StreamingDiscoverySection: View {
    private static let providerBatchSize = 10

    let kind: StreamingMediaKind
    let refreshID: Int

    @Environment(\.tmdbClient) private var client
    @AppStorage(TMDBRegion.overrideKey, store: TMDBRegion.store) private var regionOverride = ""
    @State private var providers: [WatchProvider] = []
    @State private var visibleProviderCount = providerBatchSize
    @State private var providerResults: [Int: StreamingProviderResult] = [:]
    @State private var providerTasks: [UUID: Task<Void, Never>] = [:]
    @State private var isLoadingCatalog = false
    @State private var catalogError: String?
    @State private var catalogRetryID = 0
    @State private var catalogVersion = 0
    @State private var loadedCatalogKey: String?

    var body: some View {
        LazyVStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                SectionHeader("Newest titles to stream")

                Text("Titles sorted by release date and available by subscription in \(TMDBRegion.localizedName(for: TMDBRegion.current))")
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)

                Text("Availability data provided by JustWatch")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, DSSpacing.lg)
            }

            if isLoadingCatalog {
                ProgressView("Loading streaming services")
                    .padding(.horizontal, DSSpacing.lg)
            } else if let catalogError {
                retryView(message: catalogError) { catalogRetryID += 1 }
            } else if providers.isEmpty {
                Text("No streaming services found for this region.")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)
            } else {
                ForEach(Array(providers.prefix(visibleProviderCount))) { provider in
                    StreamingProviderRail(
                        provider: provider,
                        kind: kind,
                        region: TMDBRegion.current,
                        refreshID: refreshID,
                        results: $providerResults,
                        tasks: $providerTasks
                    )
                }

                if visibleProviderCount < providers.count {
                    Button("Show more services", systemImage: "chevron.down") {
                        visibleProviderCount = min(
                            visibleProviderCount + Self.providerBatchSize,
                            providers.count
                        )
                    }
                    .accessibilityIdentifier("streaming.showMore")
                    .accessibilityValue(Text("\(visibleProviderCount) of \(providers.count)"))
                    .padding(.horizontal, DSSpacing.lg)
                }
            }
        }
        .task(id: "\(kind)-\(regionOverride)-\(refreshID)-\(catalogRetryID)") {
            await loadCatalog()
        }
        .onDisappear {
            cancelProviderTasks()
        }
    }

    private func retryView(message: String, action: @escaping () -> Void) -> some View {
        HStack(spacing: DSSpacing.sm) {
            Text(verbatim: message)
                .font(.dsCaption)
                .foregroundStyle(.secondary)
            Button("Try Again", systemImage: "arrow.clockwise", action: action)
        }
        .padding(.horizontal, DSSpacing.lg)
    }

    private func loadCatalog() async {
        let region = TMDBRegion.current
        let key = "\(kind)-\(region)-\(refreshID)-\(catalogRetryID)"
        guard loadedCatalogKey != key else { return }
        catalogVersion += 1
        let version = catalogVersion
        isLoadingCatalog = true
        catalogError = nil
        cancelProviderTasks()
        providers = []
        visibleProviderCount = Self.providerBatchSize
        providerResults = [:]
        defer {
            if version == catalogVersion { isLoadingCatalog = false }
        }

        do {
            let query = StreamingAvailabilityQuery(
                kind: kind, region: region, providerID: 0, today: ""
            )
            let response: WatchProviderCatalogResponse = try await client.fetch(
                query.catalogEndpoint,
                parameters: query.catalogParameters
            )
            guard !Task.isCancelled, version == catalogVersion,
                  region == TMDBRegion.current else { return }
            providers = response.providers(for: region)
            loadedCatalogKey = key
        } catch {
            guard !Task.isCancelled, version == catalogVersion else { return }
            catalogError = error.localizedDescription
        }
    }

    private func cancelProviderTasks() {
        for task in providerTasks.values { task.cancel() }
        providerTasks = [:]
        providerResults = providerResults.filter { _, result in
            if case .loading = result { false } else { true }
        }
    }
}

private enum StreamingProviderResult {
    case loading(UUID)
    case loaded([MediaItem])
    case failed(String)
}

/// Limits the number of simultaneous Discover requests when a batch of
/// provider rails becomes visible at once.
private actor StreamingDiscoverGate {
    static let shared = StreamingDiscoverGate()

    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Void, Error>
    }

    private let maxConcurrentRequests = 3
    private var activeRequests = 0
    private var waiting: [Waiter] = []

    func run<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async throws -> Value {
        try await acquire()
        defer { release() }
        try Task.checkCancellation()
        return try await operation()
    }

    private func acquire() async throws {
        try Task.checkCancellation()
        if activeRequests < maxConcurrentRequests {
            activeRequests += 1
        } else {
            let id = UUID()
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { continuation in
                    waiting.append(Waiter(id: id, continuation: continuation))
                }
            } onCancel: {
                Task { await self.cancelWaiter(id) }
            }
        }
    }

    private func cancelWaiter(_ id: UUID) {
        guard let index = waiting.firstIndex(where: { $0.id == id }) else { return }
        waiting.remove(at: index).continuation.resume(throwing: CancellationError())
    }

    private func release() {
        if waiting.isEmpty {
            activeRequests -= 1
        } else {
            waiting.removeFirst().continuation.resume()
        }
    }
}

/// Each rail fetches its own subscription releases only when it becomes visible.
/// Results live in the parent so scrolling away and back does not refetch them.
private struct StreamingProviderRail: View {
    let provider: WatchProvider
    let kind: StreamingMediaKind
    let region: String
    let refreshID: Int
    @Binding var results: [Int: StreamingProviderResult]
    @Binding var tasks: [UUID: Task<Void, Never>]

    @Environment(\.tmdbClient) private var client
    @State private var retryID = 0

    private var result: StreamingProviderResult? { results[provider.providerId] }

    var body: some View {
        Group {
            if case .some(.loaded(let items)) = result, items.isEmpty {
                EmptyView()
            } else {
                VStack(alignment: .leading, spacing: DSSpacing.md) {
                    HStack(spacing: DSSpacing.sm) {
                        PosterImage(path: provider.logoPath, kind: .profile)
                            .frame(width: 32, height: 32)
                            .clipShape(.rect(cornerRadius: 7))
                            .accessibilityHidden(true)
                        Text(verbatim: provider.providerName)
                            .font(.dsSectionTitle)
                            .accessibilityAddTraits(.isHeader)
                    }
                    .padding(.horizontal, DSSpacing.lg)
                    .accessibilityIdentifier("streaming.provider.\(provider.providerId)")

                    switch result {
                    case .some(.loaded(let items)):
                        MediaCarousel(
                            items: items,
                            zoomScope: "streaming-\(provider.providerId)-\(kind)"
                        )
                        .accessibilityIdentifier("streaming.results.\(provider.providerId)")
                    case .some(.failed(let message)):
                        HStack(spacing: DSSpacing.sm) {
                            Text(verbatim: message)
                                .font(.dsCaption)
                                .foregroundStyle(.secondary)
                            Button("Try Again", systemImage: "arrow.clockwise") {
                                results.removeValue(forKey: provider.providerId)
                                retryID += 1
                            }
                        }
                        .padding(.horizontal, DSSpacing.lg)
                    default:
                        ProgressView("Loading titles")
                            .padding(.horizontal, DSSpacing.lg)
                    }
                }
            }
        }
        .task(id: "\(kind)-\(region)-\(refreshID)-\(retryID)-\(provider.providerId)") {
            startLoad()
        }
    }

    private func startLoad() {
        let providerID = provider.providerId
        guard results[providerID] == nil else { return }
        let token = UUID()
        results[providerID] = .loading(token)

        // Keep a request alive if only this rail leaves the screen. The parent
        // cancels its requests when the whole section disappears or refreshes.
        tasks[token] = Task {
            await load(providerID: providerID, token: token)
            tasks.removeValue(forKey: token)
        }
    }

    private func load(providerID: Int, token: UUID) async {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        let query = StreamingAvailabilityQuery(
            kind: kind,
            region: region,
            providerID: providerID,
            today: formatter.string(from: .now)
        )
        let client = client

        do {
            let response: PagedResponse<MediaItem> = try await StreamingDiscoverGate.shared.run {
                try await client.fetch(query.discoverEndpoint, parameters: query.parameters)
            }
            guard ownsRequest(token) else { return }
            guard !Task.isCancelled, region == TMDBRegion.current else {
                results.removeValue(forKey: providerID)
                return
            }
            results[providerID] = .loaded(Array(response.results.prefix(20)))
        } catch {
            guard ownsRequest(token) else { return }
            if Task.isCancelled || region != TMDBRegion.current {
                results.removeValue(forKey: providerID)
            } else {
                results[providerID] = .failed(error.localizedDescription)
            }
        }
    }

    private func ownsRequest(_ token: UUID) -> Bool {
        if case .some(.loading(let current)) = result {
            current == token
        } else {
            false
        }
    }
}
