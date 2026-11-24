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
    private static let onboardingVersion = 1

    @Environment(AppRouter.self) private var router
    @AppStorage("completedOnboardingVersion") private var completedOnboardingVersion = 0
    @AppStorage(CloudSyncDiagnostics.modeKey) private var cloudStoreMode = ""
    @AppStorage(CloudSyncDiagnostics.lastErrorKey) private var lastCloudError = ""
    @State private var showsCloudStoreWarning = false
    @State private var didCheckCloudStore = false
    @Namespace private var zoomNamespace

    var body: some View {
        @Bindable var router = router

        ZStack {
            if showsOnboarding {
                OnboardingScreen(onChooseStreamingServices: {
                    router.presentation = AppPresentation(content: .onboardingStreaming)
                }, onExit: finishOnboarding)
            } else {
                standardBody
                    .onAppear(perform: checkCloudStore)
                    .onChange(of: lastCloudError) { _, error in
                        if cloudStoreMode == "cloudKit", !error.isEmpty {
                            didCheckCloudStore = false
                            checkCloudStore()
                        }
                    }
            }
        }
        .alert("iCloud Sync Needs Attention", isPresented: $showsCloudStoreWarning) {
            Button("OK", role: .cancel) {}
        } message: {
            if cloudStoreMode == "memory" {
                Text("The library could not be opened. New changes may disappear when the app closes. See Settings > iCloud Sync for details.")
            } else if cloudStoreMode == "local" {
                Text("Changes are being saved only on this iPhone. See Settings > iCloud Sync for details.")
            } else {
                Text("Your library is saved on this iPhone, but iCloud could not sync it. See Settings > iCloud Sync for details.")
            }
        }
        .sheet(item: $router.presentation, onDismiss: checkCloudStore, content: presentedScreen)
        .environment(\.mediaZoomNamespace, zoomNamespace)
        .environment(\.dsHoloShader, holoShaderProvider)
        .tint(DSColor.accent)
        .onOpenURL { url in
            if let deepLink = DeepLink(url: url) {
                router.open(deepLink)
            }
        }
    }

    private var showsOnboarding: Bool {
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            || (environment["CINEMATV_UI_TEST_STORE"] != nil && environment["CINEMATV_UI_TEST_ONBOARDING"] != "1") {
            return false
        }
#endif
        return completedOnboardingVersion < Self.onboardingVersion && !router.receivedExternalOpen
    }

    private func finishOnboarding(_ destination: OnboardingDestination) {
        guard !router.receivedExternalOpen else { return }
        completedOnboardingVersion = Self.onboardingVersion
        switch destination {
        case .library: router.selectedTab = .tracking
        case .search: router.selectedTab = .search
        case .libraryImport: router.presentLibraryImport()
        }
    }

    private func checkCloudStore() {
        guard !showsOnboarding, !didCheckCloudStore, router.presentation == nil else { return }
#if DEBUG
        let environment = ProcessInfo.processInfo.environment
        if environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || environment["CINEMATV_UI_TEST_STORE"] != nil {
            return
        }
#endif
        didCheckCloudStore = true
        showsCloudStoreWarning = cloudStoreMode == "local" || cloudStoreMode == "memory" || !lastCloudError.isEmpty
    }

    @ViewBuilder
    private func presentedScreen(_ presentation: AppPresentation) -> some View {
        @Bindable var router = router

        switch presentation.content {
        case .onboardingStreaming:
            StreamingServicePicker(allowsSkipping: true)
        case .libraryImport(let request):
            LibraryImportScreen(initialText: request.text, initialDestination: request.destination)
        case .externalMedia(let media):
            NavigationStack(path: $router.externalMediaPath) {
                Group {
                    switch media {
                    case .movie(let id):
                        MovieDetailScreen(movieID: id)
                    case .tvShow(let id):
                        TVShowDetailScreen(showID: id)
                    }
                }
                .withMediaDestinations(zoomNamespace: zoomNamespace)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Close", systemImage: "xmark") {
                            router.presentation = nil
                        }
                    }
                }
            }
        }
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

            Tab("Lifetime", systemImage: "chart.bar.xaxis", value: AppTab.lifetime) {
                NavigationStack(path: $router.lifetimePath) {
                    LifetimeScreen()
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
        case .boxes:
            BoxesLibraryScreen()
        case .box(let id):
            BoxDetailScreen(id: id)
        case .sharedBox(let editionID):
            BoxIncomingScreen(editionID: editionID)
        case .boxEpisode(let id, let season, let episode):
            BoxEpisodeScreen(tvShowID: id, seasonNumber: season, episodeNumber: episode)
        case .movieDetail(let id):
            MovieDetailScreen(movieID: id)
        case .person(let id):
            PersonScreen(personID: id)
        case .movieList(let category):
            MovieListScreen(category: category)
        case .streamingCatalog(let providerName, let query, let firstPageItems, let nextPage):
            StreamingCatalogScreen(
                providerName: providerName,
                query: query,
                firstPageItems: firstPageItems,
                nextPage: nextPage
            )
        case .discoverDeck:
            DiscoverScreen()
        case .tvShowDetail(let id):
            TVShowDetailScreen(showID: id)
        case .tvShowList(let category):
            TVShowListScreen(category: category)
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
