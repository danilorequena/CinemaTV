//
//  TVShowTrackingStore.swift
//  CinemaTVKit
//
//  Tracking de acompanhamento de séries. Modelo esparso: seguir uma série
//  grava o show + skeleton de SeasonSD (episodeCount como denominador);
//  EpisodeSD só existe para episódios assistidos. Uma única implementação
//  para views, App Intents e widgets, como o WatchlistStore.
//

import Foundation
import SwiftData

public struct WatchProgress: Sendable, Equatable {
    public let watched: Int
    public let total: Int

    public init(watched: Int, total: Int) {
        self.watched = watched
        self.total = total
    }

    public var fraction: Double {
        total > 0 ? Double(watched) / Double(total) : 0
    }

    public var isComplete: Bool { total > 0 && watched >= total }
}

public struct UpNextEpisode: Sendable, Equatable {
    public let showID: Int
    public let seasonNumber: Int
    public let episodeNumber: Int
    /// nil quando a temporada do próximo episódio ainda não foi carregada
    /// da rede; a UI usa o fallback "Episode N".
    public let name: String?
    public let stillPath: String?
}

@MainActor
public final class TVShowTrackingStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public convenience init(container: ModelContainer) {
        self.init(context: container.mainContext)
    }

    // MARK: - Queries

    public func watchingShows() throws -> [TVShowWatchingModel] {
        var descriptor = FetchDescriptor<TVShowWatchingModel>()
        descriptor.sortBy = [SortDescriptor(\.sortIndex), SortDescriptor(\.name)]
        return try context.fetch(descriptor)
    }

    public func show(id showID: Int) throws -> TVShowWatchingModel? {
        // Sem #Predicate: o avaliador do SwiftData trapa em propriedades
        // armazenadas chamadas `id` (colisão com PersistentModel.id).
        // A lista de séries acompanhadas é pequena; filtrar em memória.
        try watchingShows().first { $0.id == showID }
    }

    public func isFollowing(showID: Int) -> Bool {
        (try? show(id: showID)) != nil
    }

    public func isEpisodeWatched(showID: Int, seasonNumber: Int, episodeNumber: Int) -> Bool {
        watchedEpisodeNumbers(showID: showID, seasonNumber: seasonNumber).contains(episodeNumber)
    }

    public func watchedEpisodeNumbers(showID: Int, seasonNumber: Int) -> Set<Int> {
        guard let season = try? season(showID: showID, seasonNumber: seasonNumber) else { return [] }
        return Set((season.episodes ?? []).compactMap(\.episodeNumber))
    }

    public func seasonProgress(showID: Int, seasonNumber: Int) -> WatchProgress {
        guard let season = try? season(showID: showID, seasonNumber: seasonNumber) else {
            return WatchProgress(watched: 0, total: 0)
        }
        return WatchProgress(watched: season.episodes?.count ?? 0, total: season.episodeCount ?? 0)
    }

    public func showProgress(showID: Int) -> WatchProgress {
        guard let show = try? show(id: showID) else { return WatchProgress(watched: 0, total: 0) }
        let seasons = regularSeasons(of: show)
        let watched = seasons.reduce(0) { $0 + ($1.episodes?.count ?? 0) }
        let total = show.totalEpisodes ?? seasons.reduce(0) { $0 + ($1.episodeCount ?? 0) }
        return WatchProgress(watched: watched, total: total)
    }

    public func upNext(showID: Int) -> UpNextEpisode? {
        guard let show = try? show(id: showID) else { return nil }
        return upNext(of: show)
    }

    public func upNext(of show: TVShowWatchingModel) -> UpNextEpisode? {
        guard let showID = show.id,
              let seasonNumber = show.nextEpisodeSeason,
              let episodeNumber = show.nextEpisodeNumber else { return nil }
        return UpNextEpisode(
            showID: showID,
            seasonNumber: seasonNumber,
            episodeNumber: episodeNumber,
            name: show.nextEpisodeName,
            stillPath: show.nextEpisodeStillPath
        )
    }

    // MARK: - Mutations

    /// Passa a acompanhar a série: grava o show + uma SeasonSD por temporada
    /// regular (Specials/season 0 ficam de fora nesta fase).
    public func follow(_ details: TVShowDetails) throws {
        guard !isFollowing(showID: details.id) else { return }
        let nextIndex = (try watchingShows().compactMap(\.sortIndex).max() ?? -1) + 1
        let show = TVShowWatchingModel(
            id: details.id,
            name: details.name,
            overview: details.overview,
            imagePath: details.posterPath,
            voteAverage: details.voteAverage,
            firstAirDate: details.firstAirDate,
            dateAdded: .now,
            sortIndex: nextIndex
        )
        context.insert(show)
        let summaries = (details.seasons ?? []).filter { $0.seasonNumber > 0 }
        for summary in summaries {
            let season = SeasonSD(
                id: summary.id,
                airDate: summary.airDate,
                episodeCount: summary.episodeCount,
                name: summary.name,
                overview: summary.overview,
                posterPath: summary.posterPath,
                seasonNumber: summary.seasonNumber,
                tvShow: show
            )
            context.insert(season)
        }
        show.totalEpisodes = summaries.reduce(0) { $0 + ($1.episodeCount ?? 0) }
        updateUpcoming(for: show, from: details)
        recomputeUpNext(for: show)
        try context.save()
    }

    public func unfollow(showID: Int) throws {
        guard let show = try show(id: showID) else { return }
        context.delete(show)
        try context.save()
    }

    public func markEpisodeWatched(_ episode: EpisodeSummary, showID: Int) throws {
        guard let seasonNumber = episode.seasonNumber,
              let season = try season(showID: showID, seasonNumber: seasonNumber) else { return }
        let watched = Set((season.episodes ?? []).compactMap(\.episodeNumber))
        guard !watched.contains(episode.episodeNumber) else { return }
        context.insert(EpisodeSD(
            id: episode.id,
            airDate: episode.airDate,
            episodeNumber: episode.episodeNumber,
            name: episode.name,
            overview: episode.overview,
            runtime: episode.runtime,
            seasonNumber: seasonNumber,
            showID: showID,
            stillPath: episode.stillPath,
            voteAverage: episode.voteAverage,
            watchedAt: .now,
            season: season
        ))
        if let show = season.tvShow {
            recomputeUpNext(for: show)
        }
        try context.save()
    }

    public func unmarkEpisodeWatched(showID: Int, seasonNumber: Int, episodeNumber: Int) throws {
        guard let season = try season(showID: showID, seasonNumber: seasonNumber),
              let episode = (season.episodes ?? []).first(where: { $0.episodeNumber == episodeNumber })
        else { return }
        context.delete(episode)
        if let show = season.tvShow {
            recomputeUpNext(for: show)
        }
        try context.save()
    }

    /// Marca a temporada inteira (insere só os episódios que faltam).
    /// Também reconcilia o episodeCount com a lista real de episódios.
    public func markSeasonWatched(_ details: SeasonDetails, showID: Int) throws {
        guard let season = try season(showID: showID, seasonNumber: details.seasonNumber) else { return }
        reconcileEpisodeCount(of: season, with: details)
        let watched = Set((season.episodes ?? []).compactMap(\.episodeNumber))
        for episode in details.episodes where !watched.contains(episode.episodeNumber) {
            context.insert(EpisodeSD(
                id: episode.id,
                airDate: episode.airDate,
                episodeNumber: episode.episodeNumber,
                name: episode.name,
                overview: episode.overview,
                runtime: episode.runtime,
                seasonNumber: details.seasonNumber,
                showID: showID,
                stillPath: episode.stillPath,
                voteAverage: episode.voteAverage,
                watchedAt: .now,
                season: season
            ))
        }
        if let show = season.tvShow {
            recomputeUpNext(for: show)
        }
        try context.save()
    }

    public func unmarkSeasonWatched(showID: Int, seasonNumber: Int) throws {
        guard let season = try season(showID: showID, seasonNumber: seasonNumber) else { return }
        for episode in season.episodes ?? [] {
            context.delete(episode)
        }
        if let show = season.tvShow {
            recomputeUpNext(for: show)
        }
        try context.save()
    }

    /// Reconcilia metadados quando o detalhe recarrega da rede: temporadas
    /// novas ganham skeleton, episodeCount/nome/poster são atualizados e o
    /// cache de Up Next é recomputado (a série pode ter ganhado episódios).
    public func refreshMetadata(from details: TVShowDetails) throws {
        guard let show = try show(id: details.id) else { return }
        show.name = details.name
        show.overview = details.overview
        show.imagePath = details.posterPath
        show.voteAverage = details.voteAverage
        show.firstAirDate = details.firstAirDate
        let summaries = (details.seasons ?? []).filter { $0.seasonNumber > 0 }
        let existing = regularSeasons(of: show)
        for summary in summaries {
            if let season = existing.first(where: { $0.seasonNumber == summary.seasonNumber }) {
                season.episodeCount = summary.episodeCount
                season.name = summary.name
                season.posterPath = summary.posterPath
                season.airDate = summary.airDate
            } else {
                context.insert(SeasonSD(
                    id: summary.id,
                    airDate: summary.airDate,
                    episodeCount: summary.episodeCount,
                    name: summary.name,
                    overview: summary.overview,
                    posterPath: summary.posterPath,
                    seasonNumber: summary.seasonNumber,
                    tvShow: show
                ))
            }
        }
        show.totalEpisodes = summaries.reduce(0) { $0 + ($1.episodeCount ?? 0) }
        updateUpcoming(for: show, from: details)
        recomputeUpNext(for: show)
        try context.save()
    }

    /// Backfill de migração: séries com episódios assistidos gravados antes
    /// do cache lastActivityAt existir ficavam com o cache nil e caíam na
    /// fila do "Want to Watch" mesmo já começadas. Recomputa uma vez.
    public func backfillActivityCaches() throws {
        var changed = false
        for show in try watchingShows() where show.lastActivityAt == nil {
            recomputeUpNext(for: show)
            if show.lastActivityAt != nil {
                changed = true
            }
        }
        if changed {
            try context.save()
        }
    }

    /// Grava (ou limpa) o cache do próximo episódio a ir ao ar + status.
    private func updateUpcoming(for show: TVShowWatchingModel, from details: TVShowDetails) {
        show.upcomingAirDate = details.nextEpisodeToAir?.airDate
        show.upcomingSeason = details.nextEpisodeToAir?.seasonNumber
        show.upcomingEpisode = details.nextEpisodeToAir.map(\.episodeNumber)
        show.upcomingEpisodeName = details.nextEpisodeToAir?.name
        show.status = details.status
    }

    /// Enriquece o cache de Up Next com nome/still quando a temporada do
    /// próximo episódio acabou de ser carregada da rede (a tab Tracking
    /// nunca busca rede; mostra fallback textual enquanto isso).
    public func updateUpNextCache(showID: Int, from details: SeasonDetails) throws {
        guard let show = try show(id: showID),
              show.nextEpisodeSeason == details.seasonNumber,
              let number = show.nextEpisodeNumber,
              let episode = details.episodes.first(where: { $0.episodeNumber == number }),
              show.nextEpisodeName != episode.name || show.nextEpisodeStillPath != episode.stillPath
        else { return }
        show.nextEpisodeName = episode.name
        show.nextEpisodeStillPath = episode.stillPath
        try context.save()
    }

    // MARK: - Helpers

    private func season(showID: Int, seasonNumber: Int) throws -> SeasonSD? {
        guard let show = try show(id: showID) else { return nil }
        return (show.seasons ?? []).first { $0.seasonNumber == seasonNumber }
    }

    private func regularSeasons(of show: TVShowWatchingModel) -> [SeasonSD] {
        (show.seasons ?? [])
            .filter { ($0.seasonNumber ?? 0) > 0 }
            .sorted { ($0.seasonNumber ?? 0) < ($1.seasonNumber ?? 0) }
    }

    /// O episode_count do summary pode divergir da lista real de episódios
    /// da temporada; a lista completa é a fonte de verdade quando disponível.
    private func reconcileEpisodeCount(of season: SeasonSD, with details: SeasonDetails) {
        let count = details.episodes.count
        if count > 0, season.episodeCount != count {
            season.episodeCount = count
            if let show = season.tvShow {
                show.totalEpisodes = regularSeasons(of: show).reduce(0) { $0 + ($1.episodeCount ?? 0) }
            }
        }
    }

    /// Primeiro (temporada, episódio) sem EpisodeSD gravado, varrendo o
    /// skeleton local — nunca precisa de rede. Nome/still são invalidados
    /// quando o alvo muda; updateUpNextCache preenche depois. Também
    /// recomputa o cache de última atividade (roda em toda mutação).
    private func recomputeUpNext(for show: TVShowWatchingModel) {
        show.lastActivityAt = (show.seasons ?? [])
            .filter { !$0.isDeleted }
            .flatMap { $0.episodes ?? [] }
            .filter { !$0.isDeleted }
            .compactMap(\.watchedAt)
            .max()

        var next: (season: Int, episode: Int)?
        outer: for season in regularSeasons(of: show) {
            guard let seasonNumber = season.seasonNumber,
                  let total = season.episodeCount, total > 0 else { continue }
            // O recompute roda antes do save: a relação ainda contém os
            // EpisodeSD recém-deletados, que não contam como assistidos.
            let watched = Set(
                (season.episodes ?? [])
                    .filter { !$0.isDeleted }
                    .compactMap(\.episodeNumber)
            )
            for episode in 1...total where !watched.contains(episode) {
                next = (seasonNumber, episode)
                break outer
            }
        }
        guard let next else {
            show.nextEpisodeSeason = nil
            show.nextEpisodeNumber = nil
            show.nextEpisodeName = nil
            show.nextEpisodeStillPath = nil
            return
        }
        if show.nextEpisodeSeason != next.season || show.nextEpisodeNumber != next.episode {
            show.nextEpisodeSeason = next.season
            show.nextEpisodeNumber = next.episode
            show.nextEpisodeName = nil
            show.nextEpisodeStillPath = nil
        }
    }
}
