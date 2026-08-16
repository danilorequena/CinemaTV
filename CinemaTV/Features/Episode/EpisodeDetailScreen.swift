//
//  EpisodeDetailScreen.swift
//  CinemaTV
//
//  Detalhe de episódio: still stretchy + pills + sinopse completa + guest
//  stars + direção/roteiro, com bottom bar glass (anterior · check · próximo).
//  Sem rede própria: o payload da temporada já traz tudo, então a navegação
//  carrega a lista inteira e prev/next trocam o episódio na própria tela.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

/// Valor de navegação: episódios da temporada + episódio inicial + origem
/// da zoom transition (nil quando não há card visível de origem).
struct EpisodeSelection: Hashable {
    let tvShowID: Int
    let seasonNumber: Int
    let episodes: [EpisodeSummary]
    let initialEpisodeNumber: Int
    let sourceID: String?
}

struct EpisodeDetailScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var currentNumber: Int
    @State private var isFollowing = false
    @State private var isWatched = false

    private let selection: EpisodeSelection

    init(selection: EpisodeSelection) {
        self.selection = selection
        self._currentNumber = State(initialValue: selection.initialEpisodeNumber)
    }

    private var trackingStore: TVShowTrackingStore {
        TVShowTrackingStore(context: modelContext)
    }

    private var episode: EpisodeSummary? {
        selection.episodes.first { $0.episodeNumber == currentNumber }
    }

    private var currentIndex: Int? {
        selection.episodes.firstIndex { $0.episodeNumber == currentNumber }
    }

    var body: some View {
        ScrollView {
            if let episode {
                header(episode)
                content(episode)
            }
        }
        // id: trocar de episódio (prev/next) reseta o scroll para o topo.
        .id(currentNumber)
        .ignoresSafeArea(edges: .top)
        .scrollEdgeEffectStyle(.soft, for: .top)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .sensoryFeedback(.impact(weight: .light), trigger: isWatched)
        .onAppear { refreshTrackingState() }
        .onChange(of: currentNumber) {
            refreshTrackingState()
        }
    }

    // MARK: - Sections

    private func header(_ episode: EpisodeSummary) -> some View {
        ZStack(alignment: .bottomLeading) {
            PosterImage(path: episode.stillPath, kind: .backdrop)
                .frame(maxWidth: .infinity)
            LinearGradient(
                colors: [.clear, .clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            Text(verbatim: "E\(episode.episodeNumber) · \(episode.name)")
                .font(.dsHeroTitle)
                .foregroundStyle(.white)
                .lineLimit(3)
                .padding(DSSpacing.lg)
        }
        // Stretchy header idêntico aos outros detalhes (efeito geométrico,
        // ok sob Reduce Motion).
        .visualEffect { content, proxy in
            let minY = proxy.frame(in: .scrollView(axis: .vertical)).minY
            let height = proxy.size.height
            return content
                .scaleEffect(minY > 0 ? 1 + minY / height : 1, anchor: .bottom)
                .offset(y: minY < 0 ? -minY * 0.5 : 0)
        }
    }

    @ViewBuilder
    private func content(_ episode: EpisodeSummary) -> some View {
        VStack(alignment: .leading, spacing: DSSpacing.xl) {
            VStack(alignment: .leading, spacing: DSSpacing.md) {
                ScrollView(.horizontal) {
                    InfoPillRow(pills: pills(for: episode))
                }
                .scrollIndicators(.hidden)

                if let directors = crewNames(episode, department: "Directing") {
                    Text("Directed by \(directors)")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
                if let writers = crewNames(episode, department: "Writing") {
                    Text("Written by \(writers)")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, DSSpacing.lg)

            if let overview = episode.overview, !overview.isEmpty {
                Text(verbatim: overview)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)
            }

            if let guests = episode.guestStars, !guests.isEmpty {
                CastCarousel(members: guests, title: Text("Guest Stars"))
            }
        }
        .padding(.vertical, DSSpacing.lg)
        .padding(.bottom, DSSpacing.xxl)
    }

    private func pills(for episode: EpisodeSummary) -> [InfoPillRow.Pill] {
        var pills: [InfoPillRow.Pill] = []
        if let date = formattedAirDate(episode.airDate) {
            pills.append(.init(id: "date", text: "\(date)", systemImage: "calendar"))
        }
        if let runtime = episode.formattedRuntime {
            pills.append(.init(id: "runtime", text: "\(runtime)", systemImage: "clock"))
        }
        if let vote = episode.voteAverage, vote > 0 {
            let rating = vote.formatted(.number.precision(.fractionLength(1)))
            pills.append(.init(id: "rating", text: "\(rating)", systemImage: "star.fill"))
        }
        return pills
    }

    /// Nomes do crew de um department, dedupe preservando ordem (a mesma
    /// pessoa aparece por job: Writer + Teleplay).
    private func crewNames(_ episode: EpisodeSummary, department: String) -> String? {
        var seen = Set<Int>()
        let names = (episode.crew ?? [])
            .filter { $0.department == department && seen.insert($0.id).inserted }
            .map(\.name)
        return names.isEmpty ? nil : names.formatted(.list(type: .and))
    }

    private func formattedAirDate(_ airDate: String?) -> String? {
        guard let airDate,
              let date = try? Date(airDate, strategy: .iso8601.year().month().day())
        else { return nil }
        // O parse ISO cai em meia-noite UTC; formatar em GMT evita a data
        // regredir um dia em fusos negativos.
        return date.formatted(Date.FormatStyle(date: .abbreviated, time: .omitted, timeZone: .gmt))
    }

    // MARK: - Bottom bar (anterior · check · próximo)

    private var bottomBar: some View {
        GlassEffectContainer(spacing: DSSpacing.md) {
            HStack {
                Button {
                    step(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .disabled(!canStep(-1))
                .opacity(canStep(-1) ? 1 : 0.4)
                .accessibilityLabel(Text("Previous Episode"))

                Spacer()

                Button {
                    toggleWatched()
                } label: {
                    Image(systemName: "checkmark")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(isWatched ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                        .opacity(isWatched ? 1 : 0.4)
                        .symbolEffect(.bounce, value: isWatched)
                        .frame(width: 52, height: 52)
                        .glassEffect(
                            isWatched ? .regular.tint(DSColor.accent).interactive() : .regular.interactive(),
                            in: .circle
                        )
                        .animation(DSMotion.respecting(reduceMotion, DSMotion.snappy), value: isWatched)
                }
                .buttonStyle(.plain)
                // Sem follow não há onde gravar o check (mesma regra da lista).
                .disabled(!isFollowing)
                .accessibilityLabel(Text("Mark as Watched"))
                .accessibilityValue(isWatched ? Text("Watched") : Text("Unwatched"))
                .accessibilityRemoveTraits(.isSelected)

                Spacer()

                Button {
                    step(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.title3.weight(.semibold))
                        .frame(width: 44, height: 44)
                        .glassEffect(.regular.interactive(), in: .circle)
                }
                .buttonStyle(.plain)
                .disabled(!canStep(1))
                .opacity(canStep(1) ? 1 : 0.4)
                .accessibilityLabel(Text("Next Episode"))
            }
        }
        .padding(.horizontal, DSSpacing.lg)
        .padding(.bottom, DSSpacing.sm)
    }

    private func canStep(_ offset: Int) -> Bool {
        guard let index = currentIndex else { return false }
        return selection.episodes.indices.contains(index + offset)
    }

    private func step(_ offset: Int) {
        guard let index = currentIndex,
              selection.episodes.indices.contains(index + offset) else { return }
        withAnimation(DSMotion.respecting(reduceMotion, DSMotion.standard)) {
            currentNumber = selection.episodes[index + offset].episodeNumber
        }
    }

    // MARK: - Tracking

    private func refreshTrackingState() {
        isFollowing = trackingStore.isFollowing(showID: selection.tvShowID)
        isWatched = trackingStore.isEpisodeWatched(
            showID: selection.tvShowID,
            seasonNumber: selection.seasonNumber,
            episodeNumber: currentNumber
        )
    }

    private func toggleWatched() {
        guard let episode else { return }
        do {
            if isWatched {
                try trackingStore.unmarkEpisodeWatched(
                    showID: selection.tvShowID,
                    seasonNumber: selection.seasonNumber,
                    episodeNumber: episode.episodeNumber
                )
            } else {
                try trackingStore.markEpisodeWatched(episode, showID: selection.tvShowID)
            }
            withAnimation(DSMotion.respecting(reduceMotion, DSMotion.snappy)) {
                refreshTrackingState()
            }
        } catch {
            assertionFailure("Episode toggle failed: \(error)")
        }
    }
}

#Preview {
    NavigationStack {
        EpisodeDetailScreen(selection: EpisodeSelection(
            tvShowID: 1399,
            seasonNumber: 1,
            episodes: [
                EpisodeSummary(
                    id: 63056,
                    name: "Winter Is Coming",
                    overview: "Lord Eddard Stark is torn between his family and an old friend when asked to serve at the side of King Robert Baratheon.",
                    episodeNumber: 1,
                    seasonNumber: 1,
                    airDate: "2011-04-17",
                    runtime: 62,
                    stillPath: nil,
                    voteAverage: 8.0,
                    guestStars: [
                        CastMember(id: 1, name: "Joseph Mawle", character: "Benjen Stark", profilePath: nil, order: 0)
                    ],
                    crew: [
                        CrewMember(id: 2, name: "Tim Van Patten", job: "Director", department: "Directing", profilePath: nil),
                        CrewMember(id: 3, name: "David Benioff", job: "Writer", department: "Writing", profilePath: nil)
                    ]
                ),
                EpisodeSummary(id: 63057, name: "The Kingsroad", episodeNumber: 2, seasonNumber: 1)
            ],
            initialEpisodeNumber: 1,
            sourceID: nil
        ))
    }
    .modelContainer(try! ModelContainerFactory.makeInMemory())
}
