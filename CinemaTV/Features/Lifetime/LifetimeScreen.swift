import Charts
import CinemaTVCore
import CinemaTVDesignSystem
import SwiftData
import SwiftUI

private enum LifetimeCacheProvider {
    static let shared: LifetimeMetadataCache = {
        let directory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return LifetimeMetadataCache(fileURL: directory.appending(path: "LifetimeMetadata.json"))
    }()
}

private enum LifetimeMetadataRequest: Sendable {
    case movie(Int)
    case show(Int)
    case season(LifetimeSeasonKey)
}

private enum LifetimeMetadataResult: Sendable {
    case movie(Int, LifetimeMovieMetadata)
    case show(Int, LifetimeShowMetadata)
    case season(LifetimeSeasonKey, LifetimeSeasonMetadata)
    case failure
}

private enum LifetimeChartScale: String, CaseIterable {
    case monthly, yearly

    var title: LocalizedStringKey {
        switch self {
        case .monthly: "Monthly"
        case .yearly: "Yearly"
        }
    }
}

struct LifetimeScreen: View {
    @Environment(\.tmdbClient) private var client
    @Environment(\.modelContext) private var modelContext
    @Query private var watchedMovies: [MoviesWatched]
    @Query private var watchedEpisodes: [EpisodeSD]
    @Query private var followedShows: [TVShowWatchingModel]
    @Query private var reviews: [MovieReview]
    @Query private var profiles: [LifetimeProfile]

    @State private var movieMetadata: [Int: LifetimeMovieMetadata] = [:]
    @State private var showMetadata: [Int: LifetimeShowMetadata] = [:]
    @State private var seasonMetadata: [LifetimeSeasonKey: LifetimeSeasonMetadata] = [:]
    @State private var loadingCount = 0
    @State private var loadingTotal = 0
    @State private var failedCount = 0
    @State private var isEnriching = false
    @State private var retryGeneration = 0
    @State private var chartScale: LifetimeChartScale = .monthly
    @State private var selectedYear: Int?
    @State private var showsBirthday = false
    @State private var showsShare = false

    private var localeKey: String { Locale.current.identifier }

    private var movieIDs: [Int] {
        Array(Set(watchedMovies.compactMap { $0.id.flatMap(Int.init(exactly:)) })).sorted()
    }

    private var watchedShowIDs: [Int] {
        Array(Set(watchedEpisodes.compactMap(\.showID))).sorted()
    }

    private var missingRuntimeSeasons: [LifetimeSeasonKey] {
        Array(Set(watchedEpisodes.compactMap { episode -> LifetimeSeasonKey? in
            guard (episode.runtime ?? 0) <= 0,
                  let showID = episode.showID,
                  let seasonNumber = episode.seasonNumber,
                  episode.episodeNumber != nil else { return nil }
            return LifetimeSeasonKey(showID: showID, seasonNumber: seasonNumber)
        })).sorted()
    }

    private var metadataTaskID: String {
        let missingEpisodes = watchedEpisodes.compactMap { episode -> String? in
            guard (episode.runtime ?? 0) <= 0,
                  let showID = episode.showID,
                  let season = episode.seasonNumber,
                  let number = episode.episodeNumber else { return nil }
            return "\(showID)-\(season)-\(number)"
        }.sorted().joined(separator: ",")
        return "\(localeKey)|m:\(movieIDs.map(String.init).joined(separator: ","))|s:\(watchedShowIDs.map(String.init).joined(separator: ","))|e:\(missingEpisodes)|\(retryGeneration)"
    }

    private var birthDate: Date? {
        guard let iso = profiles.max(by: { ($0.updatedAt ?? .distantPast) < ($1.updatedAt ?? .distantPast) })?.birthDateISO else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: iso)
    }

    private var snapshot: LifetimeSnapshot {
        let ratings = Dictionary(grouping: reviews.compactMap { review -> (Int, MovieReview)? in
            guard let id = review.movieID.flatMap(Int.init(exactly:)) else { return nil }
            return (id, review)
        }, by: \.0).compactMapValues { entries in
            entries.max { ($0.1.updatedAt ?? .distantPast) < ($1.1.updatedAt ?? .distantPast) }?.1.rating
        }
        let movies: [LifetimeMovieRecord] = watchedMovies.compactMap { movie in
            guard let id = movie.id.flatMap(Int.init(exactly:)) else { return nil }
            let metadata = movieMetadata[id]
            return LifetimeMovieRecord(
                id: id,
                title: movie.name ?? "",
                watchedAt: movie.watchedAt,
                runtimeMinutes: metadata?.runtimeMinutes,
                genres: metadata?.genres ?? [],
                releaseYear: metadata?.releaseYear,
                personalRating: ratings[id]
            )
        }
        let names = Dictionary(grouping: followedShows.compactMap { show -> (Int, String)? in
            guard let id = show.id else { return nil }
            return (id, show.name ?? "")
        }, by: \.0).compactMapValues { $0.first?.1 }
        let episodes: [LifetimeEpisodeRecord] = watchedEpisodes.compactMap { episode in
            guard let showID = episode.showID,
                  let seasonNumber = episode.seasonNumber,
                  let episodeNumber = episode.episodeNumber else { return nil }
            return LifetimeEpisodeRecord(
                showID: showID,
                showName: names[showID] ?? episode.season?.tvShow?.name ?? "",
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                watchedAt: episode.watchedAt,
                runtimeMinutes: (episode.runtime ?? 0) > 0
                    ? episode.runtime
                    : seasonMetadata[LifetimeSeasonKey(showID: showID, seasonNumber: seasonNumber)]?.runtimesByEpisode[episodeNumber]
            )
        }
        let followedByID = Dictionary(grouping: followedShows.compactMap { show -> (Int, TVShowWatchingModel)? in
            guard let id = show.id else { return nil }
            return (id, show)
        }, by: \.0).compactMapValues { $0.first?.1 }
        let episodeNames = Dictionary(grouping: episodes, by: \.showID).compactMapValues { records in
            records.first(where: { !$0.showName.isEmpty })?.showName
        }
        let shows: [LifetimeShowRecord] = watchedShowIDs.map { id in
            let show = followedByID[id]
            return LifetimeShowRecord(
                id: id,
                name: show?.name ?? episodeNames[id] ?? "",
                firstAirYear: showMetadata[id]?.firstAirYear ?? show?.firstAirDate.flatMap { Int($0.prefix(4)) },
                genres: showMetadata[id]?.genres ?? [],
                status: show?.status
            )
        }
        return LifetimeStatistics.calculate(movies: movies, episodes: episodes, shows: shows)
    }

    var body: some View {
        let stats = snapshot
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 22) {
                header
                if stats.totalItemCount == 0 {
                    ContentUnavailableView(
                        "Your Story Is Just Beginning",
                        systemImage: "sparkles.tv",
                        description: Text("Track a movie or episode to start your story.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                } else {
                    durationHero(stats)
                    countCards(stats)
                    enrichmentStatus(stats)
                    timelinePanel(stats)
                    rankingsPanel(stats)
                    milestonesPanel(stats)
                }
                birthdayPanel(stats)
            }
            .padding(.horizontal, DSSpacing.lg)
            .padding(.top, DSSpacing.md)
            .padding(.bottom, DSSpacing.xxl)
        }
        .navigationTitle("Lifetime")
        .toolbarTitleDisplayMode(.inlineLarge)
        .toolbar {
            if stats.totalItemCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showsShare = true
                    } label: {
                        Label("Share Your Story", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("lifetime.share")
                }
            }
        }
        .task(id: metadataTaskID) { await enrichMetadata() }
        .sheet(isPresented: $showsBirthday) {
            LifetimeBirthdaySheet(initialDate: birthDate, store: LifetimeProfileStore(context: modelContext))
        }
        .sheet(isPresented: $showsShare) {
            LifetimeShareSheet(summary: LifetimeShareSummary(snapshot: stats))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("YOUR LIFETIME")
                .font(.caption.weight(.bold))
                .tracking(2)
                .foregroundStyle(DSColor.accent)
            Text("Your Story")
                .font(.system(.largeTitle, design: .serif, weight: .bold))
                .accessibilityAddTraits(.isHeader)
            Text("The stories you've marked as watched, all in one place.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func durationHero(_ stats: LifetimeSnapshot) -> some View {
        LifetimePanel {
            VStack(alignment: .leading, spacing: 10) {
                Label("Duration of titles marked as watched", systemImage: "clock")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                if stats.knownDurationCount > 0 {
                    Text(durationText(stats.totalKnownMinutes))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                        .contentTransition(.numericText())
                        .accessibilityIdentifier("lifetime.duration")
                    if stats.totalKnownMinutes >= 1_440 {
                        Text("\(stats.totalKnownMinutes / 1_440) full days of stories")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.accent)
                    } else {
                        Text("Every story counts.")
                            .font(.subheadline)
                            .foregroundStyle(DSColor.accent)
                    }
                } else {
                    Text("No duration data yet")
                        .font(.title2.weight(.bold))
                        .accessibilityIdentifier("lifetime.duration")
                }
                Text("Based on catalogue runtimes, not measured playback or rewatches.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func countCards(_ stats: LifetimeSnapshot) -> some View {
        HStack(spacing: 12) {
            countCard(value: stats.movieCount, title: "Movies", symbol: "film")
            countCard(value: stats.episodeCount, title: "Episodes", symbol: "play.tv")
        }
    }

    private func countCard(value: Int, title: LocalizedStringKey, symbol: String) -> some View {
        LifetimePanel {
            VStack(alignment: .leading, spacing: 7) {
                Image(systemName: symbol).foregroundStyle(DSColor.accent)
                Text(value.formatted()).font(.title.weight(.bold).monospacedDigit())
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func enrichmentStatus(_ stats: LifetimeSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Duration available for \(stats.knownDurationCount) of \(stats.totalItemCount) titles")
                .font(.caption.weight(.medium))
                .accessibilityIdentifier("lifetime.coverage")
            ProgressView(value: stats.durationCoverage)
                .tint(DSColor.accent)
            if isEnriching {
                Text("Loading catalogue details \(loadingCount) of \(loadingTotal)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if failedCount > 0 {
                Button("Retry missing details") { retryGeneration += 1 }
                    .font(.caption.weight(.medium))
            }
        }
        .padding(.horizontal, 4)
    }

    private func timelinePanel(_ stats: LifetimeSnapshot) -> some View {
        LifetimePanel {
            VStack(alignment: .leading, spacing: 14) {
                sectionTitle("Your timeline", subtitle: "When titles were marked as watched")
                Picker("Timeline", selection: $chartScale) {
                    ForEach(LifetimeChartScale.allCases, id: \.self) { scale in
                        Text(scale.title).tag(scale)
                    }
                }
                .pickerStyle(.segmented)
                if chartScale == .monthly, !availableYears(stats).isEmpty {
                    Picker("Year", selection: $selectedYear) {
                        ForEach(availableYears(stats), id: \.self) { year in
                            Text(year.formatted(.number.grouping(.never))).tag(Optional(year))
                        }
                    }
                    .pickerStyle(.menu)
                    .onAppear {
                        if selectedYear == nil { selectedYear = availableYears(stats).first }
                    }
                    .onChange(of: availableYears(stats)) { _, years in
                        if !years.contains(where: { $0 == selectedYear }) { selectedYear = years.first }
                    }
                }
                if stats.monthlyTimeline.isEmpty {
                    Text("No dated watch records yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else if chartScale == .monthly {
                    monthlyChart(stats)
                } else {
                    yearlyChart(stats)
                }
                if stats.undatedItemCount > 0 {
                    Text("\(stats.undatedItemCount) titles without a watch date are included in totals, but not this chart.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func monthlyChart(_ stats: LifetimeSnapshot) -> some View {
        let year = selectedYear ?? availableYears(stats).first ?? Calendar.current.component(.year, from: .now)
        let values = (1...12).map { month in
            LifetimeTimelineBucket(year: year, month: month, watchedCount: stats.monthlyTimeline.first(where: { $0.year == year && $0.month == month })?.watchedCount ?? 0)
        }
        return Chart(values) { bucket in
            BarMark(
                x: .value("Month", bucket.month),
                y: .value("Titles", bucket.watchedCount)
            )
            .foregroundStyle(DSColor.accent)
        }
        .chartXScale(domain: 0.5...12.5)
        .frame(height: 180)
        .accessibilityLabel("Monthly watch records for \(year)")
        .accessibilityValue("\(values.reduce(0) { $0 + $1.watchedCount }) titles")
    }

    private func yearlyChart(_ stats: LifetimeSnapshot) -> some View {
        let grouped = Dictionary(grouping: stats.monthlyTimeline, by: \.year)
        let values = grouped.map { (year: $0.key, count: $0.value.reduce(0) { $0 + $1.watchedCount }) }.sorted { $0.year < $1.year }
        return Chart(values, id: \.year) { entry in
            BarMark(x: .value("Year", entry.year), y: .value("Titles", entry.count))
                .foregroundStyle(DSColor.accent)
        }
        .frame(height: 180)
        .accessibilityLabel("Yearly watch records")
        .accessibilityValue("\(values.reduce(0) { $0 + $1.count }) titles across \(values.count) years")
    }

    private func availableYears(_ stats: LifetimeSnapshot) -> [Int] {
        Array(Set(stats.monthlyTimeline.map(\.year))).sorted(by: >)
    }

    private func rankingsPanel(_ stats: LifetimeSnapshot) -> some View {
        VStack(spacing: 16) {
            rankingPanel(title: "Your genres", subtitle: "Counted once per watched movie or show", entries: Array(stats.topGenres.prefix(5)))
            rankingPanel(title: "Your decades", subtitle: "Based on original release year", entries: Array(stats.topDecades.prefix(5)))
            if !stats.topShows.isEmpty {
                LifetimePanel {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Shows that stayed with you", subtitle: "Most episodes marked as watched")
                        ForEach(Array(stats.topShows.prefix(5))) { show in
                            NavigationLink(value: Route.tvShowDetail(id: show.showID)) {
                                HStack {
                                    Text(verbatim: show.name).lineLimit(1)
                                    Spacer()
                                    Text(show.episodeCount.formatted()).monospacedDigit().foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            if !stats.favoriteMovies.isEmpty {
                LifetimePanel {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Your favorites", subtitle: "Your own movie ratings")
                        ForEach(Array(stats.favoriteMovies.prefix(5))) { movie in
                            NavigationLink(value: Route.movieDetail(id: movie.id)) {
                                HStack {
                                    Text(verbatim: movie.title).lineLimit(1)
                                    Spacer()
                                    Label(movie.rating.formatted(), systemImage: "star.fill")
                                        .foregroundStyle(DSColor.accent)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func rankingPanel(title: LocalizedStringKey, subtitle: LocalizedStringKey, entries: [LifetimeRanking]) -> some View {
        if !entries.isEmpty {
            LifetimePanel {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle(title, subtitle: subtitle)
                    ForEach(entries) { entry in
                        HStack {
                            Text(verbatim: entry.name)
                            Spacer()
                            Text(entry.count.formatted()).monospacedDigit().foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func milestonesPanel(_ stats: LifetimeSnapshot) -> some View {
        LifetimePanel {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("Milestones", subtitle: "Built from your tracked history")
                ForEach(stats.milestones) { milestone in
                    Label(milestoneTitle(milestone), systemImage: "sparkle")
                        .foregroundStyle(DSColor.accent)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func milestoneTitle(_ milestone: LifetimeMilestone) -> LocalizedStringKey {
        switch milestone {
        case .firstMovie: "First movie"
        case .tenMovies: "10 movies"
        case .hundredMovies: "100 movies"
        case .firstEpisode: "First episode"
        case .hundredEpisodes: "100 episodes"
        case .thousandEpisodes: "1,000 episodes"
        case .hundredHours: "100 hours of stories"
        case .thirtyDays: "30 days of stories"
        }
    }

    private func birthdayPanel(_ stats: LifetimeSnapshot) -> some View {
        LifetimePanel {
            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("A piece of your life", subtitle: "Optional and private")
                if let birthDate {
                    if stats.knownDurationCount > 0,
                       let percentage = LifetimeStatistics.lifePercentage(totalKnownMinutes: stats.totalKnownMinutes, birthDate: birthDate) {
                        Text(percentage.formatted(.number.precision(.fractionLength(3))) + "%")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(DSColor.accent)
                            .accessibilityIdentifier("lifetime.lifePercentage")
                        Text("Of your lifetime in the known duration of titles you've marked as watched.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("The comparison will appear when runtime data is available.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Text("Add your birth date to see this optional comparison.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Button(birthDate == nil ? "Add Birth Date" : "Edit Birth Date") {
                    showsBirthday = true
                }
                .accessibilityIdentifier("lifetime.birthday.edit")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func sectionTitle(_ title: LocalizedStringKey, subtitle: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Text(subtitle).font(.caption).foregroundStyle(.secondary)
        }
    }

    private func durationText(_ minutes: Int) -> String {
        let hours = minutes / 60
        let remaining = minutes % 60
        return "\(hours.formatted())h \(remaining)m"
    }

    private func enrichMetadata() async {
        let movieIDs = self.movieIDs
        let showIDs = self.watchedShowIDs
        let seasonKeys = self.missingRuntimeSeasons
        let locale = localeKey
        let cache = LifetimeCacheProvider.shared
        let cachedMovies = await cache.cachedMovies(ids: movieIDs, locale: locale)
        let cachedShows = await cache.cachedShows(ids: showIDs, locale: locale)
        let cachedSeasons = await cache.cachedSeasons(keys: seasonKeys, locale: locale)
        guard !Task.isCancelled else { return }
        movieMetadata = cachedMovies
        showMetadata = cachedShows
        seasonMetadata = cachedSeasons
        var requests: [LifetimeMetadataRequest] = movieIDs.filter { cachedMovies[$0] == nil }.map(LifetimeMetadataRequest.movie)
        requests += showIDs.filter { cachedShows[$0] == nil }.map(LifetimeMetadataRequest.show)
        requests += seasonKeys.filter { cachedSeasons[$0] == nil }.map(LifetimeMetadataRequest.season)
        loadingTotal = movieIDs.count + showIDs.count + seasonKeys.count
        loadingCount = cachedMovies.count + cachedShows.count + cachedSeasons.count
        failedCount = 0
        isEnriching = !requests.isEmpty
        guard !requests.isEmpty else { return }

        let client = self.client
        let progressInterval = max(5, requests.count / 20)
        await withTaskGroup(of: LifetimeMetadataResult.self) { group in
            var iterator = requests.makeIterator()
            var processed = 0
            var failures = 0
            var pendingMovies: [Int: LifetimeMovieMetadata] = [:]
            var pendingShows: [Int: LifetimeShowMetadata] = [:]
            var pendingSeasons: [LifetimeSeasonKey: LifetimeSeasonMetadata] = [:]
            func submit(_ request: LifetimeMetadataRequest) {
                group.addTask {
                    do {
                        switch request {
                        case .movie(let id):
                            let metadata = try await cache.loadMovie(id: id, locale: locale, client: client)
                            return .movie(id, metadata)
                        case .show(let id):
                            let metadata = try await cache.loadShow(id: id, locale: locale, client: client)
                            return .show(id, metadata)
                        case .season(let key):
                            let metadata = try await cache.loadSeason(showID: key.showID, seasonNumber: key.seasonNumber, locale: locale, client: client)
                            return .season(key, metadata)
                        }
                    } catch {
                        return .failure
                    }
                }
            }
            for _ in 0..<min(3, requests.count) {
                if let request = iterator.next() { submit(request) }
            }
            while let result = await group.next() {
                if Task.isCancelled {
                    group.cancelAll()
                    break
                }
                processed += 1
                switch result {
                case .movie(let id, let metadata): pendingMovies[id] = metadata
                case .show(let id, let metadata): pendingShows[id] = metadata
                case .season(let key, let metadata): pendingSeasons[key] = metadata
                case .failure: failures += 1
                }
                if processed.isMultiple(of: progressInterval) || processed == requests.count {
                    movieMetadata.merge(pendingMovies) { _, new in new }
                    showMetadata.merge(pendingShows) { _, new in new }
                    seasonMetadata.merge(pendingSeasons) { _, new in new }
                    pendingMovies.removeAll()
                    pendingShows.removeAll()
                    pendingSeasons.removeAll()
                    loadingCount = cachedMovies.count + cachedShows.count + cachedSeasons.count + processed
                    failedCount = failures
                }
                if let request = iterator.next() { submit(request) }
            }
        }
        await cache.flush()
        guard !Task.isCancelled else { return }
        isEnriching = false
    }
}

private struct LifetimePanel<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.thinMaterial, in: .rect(cornerRadius: 22))
    }
}

private struct LifetimeBirthdaySheet: View {
    @Environment(\.dismiss) private var dismiss
    let initialDate: Date?
    let store: LifetimeProfileStore
    @State private var selection: Date
    @State private var errorMessage: String?

    init(initialDate: Date?, store: LifetimeProfileStore) {
        self.initialDate = initialDate
        self.store = store
        _selection = State(initialValue: initialDate ?? Calendar.current.date(byAdding: .year, value: -25, to: .now) ?? .now)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Birth Date", selection: $selection, in: ...Date.now, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .accessibilityIdentifier("lifetime.birthday.picker")
                } footer: {
                    Text("This date syncs privately with iCloud. It never appears on your shared card.")
                }
                if initialDate != nil {
                    Section {
                        Button("Remove Birth Date", role: .destructive) { save(nil) }
                            .accessibilityIdentifier("lifetime.birthday.remove")
                    }
                }
            }
            .navigationTitle("Birth Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save(selection) }
                }
            }
            .alert("Could Not Save Birth Date", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private func save(_ date: Date?) {
        do {
            try store.setBirthDate(date)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
