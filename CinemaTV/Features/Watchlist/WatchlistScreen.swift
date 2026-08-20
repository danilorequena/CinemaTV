//
//  WatchlistScreen.swift
//  CinemaTV
//
//  Library em lista única com seções colapsáveis (Watched nasce fechada).
//  Cada item é um card glass com informação útil: datas relativas, progresso,
//  próximo episódio em accent. Headers carregam resumo da seção. Swipe
//  actions fora de List via swipeActionsContainer (iOS 27); reorder por drag
//  nos filmes da fila.
//

import SwiftUI
import SwiftData
import CinemaTVCore
import CinemaTVDesignSystem

typealias ToWatchModel = CinemaTVCore.MoviesToWatch
typealias WatchedModel = CinemaTVCore.MoviesWatched

/// Seções da Library: em andamento, quero assistir (filmes + séries não
/// começadas) e assistidos.
private enum LibrarySection: Hashable {
    case watching
    case wantToWatch
    case watched
}

struct WatchlistScreen: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.tmdbClient) private var client
    @Environment(AppRouter.self) private var router
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var reviewTarget: MediaItem?
    /// Watched nasce colapsada: o histórico não rouba espaço da fila.
    @State private var expanded: Set<LibrarySection> = [.watching, .wantToWatch]
    /// Toggle da seção Settings; a permissão é pedida quando liga.
    @AppStorage("premiereNotificationsEnabled") private var premiereNotificationsEnabled = false

    @Query(sort: [
        SortDescriptor(\ToWatchModel.sortIndex),
        SortDescriptor(\ToWatchModel.name)
    ]) private var toWatch: [ToWatchModel]

    @Query(sort: [SortDescriptor(\WatchedModel.name)]) private var watched: [WatchedModel]

    // O cache de Up Next mora no TVShowWatchingModel: mutações profundas
    // (EpisodeSD) tocam o show, então esta query re-renderiza as seções.
    @Query(sort: [
        SortDescriptor(\TVShowWatchingModel.sortIndex),
        SortDescriptor(\TVShowWatchingModel.name)
    ]) private var watchingShows: [TVShowWatchingModel]

    private var store: WatchlistStore {
        WatchlistStore(context: modelContext)
    }

    private var trackingStore: TVShowTrackingStore {
        TVShowTrackingStore(context: modelContext)
    }

    private var reviewStore: ReviewStore {
        ReviewStore(context: modelContext)
    }

    var body: some View {
        Group {
            if toWatch.isEmpty && watched.isEmpty && watchingShows.isEmpty {
                EmptyStateView(
                    title: "Your Library Is Empty",
                    message: "Add movies and shows from the Discover tab to start tracking.",
                    systemImage: "books.vertical"
                )
            } else {
                library
            }
        }
        .navigationTitle("Library")
        .task {
            // Migração: séries marcadas antes do cache lastActivityAt
            // existir caíam na fila; o backfill as devolve ao Watching.
            try? trackingStore.backfillActivityCaches()
            // Refresh silencioso (1x/dia): datas/status das seguidas e da
            // fila; depois re-agenda as notificações com a agenda fresca.
            await LibraryRefresher.refreshIfNeeded(client: client, context: modelContext)
            await PremiereNotifications.sync(
                enabled: premiereNotificationsEnabled,
                entries: premiereNotificationEntries
            )
        }
        .onChange(of: premiereNotificationsEnabled) { _, enabled in
            Task {
                if enabled {
                    guard await PremiereNotifications.requestAuthorization() else {
                        // Permissão negada: o toggle volta a refletir a verdade.
                        premiereNotificationsEnabled = false
                        return
                    }
                }
                await PremiereNotifications.sync(
                    enabled: premiereNotificationsEnabled,
                    entries: premiereNotificationEntries
                )
            }
        }
        .sheet(item: $reviewTarget) { item in
            ReviewComposerSheet(item: item)
        }
    }

    // MARK: - Lista única com seções

    private var library: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: DSSpacing.lg) {
                // Up Next: agenda de ESTREIAS — só o que ainda não foi ao
                // ar (episódios/temporadas de séries seguidas e filmes da
                // fila), com contagem regressiva.
                if !upcomingPremieres.isEmpty {
                    Text("Up Next")
                        .font(.dsSectionTitle)
                        .accessibilityAddTraits(.isHeader)
                        .padding(.horizontal, DSSpacing.lg)
                    premiereAgenda
                }

                // Watching primeiro nas listas: "continue de onde parou".
                if !activeShows.isEmpty {
                    sectionHeader(
                        .watching,
                        title: "Watching",
                        count: activeShows.count,
                        detail: watchingDetail
                    )
                    if expanded.contains(.watching) {
                        ForEach(sortedActiveShows) { show in
                            watchingCard(show)
                        }
                    }
                }

                if !wantToWatchIsEmpty {
                    sectionHeader(
                        .wantToWatch,
                        title: "Want to Watch",
                        count: toWatch.count + queuedShows.count,
                        detail: wantToWatchDetail
                    )
                    .padding(.top, activeShows.isEmpty && upcomingPremieres.isEmpty ? 0 : DSSpacing.md)
                    if expanded.contains(.wantToWatch) {
                        ForEach(toWatch) { movie in
                            queueMovieCard(movie)
                        }
                        .reorderable()

                        ForEach(queuedShows) { show in
                            queuedShowCard(show)
                        }
                    }
                }

                if !watched.isEmpty || !completedShows.isEmpty {
                    sectionHeader(
                        .watched,
                        title: "Watched",
                        count: watched.count + completedShows.count,
                        detail: watchedDetail
                    )
                    .padding(.top, DSSpacing.md)
                    if expanded.contains(.watched) {
                        ForEach(watchedEntries) { entry in
                            switch entry {
                            case .movie(let movie): watchedCard(movie)
                            case .show(let show): completedShowCard(show)
                            }
                        }
                    }
                }

                settingsSection
                    .padding(.top, DSSpacing.xl)
            }
            .padding(.vertical, DSSpacing.lg)
        }
        .swipeActionsContainer()
        .reorderContainer(for: ToWatchModel.self) { difference in
            applyReorder(difference)
        }
        .sensoryFeedback(.impact(weight: .light), trigger: toWatch.compactMap(\.sortIndex))
    }

    private var wantToWatchIsEmpty: Bool {
        toWatch.isEmpty && queuedShows.isEmpty
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            Text("Settings")
                .font(.dsSectionTitle)
                .accessibilityAddTraits(.isHeader)
            Toggle(isOn: $premiereNotificationsEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premiere notifications")
                        .font(.dsCardTitle)
                    Text("Get notified on release day for shows and movies in your library.")
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                }
            }
            .tint(DSColor.accent)
        }
        .padding(.horizontal, DSSpacing.lg)
    }

    // MARK: - Agenda "Up Next" (estreias com contagem regressiva)

    /// Item da agenda: filme da fila ou próximo episódio de série seguida,
    /// sempre com data futura (>= hoje, em GMT).
    private struct UpcomingPremiere: Identifiable {
        let id: String
        let item: MediaItem
        let scope: String
        let subtitle: Text
        /// Corpo da notificação local de estreia deste item.
        let notificationBody: String
        let date: Date
    }

    private var upcomingPremieres: [UpcomingPremiere] {
        let today = gmtCalendar.startOfDay(for: .now)
        var items: [UpcomingPremiere] = []

        for movie in toWatch {
            guard let date = parseISODate(movie.releaseDate), date >= today else { continue }
            items.append(UpcomingPremiere(
                id: "movie-\(movie.id ?? 0)",
                item: movie.mediaItem,
                scope: "watchlist",
                subtitle: Text("In theaters"),
                notificationBody: String(localized: "In theaters today"),
                date: date
            ))
        }

        for show in watchingShows {
            guard let date = parseISODate(show.upcomingAirDate), date >= today,
                  let season = show.upcomingSeason,
                  let episode = show.upcomingEpisode else { continue }
            // E1 = estreia de temporada; o resto é episódio novo.
            let subtitle: Text
            let notificationBody: String
            if episode == 1 {
                subtitle = Text("Season \(season) premiere")
                notificationBody = String(localized: "Season \(season) premieres today")
            } else {
                notificationBody = String(localized: "S\(season) E\(episode) airs today")
                if let name = show.upcomingEpisodeName, !name.isEmpty {
                    subtitle = Text(verbatim: "S\(season) E\(episode) · \(name)")
                } else {
                    subtitle = Text(verbatim: "S\(season) E\(episode)")
                }
            }
            items.append(UpcomingPremiere(
                id: "show-\(show.id ?? 0)",
                item: show.mediaItem,
                scope: "watching",
                subtitle: subtitle,
                notificationBody: notificationBody,
                date: date
            ))
        }

        return items.sorted { $0.date < $1.date }
    }

    /// Entradas para as notificações locais (mesma fonte da agenda).
    private var premiereNotificationEntries: [PremiereNotifications.Entry] {
        upcomingPremieres.map { premiere in
            PremiereNotifications.Entry(
                id: premiere.id,
                title: premiere.item.title,
                body: premiere.notificationBody,
                date: premiere.date
            )
        }
    }

    private var premiereAgenda: some View {
        let thisWeek = upcomingPremieres.filter { daysUntil($0.date) <= 7 }
        let later = upcomingPremieres.filter { daysUntil($0.date) > 7 }

        return VStack(alignment: .leading, spacing: DSSpacing.md) {
            if !thisWeek.isEmpty {
                agendaGroupLabel(Text("This Week"))
                ForEach(thisWeek) { premiere in
                    premiereRow(premiere)
                }
            }
            if !later.isEmpty {
                agendaGroupLabel(Text("Later"))
                    .padding(.top, thisWeek.isEmpty ? 0 : DSSpacing.sm)
                ForEach(later) { premiere in
                    premiereRow(premiere)
                }
            }
        }
    }

    private func agendaGroupLabel(_ text: Text) -> some View {
        text
            .font(.caption2.weight(.bold))
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .padding(.horizontal, DSSpacing.lg)
    }

    /// Row K1: bloco de data estilo calendário + poster + countdown accent.
    private func premiereRow(_ premiere: UpcomingPremiere) -> some View {
        let selection = MediaSelection(item: premiere.item, scope: premiere.scope)

        return NavigationLink(value: selection) {
            HStack(spacing: DSSpacing.md) {
                VStack(spacing: 0) {
                    // GMT: a data ISO vive em meia-noite UTC; formatar local
                    // regrediria um dia em fusos negativos.
                    Text(verbatim: premiere.date.formatted(Date.FormatStyle(timeZone: .gmt).month(.abbreviated)).uppercased())
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(DSColor.accent)
                    Text(verbatim: premiere.date.formatted(Date.FormatStyle(timeZone: .gmt).day()))
                        .font(.title3.bold())
                        .monospacedDigit()
                }
                .frame(width: 48)
                .padding(.vertical, DSSpacing.sm)
                .glassEffect(.regular, in: .rect(cornerRadius: DSRadius.poster))

                PosterImage(path: premiere.item.posterPath, kind: .thumbnail)
                    .frame(width: 40)
                    .clipShape(.rect(cornerRadius: DSRadius.poster / 2))

                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: premiere.item.title)
                        .font(.dsCardTitle)
                        .lineLimit(1)
                    premiere.subtitle
                        .font(.dsCaption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    Text(verbatim: countdownLine(for: premiere.date))
                        .font(.caption2)
                        .foregroundStyle(DSColor.accent)
                }
                Spacer(minLength: 0)
            }
            .contentShape(.rect)
            .padding(.horizontal, DSSpacing.lg)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }

    // As datas do TMDB são dias ISO sem fuso; tudo em GMT para a contagem
    // não escorregar um dia em fusos negativos.
    private var gmtCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }

    private func parseISODate(_ iso: String?) -> Date? {
        guard let iso else { return nil }
        return try? Date(iso, strategy: .iso8601.year().month().day())
    }

    private func daysUntil(_ date: Date) -> Int {
        let start = gmtCalendar.startOfDay(for: .now)
        return gmtCalendar.dateComponents([.day], from: start, to: date).day ?? 0
    }

    /// "In 3 days · Wednesday" (Today/Tomorrow nos extremos).
    private func countdownLine(for date: Date) -> String {
        let days = daysUntil(date)
        let countdown = switch days {
        case 0: String(localized: "Today")
        case 1: String(localized: "Tomorrow")
        default: String(localized: "In \(days) days")
        }
        let weekday = date.formatted(Date.FormatStyle(timeZone: .gmt).weekday(.wide))
        return "\(countdown) · \(weekday)"
    }

    // MARK: - Headers com resumo

    private func sectionHeader(
        _ section: LibrarySection,
        title: LocalizedStringKey,
        count: Int,
        detail: String?
    ) -> some View {
        let isExpanded = expanded.contains(section)

        return Button {
            withAnimation(DSMotion.respecting(reduceMotion, DSMotion.snappy)) {
                if isExpanded {
                    expanded.remove(section)
                } else {
                    expanded.insert(section)
                }
            }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.sm) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: DSSpacing.sm) {
                        Text(title)
                            .font(.dsSectionTitle)
                        Text(count, format: .number)
                            .font(.dsCaption.bold())
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: Double(count)))
                    }
                    if let detail {
                        Text(verbatim: detail)
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
            }
            .contentShape(.rect)
            .padding(.horizontal, DSSpacing.lg)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isHeader)
        .accessibilityValue(isExpanded ? Text("Expanded") : Text("Collapsed"))
        .animation(DSMotion.respecting(reduceMotion, DSMotion.snappy), value: count)
    }

    /// "3 movies · 1 show" — breakdown da fila.
    private var wantToWatchDetail: String? {
        var parts: [String] = []
        if !toWatch.isEmpty {
            parts.append(String(localized: "\(toWatch.count) movies"))
        }
        if !queuedShows.isEmpty {
            parts.append(String(localized: "\(queuedShows.count) shows"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    /// "23 of 88 episodes" — progresso agregado das séries em andamento.
    private var watchingDetail: String? {
        let summary = activeShows.reduce(into: (watched: 0, total: 0)) { acc, show in
            guard let showID = show.id else { return }
            let progress = trackingStore.showProgress(showID: showID)
            acc.watched += progress.watched
            acc.total += progress.total
        }
        guard summary.total > 0 else { return nil }
        return String(localized: "\(summary.watched) of \(summary.total) episodes")
    }

    /// "4 reviewed · 2 shows" — reviews dos filmes + séries completas.
    private var watchedDetail: String? {
        var parts: [String] = []
        let reviewed = watched.reduce(0) { count, movie in
            count + (reviewStore.hasReview(movieID: Int(movie.id ?? 0)) ? 1 : 0)
        }
        if reviewed > 0 {
            parts.append(String(localized: "\(reviewed) reviewed"))
        }
        if !completedShows.isEmpty {
            parts.append(String(localized: "\(completedShows.count) shows"))
        }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    // MARK: - Fila: filmes

    private func queueMovieCard(_ movie: ToWatchModel) -> some View {
        let item = movie.mediaItem
        let selection = MediaSelection(item: item, scope: "watchlist")

        return NavigationLink(value: selection) {
            LibraryRow(zoomSourceID: selection.sourceID) {
                HStack(alignment: .top, spacing: DSSpacing.md) {
                    PosterImage(path: item.posterPath, kind: .thumbnail)
                        .frame(width: 60)
                        .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(verbatim: item.title)
                            .font(.dsCardTitle)
                            .lineLimit(2)
                        Text(verbatim: queueMovieMeta(item: item, movie: movie))
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                        if !item.overview.isEmpty {
                            Text(verbatim: item.overview)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    Spacer(minLength: 0)
                    Button {
                        markWatched(item)
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .opacity(0.35)
                            .padding(DSSpacing.sm)
                            .glassEffect(.regular.interactive(), in: .circle)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("Mark as Watched"))
                    // O símbolo checkmark herda o trait Selected; sem remover,
                    // o VoiceOver anuncia "Selected" antes do filme ser visto.
                    .accessibilityRemoveTraits(.isSelected)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                markWatched(item)
            } label: {
                Label("Mark as Watched", systemImage: "checkmark.circle")
            }
            Button(role: .destructive) {
                removeFromWatchlist(item)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                removeFromWatchlist(item)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                markWatched(item)
            } label: {
                Label("Mark as Watched", systemImage: "checkmark.circle")
            }
            .tint(DSColor.accent)
        }
    }

    private func queueMovieMeta(item: MediaItem, movie: ToWatchModel) -> String {
        var parts: [String] = []
        if item.voteAverage > 0 {
            parts.append("★ \(item.voteAverage.formatted(.number.precision(.fractionLength(1))))")
        }
        if let added = relativeDate(movie.dateAdded) {
            parts.append(String(localized: "Added \(added)"))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Fila: séries não começadas

    /// Séries seguidas sem nenhum episódio marcado vivem na fila; a primeira
    /// marcação preenche lastActivityAt e as promove a Watching.
    private var queuedShows: [TVShowWatchingModel] {
        watchingShows
            .filter { $0.lastActivityAt == nil }
            .sorted { lhs, rhs in
                switch (lhs.dateAdded, rhs.dateAdded) {
                case let (left?, right?): left > right
                case (.some, nil): true
                case (nil, .some): false
                case (nil, nil): (lhs.name ?? "") < (rhs.name ?? "")
                }
            }
    }

    private func queuedShowCard(_ show: TVShowWatchingModel) -> some View {
        let item = show.mediaItem
        let selection = MediaSelection(item: item, scope: "watching")

        return NavigationLink(value: selection) {
            LibraryRow(zoomSourceID: selection.sourceID) {
                HStack(alignment: .top, spacing: DSSpacing.md) {
                    PosterImage(path: item.posterPath, kind: .thumbnail)
                        .frame(width: 60)
                        .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(verbatim: item.title)
                            .font(.dsCardTitle)
                            .lineLimit(2)
                        Text(verbatim: queuedShowMeta(show))
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                        if let start = startLabel(for: show) {
                            Label {
                                start
                            } icon: {
                                Image(systemName: "checklist")
                            }
                            .font(.caption)
                            .foregroundStyle(DSColor.accent)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            showContextMenu(show)
        }
        .swipeActions(edge: .trailing) {
            unfollowSwipeButton(show)
        }
        .swipeActions(edge: .leading) {
            Button {
                continueWatching(show)
            } label: {
                Label("Start Watching", systemImage: "checklist")
            }
            .tint(DSColor.accent)
        }
    }

    private func queuedShowMeta(_ show: TVShowWatchingModel) -> String {
        var parts: [String] = []
        let seasons = (show.seasons ?? []).count
        if seasons > 0 {
            parts.append(String(localized: "\(seasons) Seasons"))
        }
        if let episodes = show.totalEpisodes, episodes > 0 {
            parts.append(String(localized: "\(episodes) episodes"))
        }
        if let added = relativeDate(show.dateAdded) {
            parts.append(String(localized: "Added \(added)"))
        }
        return parts.joined(separator: " · ")
    }

    /// "Start with S1 E1 · Pilot" (nome quando o cache já tem).
    private func startLabel(for show: TVShowWatchingModel) -> Text? {
        guard let season = show.nextEpisodeSeason, let episode = show.nextEpisodeNumber else {
            return nil
        }
        if let name = show.nextEpisodeName {
            return Text("Start with S\(season) E\(episode) · \(name)")
        }
        return Text("Start with S\(season) E\(episode)")
    }

    // MARK: - Watching (séries em andamento)

    /// Séries com episódio marcado E ainda incompletas. Completas saem do
    /// Watching (vivem na Watched) e voltam sozinhas quando o refresh de
    /// metadados trouxer episódios novos — o que nunca acontece com séries
    /// encerradas/canceladas.
    private var activeShows: [TVShowWatchingModel] {
        watchingShows.filter { $0.lastActivityAt != nil && !progress(for: $0).isComplete }
    }

    /// Séries 100% assistidas — moram na seção Watched.
    private var completedShows: [TVShowWatchingModel] {
        watchingShows.filter { progress(for: $0).isComplete }
    }

    /// "Continue de onde parou": última atividade primeiro.
    private var sortedActiveShows: [TVShowWatchingModel] {
        activeShows.sorted { lhs, rhs in
            switch (lhs.lastActivityAt, rhs.lastActivityAt) {
            case let (left?, right?): left > right
            case (.some, nil): true
            case (nil, .some): false
            case (nil, nil): (lhs.name ?? "") < (rhs.name ?? "")
            }
        }
    }

    private func watchingCard(_ show: TVShowWatchingModel) -> some View {
        let item = show.mediaItem
        let selection = MediaSelection(item: item, scope: "watching")
        let progress = progress(for: show)

        return NavigationLink(value: selection) {
            LibraryRow(zoomSourceID: selection.sourceID) {
                HStack(alignment: .top, spacing: DSSpacing.md) {
                    PosterImage(path: item.posterPath, kind: .thumbnail)
                        .frame(width: 60)
                        .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(verbatim: item.title)
                            .font(.dsCardTitle)
                            .lineLimit(2)
                        if progress.total > 0 {
                            DSProgressBar(progress: progress.fraction)
                        }
                        Text(verbatim: watchingMeta(show: show, progress: progress))
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        if let upNext = upNextLabel(for: show) {
                            Label {
                                upNext
                            } icon: {
                                Image(systemName: "checklist")
                            }
                            .font(.caption)
                            .foregroundStyle(DSColor.accent)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            showContextMenu(show)
        }
        .swipeActions(edge: .trailing) {
            unfollowSwipeButton(show)
        }
        .swipeActions(edge: .leading) {
            Button {
                continueWatching(show)
            } label: {
                Label("Continue Watching", systemImage: "checklist")
            }
            .tint(DSColor.accent)
        }
    }

    private func watchingMeta(show: TVShowWatchingModel, progress: WatchProgress) -> String {
        var parts: [String] = []
        if progress.total > 0 {
            parts.append(String(localized: "\(progress.watched) of \(progress.total)"))
        }
        if let activity = relativeDate(show.lastActivityAt) {
            parts.append(String(localized: "Last watched \(activity)"))
        }
        return parts.joined(separator: " · ")
    }

    private func progress(for show: TVShowWatchingModel) -> WatchProgress {
        guard let showID = show.id else { return WatchProgress(watched: 0, total: 0) }
        return trackingStore.showProgress(showID: showID)
    }

    private func upNextLabel(for show: TVShowWatchingModel) -> Text? {
        guard let season = show.nextEpisodeSeason, let episode = show.nextEpisodeNumber else {
            return nil
        }
        if let name = show.nextEpisodeName {
            return Text("Up next: S\(season) E\(episode) · \(name)")
        }
        // Nome ainda não cacheado (temporada não visitada): só os números.
        return Text("Up next: S\(season) E\(episode)")
    }

    @ViewBuilder
    private func showContextMenu(_ show: TVShowWatchingModel) -> some View {
        if let upNext = trackingStore.upNext(of: show) {
            Button {
                // Sem sourceID: menu de contexto não tem card visível de
                // onde o zoom possa partir.
                router.push(Route.season(
                    tvShowID: upNext.showID,
                    seasonNumber: upNext.seasonNumber,
                    sourceID: nil
                ))
            } label: {
                Label("Continue Watching", systemImage: "checklist")
            }
        }
        Button(role: .destructive) {
            unfollow(show)
        } label: {
            Label("Unfollow", systemImage: "minus.circle")
        }
    }

    private func unfollowSwipeButton(_ show: TVShowWatchingModel) -> some View {
        Button(role: .destructive) {
            unfollow(show)
        } label: {
            Label("Unfollow", systemImage: "minus.circle")
        }
    }

    private func unfollow(_ show: TVShowWatchingModel) {
        guard let showID = show.id else { return }
        withAnimation(DSMotion.respecting(reduceMotion)) {
            try? trackingStore.unfollow(showID: showID)
        }
    }

    /// Vai direto à temporada do próximo episódio (cache denormalizado).
    private func continueWatching(_ show: TVShowWatchingModel) {
        guard let showID = show.id, let season = show.nextEpisodeSeason else { return }
        router.push(Route.season(tvShowID: showID, seasonNumber: season, sourceID: nil))
    }

    // MARK: - Watched

    /// Filmes e séries completas numa lista só, do mais recente para o mais
    /// antigo (filme = watchedAt; série = lastActivityAt); sem data → fim.
    private enum WatchedEntry: Identifiable {
        case movie(WatchedModel)
        case show(TVShowWatchingModel)

        var id: String {
            switch self {
            case .movie(let movie): "movie-\(movie.id ?? 0)"
            case .show(let show): "show-\(show.id ?? 0)"
            }
        }

        var sortDate: Date? {
            switch self {
            case .movie(let movie): movie.watchedAt
            case .show(let show): show.lastActivityAt
            }
        }

        var sortName: String {
            switch self {
            case .movie(let movie): movie.name ?? ""
            case .show(let show): show.name ?? ""
            }
        }
    }

    private var watchedEntries: [WatchedEntry] {
        let entries = watched.map(WatchedEntry.movie) + completedShows.map(WatchedEntry.show)
        return entries.sorted { lhs, rhs in
            switch (lhs.sortDate, rhs.sortDate) {
            case let (left?, right?): left > right
            case (.some, nil): true
            case (nil, .some): false
            case (nil, nil): lhs.sortName < rhs.sortName
            }
        }
    }

    private func watchedCard(_ movie: WatchedModel) -> some View {
        let item = movie.mediaItem
        let selection = MediaSelection(item: item, scope: "watched")
        let hasReview = reviewStore.hasReview(movieID: item.id)

        return NavigationLink(value: selection) {
            LibraryRow(zoomSourceID: selection.sourceID) {
                HStack(alignment: .top, spacing: DSSpacing.md) {
                    PosterImage(path: item.posterPath, kind: .thumbnail)
                        .frame(width: 60)
                        .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(verbatim: item.title)
                            .font(.dsCardTitle)
                            .lineLimit(2)
                        Text(verbatim: watchedMeta(item: item, movie: movie))
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                        if hasReview {
                            Label {
                                Text("Reviewed")
                            } icon: {
                                Image(systemName: "star.bubble")
                            }
                            .font(.caption)
                            .foregroundStyle(DSColor.accent)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                reviewTarget = item
            } label: {
                Label(
                    hasReview ? "Edit Review" : "Write Review",
                    systemImage: "star.bubble"
                )
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                try? store.unmarkWatched(movieID: item.id)
            } label: {
                Label("Remove", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                reviewTarget = item
            } label: {
                Label(
                    hasReview ? "Edit Review" : "Write Review",
                    systemImage: "star.bubble"
                )
            }
            .tint(DSColor.accent)
        }
    }

    /// Série 100% assistida na seção Watched: progresso completo + status
    /// explicando por que saiu do Watching.
    private func completedShowCard(_ show: TVShowWatchingModel) -> some View {
        let item = show.mediaItem
        let selection = MediaSelection(item: item, scope: "watching")
        let progress = progress(for: show)

        return NavigationLink(value: selection) {
            LibraryRow(zoomSourceID: selection.sourceID) {
                HStack(alignment: .top, spacing: DSSpacing.md) {
                    PosterImage(path: item.posterPath, kind: .thumbnail)
                        .frame(width: 60)
                        .clipShape(.rect(cornerRadius: DSRadius.poster / 2))
                    VStack(alignment: .leading, spacing: DSSpacing.xs) {
                        Text(verbatim: item.title)
                            .font(.dsCardTitle)
                            .lineLimit(2)
                        Text(verbatim: watchingMeta(show: show, progress: progress))
                            .font(.dsCaption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                        completedStatusLabel(show)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                unfollow(show)
            } label: {
                Label("Unfollow", systemImage: "minus.circle")
            }
        }
        .swipeActions(edge: .trailing) {
            unfollowSwipeButton(show)
        }
    }

    /// Encerrada/cancelada = definitivo; ativa = pode voltar ao Watching.
    @ViewBuilder
    private func completedStatusLabel(_ show: TVShowWatchingModel) -> some View {
        switch show.status {
        case "Ended":
            Label {
                Text("Ended")
            } icon: {
                Image(systemName: "checkmark.seal.fill")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        case "Canceled":
            Label {
                Text("Canceled")
            } icon: {
                Image(systemName: "xmark.seal")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        default:
            Label {
                Text("Waiting for new episodes")
            } icon: {
                Image(systemName: "hourglass")
            }
            .font(.caption)
            .foregroundStyle(DSColor.accent)
        }
    }

    private func watchedMeta(item: MediaItem, movie: WatchedModel) -> String {
        var parts: [String] = []
        if item.voteAverage > 0 {
            parts.append("★ \(item.voteAverage.formatted(.number.precision(.fractionLength(1))))")
        }
        if let watchedDate = relativeDate(movie.watchedAt) {
            parts.append(String(localized: "Watched \(watchedDate)"))
        }
        return parts.joined(separator: " · ")
    }

    // MARK: - Ações e helpers

    private func markWatched(_ item: MediaItem) {
        withAnimation(DSMotion.respecting(reduceMotion)) {
            try? store.markWatched(item)
            SpotlightIndexer.deindex(movieID: item.id)
        }
    }

    private func removeFromWatchlist(_ item: MediaItem) {
        withAnimation(DSMotion.respecting(reduceMotion)) {
            try? store.removeFromWatchlist(movieID: item.id)
            SpotlightIndexer.deindex(movieID: item.id)
        }
    }

    /// "2 days ago" / "yesterday", localizado pelo sistema.
    private func relativeDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        return date.formatted(.relative(presentation: .named))
    }

    // MARK: - Reorder

    private func applyReorder(_ difference: ReorderDifference<ToWatchModel.ID, ReorderableSingleCollectionIdentifier>) {
        var ordered = toWatch
        let moving = Set(difference.sources)
        guard !moving.isEmpty else { return }

        var moved: [ToWatchModel] = []
        ordered.removeAll { element in
            guard moving.contains(element.id) else { return false }
            moved.append(element)
            return true
        }

        switch difference.destination.position {
        case .before(let id):
            let index = ordered.firstIndex { $0.id == id } ?? ordered.endIndex
            ordered.insert(contentsOf: moved, at: index)
        case .end:
            ordered.append(contentsOf: moved)
        }

        try? store.reorderToWatch(ordered)
    }
}

// MARK: - Row da Library

/// Container comum dos itens: row plana (sem superfície própria) com
/// zoom source e área de toque cheia.
private struct LibraryRow<Content: View>: View {
    @Environment(\.mediaZoomNamespace) private var zoomNamespace

    var zoomSourceID: String?
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(.rect)
            .modifier(ZoomSourceModifier(id: zoomSourceID, namespace: zoomNamespace))
            .padding(.horizontal, DSSpacing.lg)
            .padding(.vertical, DSSpacing.xs)
    }
}

// MARK: - Mapeamento para o design system

extension CinemaTVCore.MoviesToWatch {
    var mediaItem: MediaItem {
        MediaItem(
            id: Int(id ?? 0),
            title: name ?? "",
            overview: overview ?? "",
            posterPath: profilePath,
            backdropPath: nil,
            voteAverage: counter ?? 0,
            releaseDate: nil,
            mediaType: .movie
        )
    }
}

extension CinemaTVCore.MoviesWatched {
    var mediaItem: MediaItem {
        MediaItem(
            id: Int(id ?? 0),
            title: name ?? "",
            overview: overview ?? "",
            posterPath: profilePath,
            backdropPath: nil,
            voteAverage: counter ?? 0,
            releaseDate: nil,
            mediaType: .movie
        )
    }
}

extension CinemaTVCore.TVShowWatchingModel {
    var mediaItem: MediaItem {
        MediaItem(
            id: id ?? 0,
            title: name ?? "",
            overview: overview ?? "",
            posterPath: imagePath,
            backdropPath: nil,
            voteAverage: voteAverage ?? 0,
            releaseDate: firstAirDate,
            mediaType: .tvShow
        )
    }
}
