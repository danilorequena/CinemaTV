//
//  DiscoverScreen.swift
//  CinemaTV
//
//  Fluxo Discover real (dados do TMDB + watchlist): paging vertical
//  full-bleed com parallax de tilt e decisões via botões glass.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

// MARK: - Tela

struct DiscoverScreen: View {
    @State private var model = DiscoverModel()

    var body: some View {
        DiscoverContent(model: model)
    }
}

/// Conteúdo separado da tela para que os previews injetem um model
/// pré-populado sem rede (o @State da DiscoverScreen não é semeável).
private struct DiscoverContent: View {
    @Environment(\.tmdbClient) private var client
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @Bindable var model: DiscoverModel
    /// Previews: tilt congelado — o body sobrescreve o environment com o
    /// MotionTiltManager (zero sem giroscópio), então injeção externa não
    /// chega; este parâmetro tem precedência quando presente.
    var previewTilt: DSTiltValue?

    @State private var motion = MotionTiltManager()
    @State private var trailer = DiscoverTrailerModel()
    @State private var quickDetails: MediaItem?
    @State private var pendingDetails: MediaItem?
    @State private var fullDetails: MediaItem?
    @State private var saveFeedback = 0
    @Query private var savedMovies: [MoviesToWatch]
    @Query private var watchedMovies: [MoviesWatched]

    private var savedMovieIDs: Set<Int> {
        Set(savedMovies.compactMap { $0.id.map(Int.init) })
            .union(watchedMovies.compactMap { $0.id.map(Int.init) })
    }

    private var store: WatchlistStore {
        let context = ModelContext(modelContext.container)
        context.autosaveEnabled = false
        return WatchlistStore(context: context)
    }

    var body: some View {
        ZStack {
            ambientBackground
            content
        }
        .environment(\.colorScheme, .dark)
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $quickDetails, onDismiss: {
            fullDetails = pendingDetails
            pendingDetails = nil
        }) { item in
            DiscoverQuickDetails(item: item) {
                pendingDetails = item
                quickDetails = nil
            }
        }
        .navigationDestination(item: $fullDetails) { item in
            MovieDetailScreen(item: item)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if trailer.movieID != nil {
                    Button("Back to cover", systemImage: "xmark") { trailer.close() }
                } else if model.canUndo {
                    Button("Undo skip", systemImage: "arrow.uturn.backward") {
                        withAnimation(DSMotion.respecting(reduceMotion)) { model.undoSkip() }
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: saveFeedback)
        .environment(\.dsTilt, previewTilt ?? DSTiltValue(roll: motion.roll, pitch: motion.pitch))
        .onAppear {
            if !reduceMotion {
                motion.start()
            }
        }
        .onDisappear {
            motion.stop()
            model.cancelLoading()
            trailer.close()
        }
        .onChange(of: model.visibleItemID) {
            if trailer.movieID != model.visibleItemID { trailer.close() }
        }
        .task {
            await model.loadInitial(client: client)
            await model.loadMoreIfNeeded(client: client)
        }
        .task(id: model.deck.count) {
            await model.loadMoreIfNeeded(client: client)
        }
        .task(id: model.visibleItemID) {
            await model.loadMoreIfNeeded(client: client)
        }
        .overlay(alignment: .bottom) {
            if trailer.movieID == nil {
                VStack(spacing: DSSpacing.sm) {
                    if let error = model.actionError {
                        HStack {
                            Text(verbatim: error).font(.caption)
                            Button("Close", systemImage: "xmark") { model.actionError = nil }
                                .labelStyle(.iconOnly)
                        }
                        .padding(DSSpacing.md)
                        .foregroundStyle(.white)
                        .glassEffect()
                    }
                    if !model.deck.isEmpty { paginationStatus }
                }
                .padding(DSSpacing.md)
            }
        }
    }

    /// A luz ambiente acompanha o filme visível, inclusive ao deslizar.
    private var ambientBackground: some View {
        ZStack {
            Color.black
            if let top = model.visibleItem {
                PosterImage(path: top.posterPath, kind: .poster, fillsContainer: true)
                    .id(top.id)
                    .blur(radius: 60)
                    .overlay(.black.opacity(0.45))
            }
        }
        .ignoresSafeArea()
        .animation(DSMotion.respecting(reduceMotion), value: model.visibleItem?.id)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            LoadingStateView {
                DiscoverCardSkeleton()
            }
        case .failed(let message):
            ErrorStateView(message: message) {
                Task { await model.retry(client: client) }
            }
        case .loaded:
            if model.deck.isEmpty {
                if model.isLoadingMore {
                    LoadingStateView { DiscoverCardSkeleton() }
                } else if let message = model.paginationError {
                    ErrorStateView(message: message) {
                        Task { await model.retry(client: client) }
                    }
                } else {
                    EmptyStateView(
                        title: "That's all for now",
                        message: "Come back soon for more movies.",
                        systemImage: "sparkles"
                    )
                }
            } else {
                VerticalVariant(
                    deck: model.deck,
                    visibleItemID: $model.visibleItemID,
                    savedIDs: savedMovieIDs,
                    trailer: trailer,
                    onDecide: decide,
                    onPlayTrailer: playTrailer,
                    onDetails: { trailer.close(); quickDetails = $0 }
                )
            }
        }
    }

    @ViewBuilder
    private var paginationStatus: some View {
        if model.isLoadingMore {
            ProgressView()
                .tint(.white)
                .padding(DSSpacing.md)
                .glassEffect()
                .accessibilityLabel(Text("Loading more movies"))
        } else if model.paginationError != nil {
            VStack(spacing: DSSpacing.xs) {
                Text("Couldn't load more movies.")
                    .font(.caption)
                Button("Try Again", systemImage: "arrow.clockwise") {
                    Task { await model.retry(client: client) }
                }
                .buttonStyle(.glass)
            }
            .foregroundStyle(.white)
        }
    }

    private func playTrailer(_ item: MediaItem) {
        trailer.play(item, client: client)
    }

    private func decide(_ item: MediaItem, wanted: Bool) {
        withAnimation(DSMotion.respecting(reduceMotion)) {
            if model.decide(item, wanted: wanted, store: store), wanted {
                saveFeedback += 1
            }
        }
    }

}

// MARK: - Peças compartilhadas

private func discoverAccessibilityLabel(for item: MediaItem) -> Text {
    let rating = item.voteAverage.formatted(.number.precision(.fractionLength(1)))
    return Text(verbatim: "\(item.title), \(item.releaseYear ?? ""), \(rating)")
}

/// Skeleton do estado de carga: silhueta da carta central.
private struct DiscoverCardSkeleton: View {
    var body: some View {
        VStack(spacing: DSSpacing.lg) {
            RoundedRectangle(cornerRadius: DSRadius.card)
                .fill(.quaternary)
                .aspectRatio(2 / 3, contentMode: .fit)
                .frame(width: 300)
            RoundedRectangle(cornerRadius: DSRadius.poster / 2)
                .fill(.quaternary)
                .frame(width: 180, height: 16)
        }
    }
}

// MARK: - Vertical Immersive

private struct VerticalVariant: View {
    let deck: [MediaItem]
    @Binding var visibleItemID: MediaItem.ID?
    let savedIDs: Set<Int>
    let trailer: DiscoverTrailerModel
    let onDecide: (MediaItem, Bool) -> Void
    let onPlayTrailer: (MediaItem) -> Void
    let onDetails: (MediaItem) -> Void

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(deck) { item in
                    VerticalPage(item: item, isSaved: savedIDs.contains(item.id), trailer: trailer,
                                 onDecide: onDecide, onPlayTrailer: onPlayTrailer, onDetails: onDetails)
                        .containerRelativeFrame(.vertical)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $visibleItemID)
        .scrollIndicators(.hidden)
        // Sem .soft, o efeito de borda do scroll pinta uma faixa dura preta
        // sob a navigation bar no full-bleed.
        .scrollEdgeEffectStyle(.soft, for: .top)
        .ignoresSafeArea()
    }
}

private struct VerticalPage: View {
    @Environment(\.dsTilt) private var tilt
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.mediaZoomNamespace) private var zoomNamespace
    @Environment(\.scenePhase) private var scenePhase

    let item: MediaItem
    let isSaved: Bool
    let trailer: DiscoverTrailerModel
    let onDecide: (MediaItem, Bool) -> Void
    let onPlayTrailer: (MediaItem) -> Void
    let onDetails: (MediaItem) -> Void

    /// Um único MediaSelection por página: o mesmo valor navega (botão info)
    /// e ancora a zoom transition na página inteira.
    private var selection: MediaSelection {
        MediaSelection(item: item, scope: "discover")
    }

    private var showsTrailer: Bool { trailer.movieID == item.id }
    private var playerReady: Bool { showsTrailer && trailer.isReady }

    var body: some View {
        ZStack {
            posterContent
                .opacity(playerReady ? 0 : 1)
                .allowsHitTesting(!playerReady)
                .accessibilityHidden(playerReady)
            if showsTrailer, let video = trailer.video {
                let playbackID = trailer.playbackID
                ZStack {
                    Color.black
                    InlineYouTubePlayer(
                        videoKey: video.key,
                        isActive: scenePhase == .active,
                        onReady: { trailer.playerReady(for: video, playbackID: playbackID) },
                        onFailure: { trailer.playerFailed(for: video, playbackID: playbackID) }
                    )
                    .id(playbackID)
                    .aspectRatio(16 / 9, contentMode: .fit)
                }
                .opacity(playerReady ? 1 : 0)
                .allowsHitTesting(playerReady)
                .accessibilityHidden(!playerReady)
                .transition(.opacity)
            }
            if showsTrailer, !playerReady {
                trailerStatus
            }
        }
        .animation(reduceMotion ? DSMotion.subtleFade : .easeInOut(duration: 0.25), value: playerReady)
        .onChange(of: scenePhase) {
            if scenePhase == .background { trailer.close() }
        }
        .onDisappear {
            if showsTrailer { trailer.close() }
        }
        .accessibilityAction(named: Text("Back to cover")) {
            if showsTrailer { trailer.close() }
        }
    }

    private var posterContent: some View {
        ZStack(alignment: .bottom) {
            // Camada de fundo do parallax, na linguagem do hero da Home:
            // imagem rígida (sem warp) ampliada, com leve rotação 3D +
            // translação maior que o primeiro plano + varredura holográfica.
            PosterImage(path: item.posterPath, kind: .poster, fillsContainer: true)
                .scaleEffect(1.12)
                .rotation3DEffect(
                    .degrees(reduceMotion ? 0 : tilt.roll * 4),
                    axis: (x: 0, y: 1, z: 0),
                    perspective: 0.35
                )
                .rotation3DEffect(
                    .degrees(reduceMotion ? 0 : tilt.pitch * 3),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.35
                )
                .offset(
                    x: reduceMotion ? 0 : tilt.roll * 24,
                    y: reduceMotion ? 0 : tilt.pitch * 18
                )
                .dsHoloEffect(angle: reduceMotion ? 0 : tilt.roll)
                .accessibilityHidden(true)
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            .accessibilityHidden(true)

            HStack(alignment: .bottom, spacing: DSSpacing.lg) {
                VStack(alignment: .leading, spacing: DSSpacing.sm) {
                    Text(verbatim: item.title)
                        .font(.dsHeroTitle)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                    InfoPillRow(pills: pills)
                    if !item.overview.isEmpty {
                        Text(verbatim: item.overview)
                            .font(.subheadline)
                            .foregroundStyle(.white.secondary)
                            .lineLimit(2)
                    }
                }
                Spacer()
                actions
            }
            .padding(DSSpacing.lg)
            .padding(.bottom, DSSpacing.xxl + DSSpacing.lg)
            // Primeiro plano do parallax: micro-movimento CONTRA o tilt —
            // o conteúdo flutua na frente do vidro.
            .offset(
                x: reduceMotion ? 0 : tilt.roll * -8,
                y: reduceMotion ? 0 : tilt.pitch * -6
            )
        }
        .clipped()
        .modifier(ZoomSourceModifier(id: selection.sourceID, namespace: zoomNamespace))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(discoverAccessibilityLabel(for: item))
        .accessibilityAction(named: Text("Want to Watch")) { onDecide(item, true) }
        .accessibilityAction(named: Text("Skip")) { onDecide(item, false) }
    }

    private var pills: [InfoPillRow.Pill] {
        var result: [InfoPillRow.Pill] = []
        if let year = item.releaseYear {
            result.append(.init(id: "year", text: "\(year)", systemImage: "calendar"))
        }
        result.append(.init(
            id: "rating",
            text: "\(item.voteAverage.formatted(.number.precision(.fractionLength(1))))",
            systemImage: "star.fill"
        ))
        return result
    }

    private var actions: some View {
        VStack(spacing: DSSpacing.md) {
            actionButton(isSaved ? "Saved" : "Save", systemImage: isSaved ? "bookmark.fill" : "bookmark", tint: .green) {
                onDecide(item, true)
            }
            .disabled(isSaved)
            actionButton("Trailer", systemImage: "play.fill") { onPlayTrailer(item) }
                .disabled(showsTrailer)
                .accessibilityAddTraits(.startsMediaSession)
            actionButton("Skip", systemImage: "forward.end") { onDecide(item, false) }
            actionButton("Details", systemImage: "info") { onDetails(item) }
        }
    }

    private func actionButton(_ title: LocalizedStringKey, systemImage: String, tint: Color = .white,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: DSSpacing.xs) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .glassEffect(.regular.interactive(), in: .circle)
                Text(title).font(.caption2).foregroundStyle(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(title))
    }

    @ViewBuilder
    private var trailerStatus: some View {
        VStack(spacing: DSSpacing.md) {
            switch trailer.phase {
            case .loading, .preparing:
                ProgressView("Loading trailer…").tint(.white)
                Button("Cancel") { trailer.close() }
            case .failed:
                Text("Couldn't play this trailer.")
                Button("Try Again", systemImage: "arrow.clockwise") { onPlayTrailer(item) }
                if let url = trailer.watchURL {
                    Link("Open in YouTube", destination: url)
                }
                Button("Back to cover") { trailer.close() }
            case .unavailable:
                Text("No trailer available for this movie.")
                Button("Back to cover") { trailer.close() }
            case .idle, .ready:
                EmptyView()
            }
        }
        .font(.subheadline)
        .foregroundStyle(.white)
        .padding(DSSpacing.lg)
        .background(.black.opacity(0.85), in: .rect(cornerRadius: 20))
        .buttonStyle(.glass)
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews (deck fake, sem rede)

private let discoverPreviewDeck: [MediaItem] = [
    MediaItem(
        id: 1,
        title: "Neon Horizon",
        overview: "Em uma megacidade à beira do colapso, uma pilota clandestina descobre um sinal impossível.",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 8.4,
        releaseDate: "2026-03-14",
        mediaType: .movie
    ),
    MediaItem(
        id: 2,
        title: "Last Ember",
        overview: "O último guardião de uma chama ancestral atravessa um continente em ruínas.",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 7.2,
        releaseDate: "2025-11-02",
        mediaType: .movie
    ),
    MediaItem(
        id: 3,
        title: "Tide Runner",
        overview: "Uma mensageira dos mares contrabandeia memórias entre cidades flutuantes.",
        posterPath: nil,
        backdropPath: nil,
        voteAverage: 6.9,
        releaseDate: "2026-07-04",
        mediaType: .movie
    )
]

#Preview("Discover") {
    NavigationStack {
        DiscoverContent(model: DiscoverModel(previewDeck: discoverPreviewDeck))
    }
    .modelContainer(try! ModelContainerFactory.makeInMemory())
}
// Tilt forçado: o simulador/preview não tem giroscópio — este preview
// congela o parallax num ângulo extremo para inspecionar o warp, os
// offsets das camadas e conferir que nenhuma borda do poster aparece.
#Preview("Parallax debug") {
    NavigationStack {
        DiscoverContent(
            model: DiscoverModel(previewDeck: discoverPreviewDeck),
            previewTilt: DSTiltValue(roll: 0.5, pitch: 0.25)
        )
    }
    .modelContainer(try! ModelContainerFactory.makeInMemory())
}
