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

// MARK: - Model

@MainActor
@Observable
final class DiscoverModel {
    struct Decision {
        let item: MediaItem
        let wanted: Bool
    }

    private(set) var deck: [MediaItem] = []
    private(set) var history: [Decision] = []
    private(set) var state: LoadState<Bool> = .idle

    private var page = 0
    private var totalPages = Int.max
    private var decidedIDs: Set<Int> = []
    private var isLoadingMore = false

    init() {}

    /// Previews: deck pré-populado, sem rede (totalPages = 1 desliga o
    /// loadMoreIfNeeded).
    init(previewDeck: [MediaItem]) {
        deck = previewDeck
        page = 1
        totalPages = 1
        state = .loaded(true)
    }

    var canUndo: Bool { !history.isEmpty }

    /// Trailer do YouTube sob demanda: primeiro o trailer oficial; senão
    /// qualquer vídeo DO YOUTUBE (key de outro site montaria URL quebrada).
    func trailer(for item: MediaItem, client: TMDBClient) async -> Video? {
        let response: VideosResponse? = try? await client.fetch(.movieVideos(id: item.id))
        return response?.results.first(where: \.isYouTubeTrailer)
            ?? response?.results.first(where: { $0.site.caseInsensitiveCompare("YouTube") == .orderedSame })
    }

    func loadInitial(client: TMDBClient) async {
        if case .loaded = state { return }
        state = .loading
        do {
            let response: PagedResponse<MediaItem> = try await client.fetch(.discoverMovies, page: 1)
            page = response.page
            totalPages = response.totalPages
            deck = response.results.filter { $0.mediaType == .movie && !decidedIDs.contains($0.id) }
            state = .loaded(true)
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    /// Reabastece o deck com a página seguinte quando restam poucas cartas,
    /// filtrando filmes já decididos nesta sessão.
    func loadMoreIfNeeded(client: TMDBClient) async {
        guard case .loaded = state, deck.count < 4, page < totalPages, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let response: PagedResponse<MediaItem> = try await client.fetch(.discoverMovies, page: page + 1)
            page = response.page
            totalPages = response.totalPages
            let visible = Set(deck.map(\.id))
            deck.append(contentsOf: response.results.filter {
                $0.mediaType == .movie && !decidedIDs.contains($0.id) && !visible.contains($0.id)
            })
        } catch {
            // Com cartas na mesa o fluxo segue; só vira erro sem nada a exibir.
            if deck.isEmpty {
                state = .failed(error.localizedDescription)
            }
        }
    }

    func decide(_ item: MediaItem, wanted: Bool, store: WatchlistStore) {
        decidedIDs.insert(item.id)
        deck.removeAll { $0.id == item.id }
        history.append(Decision(item: item, wanted: wanted))
        if wanted {
            try? store.addToWatchlist(item)
            SpotlightIndexer.index(item)
        }
    }

    func undo(store: WatchlistStore) {
        guard let last = history.popLast() else { return }
        decidedIDs.remove(last.item.id)
        deck.insert(last.item, at: 0)
        if last.wanted {
            try? store.removeFromWatchlist(movieID: last.item.id)
            SpotlightIndexer.deindex(movieID: last.item.id)
        }
    }

    func retry(client: TMDBClient) async {
        state = .idle
        await loadInitial(client: client)
    }
}

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

    let model: DiscoverModel
    /// Previews: tilt congelado — o body sobrescreve o environment com o
    /// MotionTiltManager (zero sem giroscópio), então injeção externa não
    /// chega; este parâmetro tem precedência quando presente.
    var previewTilt: DSTiltValue?

    @State private var motion = MotionTiltManager()
    @State private var presentedTrailer: Video?

    private var store: WatchlistStore {
        WatchlistStore(context: modelContext)
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
        .sheet(item: $presentedTrailer) { trailer in
            YouTubePlayerView(video: trailer)
                .presentationDetents([.medium, .large])
        }
        .environment(\.dsTilt, previewTilt ?? DSTiltValue(roll: motion.roll, pitch: motion.pitch))
        .onAppear {
            if !reduceMotion {
                motion.start()
            }
        }
        .onDisappear {
            motion.stop()
        }
        .task {
            await model.loadInitial(client: client)
        }
        .task(id: model.deck.count) {
            await model.loadMoreIfNeeded(client: client)
        }
    }

    /// Poster do topo do deck desfocado como luz ambiente; crossfade animado
    /// quando o topo muda.
    private var ambientBackground: some View {
        ZStack {
            Color.black
            if let top = model.deck.first {
                PosterImage(path: top.posterPath, kind: .poster, fillsContainer: true)
                    .id(top.id)
                    .blur(radius: 60)
                    .overlay(.black.opacity(0.45))
            }
        }
        .ignoresSafeArea()
        .animation(DSMotion.standard, value: model.deck.first?.id)
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
                EmptyStateView(
                    title: "That's all for now",
                    message: "Come back soon for more movies.",
                    systemImage: "sparkles"
                )
            } else {
                VerticalVariant(
                    deck: model.deck,
                    onDecide: decide,
                    onPlayTrailer: playTrailer
                )
            }
        }
    }

    private func playTrailer(_ item: MediaItem) {
        Task {
            presentedTrailer = await model.trailer(for: item, client: client)
        }
    }

    private func decide(_ item: MediaItem, wanted: Bool) {
        withAnimation(DSMotion.respecting(reduceMotion)) {
            model.decide(item, wanted: wanted, store: store)
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
    let onDecide: (MediaItem, Bool) -> Void
    let onPlayTrailer: (MediaItem) -> Void

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(deck) { item in
                    VerticalPage(item: item, onDecide: onDecide, onPlayTrailer: onPlayTrailer)
                        .containerRelativeFrame(.vertical)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
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
    @Namespace private var actionsNamespace
    /// "Want to Watch" morfa a coluna de ações numa pill de confirmação
    /// antes do onDecide remover a página do deck.
    @State private var confirmedWant = false

    let item: MediaItem
    let onDecide: (MediaItem, Bool) -> Void
    let onPlayTrailer: (MediaItem) -> Void

    /// Um único MediaSelection por página: o mesmo valor navega (botão info)
    /// e ancora a zoom transition na página inteira.
    private var selection: MediaSelection {
        MediaSelection(item: item, scope: "discover")
    }

    var body: some View {
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
        GlassEffectContainer(spacing: DSSpacing.md) {
            VStack(spacing: DSSpacing.md) {
                if confirmedWant {
                    // Herda o glassEffectID do bookmark: o glass dele flui
                    // para cá e os demais botões são absorvidos pelo container.
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .padding(DSSpacing.lg)
                        .glassEffect(.regular.tint(.green), in: .circle)
                        .glassEffectID("want", in: actionsNamespace)
                        .accessibilityHidden(true)
                } else {
                    Button {
                        confirmWant()
                    } label: {
                        Image(systemName: "bookmark.fill")
                            .foregroundStyle(.green)
                            .padding(DSSpacing.md)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .glassEffectID("want", in: actionsNamespace)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Want to Watch"))

                    Button {
                        onPlayTrailer(item)
                    } label: {
                        Image(systemName: "play.fill")
                            .foregroundStyle(.white)
                            .padding(DSSpacing.md)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .glassEffectID("trailer", in: actionsNamespace)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Trailer"))
                    .accessibilityAddTraits(.startsMediaSession)

                    Button {
                        onDecide(item, false)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.red)
                            .padding(DSSpacing.md)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .glassEffectID("skip", in: actionsNamespace)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Skip"))

                    NavigationLink(value: selection) {
                        Image(systemName: "info")
                            .padding(DSSpacing.md)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .glassEffectID("info", in: actionsNamespace)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(verbatim: item.title))
                }
            }
            .font(.title3.weight(.semibold))
        }
        .sensoryFeedback(.success, trigger: confirmedWant)
    }

    /// Morph primeiro, decisão depois: o onDecide remove a página do deck,
    /// então a pill de confirmação precisa de um instante em cena.
    private func confirmWant() {
        guard !confirmedWant else { return }
        guard !reduceMotion else {
            onDecide(item, true)
            return
        }
        withAnimation(DSMotion.snappy) {
            confirmedWant = true
        }
        Task {
            try? await Task.sleep(for: .milliseconds(650))
            onDecide(item, true)
        }
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

