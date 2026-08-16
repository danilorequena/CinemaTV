//
//  AppShellView.swift
//  CinemaTV
//
//  Shell do redesign: TabView (Tracking, Discover, Search com role .search),
//  um NavigationStack por tab e o funil único de destinos. Substitui o
//  AppView legado.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

// Instância única e estável (Equatable por id): o design system aplica o
// shader sem conhecer o metallib do app.
private let holoShaderProvider = DSHoloShaderProvider(id: "holoSweep") { angle, size in
    ShaderLibrary.holoSweep(.float2(size), .float(angle), .float(0.3))
}

struct AppShellView: View {
    @Environment(AppRouter.self) private var router
    @Namespace private var zoomNamespace

    var body: some View {
        standardBody
            .environment(\.mediaZoomNamespace, zoomNamespace)
            .environment(\.dsHoloShader, holoShaderProvider)
            .tint(DSColor.accent)
    }

    private var standardBody: some View {
        @Bindable var router = router

        return TabView(selection: $router.selectedTab) {
            Tab("Library", systemImage: "books.vertical", value: AppTab.tracking) {
                NavigationStack(path: $router.trackingPath) {
                    WatchlistScreen()
                        .withMediaDestinations(zoomNamespace: zoomNamespace)
                }
            }

            Tab("Discover", systemImage: "binoculars", value: AppTab.discover) {
                NavigationStack(path: $router.discoverPath) {
                    HomeScreen()
                        .withMediaDestinations(zoomNamespace: zoomNamespace)
                }
            }

            Tab(value: AppTab.search, role: .search) {
                NavigationStack(path: $router.searchPath) {
                    SearchScreen()
                        .withMediaDestinations(zoomNamespace: zoomNamespace)
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewSearchActivation(.searchTabSelection)
        .onOpenURL { url in
            if let deepLink = DeepLink(url: url) {
                router.open(deepLink)
            }
        }
    }
}

/// Resolve os dois tipos de valor de navegação: MediaItem (taps em cards do
/// design system) e Route (deep links, intents, "See All").
private struct MediaDestinationsModifier: ViewModifier {
    let zoomNamespace: Namespace.ID

    func body(content: Content) -> some View {
        content
            .navigationDestination(for: MediaSelection.self) { selection in
                destination(for: selection)
            }
            .navigationDestination(for: MediaItem.self) { item in
                destination(for: item)
            }
            .navigationDestination(for: Route.self) { route in
                destination(for: route)
            }
            .navigationDestination(for: EpisodeSelection.self) { selection in
                if let sourceID = selection.sourceID {
                    EpisodeDetailScreen(selection: selection)
                        .navigationTransition(.zoom(sourceID: sourceID, in: zoomNamespace))
                } else {
                    EpisodeDetailScreen(selection: selection)
                }
            }
    }

    /// Seleções vindas de cards do design system: zoom transition partindo
    /// exatamente do card tocado (sourceID escopado por rail/grid).
    @ViewBuilder
    private func destination(for selection: MediaSelection) -> some View {
        switch selection.item.mediaType {
        case .movie:
            MovieDetailScreen(item: selection.item)
                .navigationTransition(.zoom(sourceID: selection.sourceID, in: zoomNamespace))
        case .person:
            PersonScreen(personID: selection.item.id)
                .navigationTransition(.zoom(sourceID: selection.sourceID, in: zoomNamespace))
        case .tvShow:
            TVShowDetailScreen(item: selection.item)
                .navigationTransition(.zoom(sourceID: selection.sourceID, in: zoomNamespace))
        }
    }

    @ViewBuilder
    private func destination(for item: MediaItem) -> some View {
        switch item.mediaType {
        case .movie:
            MovieDetailScreen(item: item)
        case .person:
            PersonScreen(personID: item.id)
        case .tvShow:
            TVShowDetailScreen(item: item)
        }
    }

    @ViewBuilder
    private func destination(for route: Route) -> some View {
        switch route {
        case .movieDetail(let id):
            MovieDetailScreen(movieID: id)
        case .person(let id):
            PersonScreen(personID: id)
        case .movieList(let category):
            MovieListScreen(category: category)
        case .discoverDeck:
            DiscoverScreen()
        case .tvShowDetail(let id):
            TVShowDetailScreen(showID: id)
        case .season(let tvShowID, let seasonNumber, let sourceID):
            if let sourceID {
                SeasonScreen(tvShowID: tvShowID, seasonNumber: seasonNumber)
                    .navigationTransition(.zoom(sourceID: sourceID, in: zoomNamespace))
            } else {
                SeasonScreen(tvShowID: tvShowID, seasonNumber: seasonNumber)
            }
        }
    }
}

extension View {
    func withMediaDestinations(zoomNamespace: Namespace.ID) -> some View {
        modifier(MediaDestinationsModifier(zoomNamespace: zoomNamespace))
    }
}
