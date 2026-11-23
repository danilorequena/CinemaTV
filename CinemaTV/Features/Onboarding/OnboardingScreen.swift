import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

enum OnboardingDestination {
    case library
    case search
    case libraryImport
}

struct OnboardingScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AccessibilityFocusState private var focusedChapter: OnboardingChapter?
    @State private var chapter = OnboardingChapter.discover
    @State private var showsStreamingServices = false

    private let isReview: Bool
    private let onChooseStreamingServices: (() -> Void)?
    private let onExit: (OnboardingDestination) -> Void

    init(
        isReview: Bool = false,
        onChooseStreamingServices: (() -> Void)? = nil,
        onExit: @escaping (OnboardingDestination) -> Void
    ) {
        self.isReview = isReview
        self.onChooseStreamingServices = onChooseStreamingServices
        self.onExit = onExit
    }

    private var scrollsActions: Bool {
        dynamicTypeSize.isAccessibilitySize || verticalSizeClass == .compact
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, DSSpacing.xl)
                .padding(.bottom, DSSpacing.md)

            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    chapterContent
                    if scrollsActions {
                        actions
                    }
                }
                .padding(.horizontal, DSSpacing.xl)
                .padding(.top, DSSpacing.xs)
                .padding(.bottom, DSSpacing.xl)
            }
            .id(chapter)
            .defaultScrollAnchor(.top)

            if !scrollsActions {
                actions
                    .padding(.horizontal, DSSpacing.xl)
                    .padding(.top, DSSpacing.sm)
                    .padding(.bottom, DSSpacing.md)
                    .background(.background)
            }
        }
        .frame(maxWidth: 560)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background {
            Color(uiColor: .systemBackground)
                .ignoresSafeArea()
        }
        .tint(DSColor.accent)
        .onChange(of: chapter) { _, chapter in
            focusedChapter = chapter
        }
        .sheet(isPresented: $showsStreamingServices) {
            StreamingServicePicker(allowsSkipping: true)
        }
    }

    private var header: some View {
        VStack(spacing: DSSpacing.xs) {
            HStack(spacing: DSSpacing.sm) {
                if let previous = OnboardingChapter(rawValue: chapter.rawValue - 1) {
                    Button {
                        chapter = previous
                    } label: {
                        Label("Back", systemImage: "chevron.backward")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(.rect)
                    }
                    .foregroundStyle(.primary)
                    .accessibilityIdentifier("onboarding.back")
                }

                Spacer()

                Button {
                    onExit(.library)
                } label: {
                    Text(isReview ? "Close" : "Skip")
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(.rect)
                }
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(isReview ? "onboarding.close" : "onboarding.skip")
            }
            .buttonStyle(.plain)
            .frame(minHeight: 44)

            HStack(spacing: DSSpacing.sm) {
                HStack(spacing: DSSpacing.xs) {
                    ForEach(OnboardingChapter.allCases, id: \.self) { step in
                        Capsule()
                            .fill(step.rawValue <= chapter.rawValue ? DSColor.accent : Color.primary.opacity(0.12))
                            .frame(height: 4)
                    }
                }
                .accessibilityHidden(true)

                Text("Page \(chapter.rawValue + 1) of \(OnboardingChapter.allCases.count)")
                    .font(.dsCaption)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .layoutPriority(1)
            }
            .accessibilityIdentifier("onboarding.progress")
        }
    }

    private var chapterContent: some View {
        VStack(alignment: .leading, spacing: DSSpacing.lg) {
            OnboardingArtwork(symbols: chapter.artwork)

            Text(chapter.title)
                .font(.dsHeroTitle)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("onboarding.title")
                .accessibilityFocused($focusedChapter, equals: chapter)

            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                ForEach(chapter.features) { feature in
                    HStack(alignment: .top, spacing: DSSpacing.md) {
                        Image(systemName: feature.symbol)
                            .font(.headline)
                            .symbolRenderingMode(.hierarchical)
                            .frame(width: 32, height: 32)
                            .background(DSColor.accent.opacity(0.18), in: .rect(cornerRadius: DSSpacing.sm))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: DSSpacing.xs) {
                            Text(feature.title)
                                .font(.headline)
                            Text(feature.description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            if chapter == .discover {
                Button("Choose Streaming Services", systemImage: "play.tv") {
                    if let onChooseStreamingServices {
                        onChooseStreamingServices()
                    } else {
                        showsStreamingServices = true
                    }
                }
                .controlSize(.regular)
                .buttonStyle(.bordered)
                .tint(.primary)
                .accessibilityIdentifier("onboarding.streaming")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var actions: some View {
        if let next = OnboardingChapter(rawValue: chapter.rawValue + 1) {
            primaryAction("Continue", identifier: "onboarding.next") {
                chapter = next
            }
        } else if isReview {
            primaryAction("Done", identifier: "onboarding.done") {
                onExit(.library)
            }
        } else {
            VStack(spacing: DSSpacing.sm) {
                primaryAction("Open Library", identifier: "onboarding.openLibrary") {
                    onExit(.library)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: DSSpacing.xl) {
                        searchButton.fixedSize(horizontal: true, vertical: false)
                        importButton.fixedSize(horizontal: true, vertical: false)
                    }

                    VStack(spacing: DSSpacing.xs) {
                        searchButton
                        importButton
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
        }
    }

    private func primaryAction(
        _ title: LocalizedStringKey,
        identifier: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity, minHeight: 28)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .controlSize(.large)
        .accessibilityIdentifier(identifier)
    }

    private var searchButton: some View {
        Button {
            onExit(.search)
        } label: {
            Label("Search for a Title", systemImage: "magnifyingglass")
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .tint(.primary)
        .accessibilityIdentifier("onboarding.search")
    }

    private var importButton: some View {
        Button {
            onExit(.libraryImport)
        } label: {
            Label("Import My List", systemImage: "tray.and.arrow.down")
                .frame(minHeight: 44)
                .contentShape(.rect)
        }
        .tint(.primary)
        .accessibilityIdentifier("onboarding.import")
    }
}

private enum OnboardingChapter: Int, CaseIterable {
    case discover, library, details, lifetime, boxes, shortcuts, settings

    var title: LocalizedStringKey {
        switch self {
        case .discover: "Find your next watch"
        case .library: "Build your Library"
        case .details: "Go beyond the credits"
        case .lifetime: "See your Lifetime"
        case .boxes: "Make a Box"
        case .shortcuts: "CinemaTV at a glance"
        case .settings: "Make it yours"
        }
    }

    var artwork: OnboardingArtwork.Symbols {
        switch self {
        case .discover: .init(center: "binoculars.fill", leading: "magnifyingglass", trailing: "play.tv")
        case .library: .init(center: "books.vertical.fill", leading: "checkmark.circle", trailing: "calendar")
        case .details: .init(center: "play.rectangle.fill", leading: "star.bubble", trailing: "music.note")
        case .lifetime: .init(center: "chart.bar.xaxis", leading: "clock", trailing: "trophy")
        case .boxes: .init(center: "shippingbox.fill", leading: "photo.on.rectangle", trailing: "square.and.arrow.up")
        case .shortcuts: .init(center: "square.grid.2x2.fill", leading: "waveform", trailing: "viewfinder")
        case .settings: .init(center: "gearshape.fill", leading: "globe", trailing: "icloud")
        }
    }

    var features: [OnboardingFeature] {
        switch self {
        case .discover:
            [
                .init("Browse Discover", "See upcoming movies and shows, or swipe through the Discover deck for ideas.", symbol: "rectangle.on.rectangle"),
                .init("Search the catalog", "Find movies, TV shows, and people by name, or browse genres.", symbol: "magnifyingglass"),
                .init("See where to watch", "Check availability in your region. Your selected services appear first in Discover.", symbol: "play.tv")
            ]
        case .library:
            [
                .init("Make a movie queue", "Save movies to Want to Watch and mark them watched when you finish.", symbol: "bookmark"),
                .init("Keep up with shows", "Track episodes, browse upcoming premieres, and turn on release-day alerts in Settings.", symbol: "calendar"),
                .init("Bring your lists with you", "Paste titles or choose screenshots and review matches before adding them.", symbol: "tray.and.arrow.down")
            ]
        case .details:
            [
                .init("Explore the details", "Watch trailers, meet the cast, explore their filmographies, and find related titles.", symbol: "film"),
                .init("Rate and review movies", "Save a rating and share your review as a card.", symbol: "star.bubble"),
                .init("Listen to soundtracks", "Find soundtracks for movies and shows and open them in Apple Music when available.", symbol: "music.note")
            ]
        case .lifetime:
            [
                .init("See what you’ve watched", "Follow your watch time, timeline, rankings, and milestones as your Library grows.", symbol: "chart.bar.xaxis"),
                .init("Share your story", "Turn your Lifetime highlights into an image to share.", symbol: "square.and.arrow.up"),
                .init("Compare with your age", "Add your birth date for an optional, private comparison of watch time with your age.", symbol: "birthday.cake")
            ]
        case .boxes:
            [
                .init("Collect what belongs together", "Add movies, shows, episodes, trailers, music, and notes to a Box.", symbol: "shippingbox"),
                .init("Choose a cover and share", "Pick what goes on the cover and share it as an image.", symbol: "photo.on.rectangle")
            ] + (BoxSharingConfiguration.baseURL != nil ? [
                .init("Share an edition by link", "Publish a snapshot of a Box that anyone with the link can open.", symbol: "link")
            ] : [])
        case .shortcuts:
            [
                .init("Add widgets", "Put Movies, Library, or Quick Action on your Home Screen.", symbol: "square.grid.2x2"),
                .init("Use Siri and Shortcuts", "Open your watchlist, search, or log a movie with a shortcut.", symbol: "waveform"),
                .init("Search from anywhere", "Find titles through Spotlight and use Visual Intelligence on supported devices.", symbol: "viewfinder")
            ]
        case .settings:
            [
                .init("Manage your preferences", "Choose a content region, manage premiere notifications, and check iCloud sync in Settings.", symbol: "gearshape"),
                .init("Check Apple Intelligence", "See which Apple Intelligence models are available on your device.", symbol: "sparkles")
            ] + (TraktConfiguration.fromBundle() != nil ? [
                .init("Connect Trakt", "Import your watchlist and watched progress from Trakt.", symbol: "arrow.triangle.2.circlepath")
            ] : []) + [
                .init("Keep up with CinemaTV", "See what’s new, check what’s coming, and send feedback.", symbol: "text.bubble")
            ]
        }
    }
}

private struct OnboardingFeature: Identifiable {
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let symbol: String

    var id: String { symbol }

    init(_ title: LocalizedStringKey, _ description: LocalizedStringKey, symbol: String) {
        self.title = title
        self.description = description
        self.symbol = symbol
    }
}

private struct OnboardingArtwork: View {
    struct Symbols {
        let center: String
        let leading: String
        let trailing: String
    }

    let symbols: Symbols

    var body: some View {
        ZStack {
            Color(red: 0.075, green: 0.067, blue: 0.09)
            RadialGradient(
                colors: [DSColor.accent.opacity(0.34), .clear],
                center: .bottom,
                startRadius: 12,
                endRadius: 248
            )

            HStack {
                tile(symbols.leading, foreground: .white.opacity(0.78), size: 62)
                    .rotationEffect(.degrees(-13))
                Spacer(minLength: 32)
                tile(symbols.trailing, foreground: .white.opacity(0.78), size: 62)
                    .rotationEffect(.degrees(13))
            }
            .frame(maxWidth: 230)
            .padding(.horizontal, DSSpacing.lg)
            .offset(y: 6)

            tile(symbols.center, foreground: DSColor.accent, size: 96)
                .rotationEffect(.degrees(-5))
        }
        .frame(height: 142)
        .clipShape(.rect(cornerRadius: DSSpacing.xl))
        .accessibilityHidden(true)
    }

    private func tile(_ symbol: String, foreground: Color, size: CGFloat) -> some View {
        Image(systemName: symbol)
            .font(.system(size: size * 0.34, weight: .medium))
            .foregroundStyle(foreground)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.20)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.25, green: 0.20, blue: 0.18), Color(red: 0.14, green: 0.12, blue: 0.14)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .strokeBorder(.white.opacity(0.17))
                    .shadow(color: .black.opacity(0.38), radius: 10, y: 6)
            }
    }
}
