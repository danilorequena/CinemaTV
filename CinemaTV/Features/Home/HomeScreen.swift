//
//  HomeScreen.swift
//  CinemaTV
//
//  Home de Movies: hero (now playing) + rails por categoria.
//  Substitui HomeView/MoviesView/DiscoverView.
//

import SwiftUI
import UIKit
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

    init() {
        // Segmented nativo (ganha o drag do thumb) com o accent do app.
        // Appearance é global, mas este é o único Picker segmentado do app.
        let appearance = UISegmentedControl.appearance()
        appearance.selectedSegmentTintColor = UIColor(DSColor.accent)
        appearance.setTitleTextAttributes([.foregroundColor: UIColor.black], for: .selected)
    }

    var body: some View {
        VStack(spacing: DSSpacing.md) {
            Picker("Media Type", selection: $mediaKind) {
                Text("Movies").tag(MediaKind.movies)
                Text("TV Shows").tag(MediaKind.shows)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, DSSpacing.lg)

            switch mediaKind {
            case .movies:
                moviesBody
            case .shows:
                showsBody
            }
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
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
                TiltedHeroCarousel(items: Array(content.nowPlaying.prefix(6)), motion: motion)

                MediaCarousel(title: "Upcoming", items: content.upcoming, zoomScope: "upcoming") {
                    router.discoverPath.append(Route.movieList(category: .upcoming))
                }
                MediaCarousel(title: "Popular", items: content.popular, zoomScope: "popular") {
                    router.discoverPath.append(Route.movieList(category: .popular))
                }
                MediaCarousel(title: "Top Rated", items: content.topRated, zoomScope: "topRated") {
                    router.discoverPath.append(Route.movieList(category: .topRated))
                }
                DiscoverPortalCard(items: Array(content.discover.prefix(3))) {
                    router.discoverPath.append(Route.discoverDeck)
                }
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .refreshable {
            await model.refresh(client: client)
        }
    }

    private var homeSkeleton: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
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
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
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
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .refreshable {
            await tvModel.refresh(client: client)
        }
    }

    private var showsSkeleton: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.xl) {
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
