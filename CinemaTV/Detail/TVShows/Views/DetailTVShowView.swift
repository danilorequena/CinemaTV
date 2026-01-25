//
//  DetailTVShowView.swift
//  CinemaTV
//
//  Created by Danilo Requena on 03/10/22.
//

import SwiftUI
import SwiftData

struct DetailTVShowView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) var mocWatching
    @Query var seasons: [TVShowWatchingModel]

    var state: MovieORTVShow
    @StateObject var viewModel = DetailViewModel()
    var id: Int?

    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSaveError = false

    private let seasonService = SeasonService()
    var body: some View {
        ZStack {
            if let detail = viewModel.detailTVShow {
                if viewModel.isDetailLoading && viewModel.isCastLoading {
                    CinemaTVProgressView()
                } else {
                    AsyncImage(url: URL(string: Constants.basePosters + (detail.posterPath ?? String()))) { image in
                        image
                            .resizable()
                    } placeholder: {
                        Image("placeholder-image")
                    }
                    
                    ScrollView {
                        Spacer(minLength: UIScreen.main.bounds.height / 2)
                        VStack {
                            VStack(alignment: .leading, spacing: 16) {
                                InformationDetailView(detailInfos: detail)
                                
                                Menu {
                                    Button("Watching") {
                                        Task {
                                            await saveDataWithEpisodes(detail: detail)
                                        }
                                    }
                                    .disabled(isSaving)

                                    Button("Watched") {
//                                        Implementar o salvamento aqui
                                    }
                                } label: {
                                    HStack {
                                        if isSaving {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "bookmark.fill")
                                        }
                                        Text(isSaving ? LC.loading.text : "Add")
                                            .foregroundColor(.black)
                                    }
                                    .padding(8)
                                    .background(.ultraThinMaterial.opacity(0.2))
                                    .cornerRadius(16)
                                }
                                .disabled(isSaving)
                                .padding(.leading, 8)
                                .alert("Error", isPresented: $showSaveError) {
                                    Button("OK", role: .cancel) {}
                                } message: {
                                    Text(saveError ?? "Unknown error")
                                }
                                
                                TrailersView(videoID: id, videoKey: viewModel.videoKey ?? "")
                                    .padding(16)
                                    .frame(height: 260)
                                
                                if let cast = viewModel.cast?.cast, !cast.isEmpty {
                                    CastView(state: .tvShow, castData: cast)
                                }
                                
                                if let seasons = viewModel.detailTVShow?.seasons,
                                   let seriesID = viewModel.detailTVShow?.id, !seasons.isEmpty {
                                    SeasonsCarouselView(seriesID: seriesID, data: seasons, title: "Seasons")
                                }
                                
                                if let recommendations = viewModel.tvShowsRecommendations?.results, !recommendations.isEmpty {
                                    CarouselInDetailView(data: viewModel.tvShowsRecommendations?.results ?? [], title: LC.recommendations.text)
                                }
                                
                                if let similars = viewModel.tvShowsSimilars?.results, !similars.isEmpty {
                                    CarouselInDetailView(data: viewModel.tvShowsSimilars?.results ?? [], title: LC.similars.text)
                                }
                            }
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                    }
                }
            }
        }
        .task {
            await viewModel.loadDetails(ID: id ?? 0, state: state)
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    @MainActor
    private func saveDataWithEpisodes(detail: DetailTVShow) async {
        guard let showId = detail.id else {
            saveError = "Invalid TV Show ID"
            showSaveError = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        let seasonsData = detail.seasons ?? []
        var seasonModels: [SeasonSD] = []
        var fetchErrors: [String] = []

        // Fetch episodes for each season
        for season in seasonsData {
            guard let seasonNumber = season.seasonNumber else { continue }

            do {
                let seasonDetail = try await fetchSeasonDetail(showId: showId, seasonNumber: seasonNumber)

                let episodes = seasonDetail.episodes.map { episode in
                    EpisodeSD(
                        id: episode.id,
                        airDate: episode.airDate,
                        episodeNumber: episode.episodeNumber,
                        name: episode.name,
                        overview: episode.overview,
                        productionCode: episode.productionCode,
                        runtime: episode.runtime,
                        seasonNumber: episode.seasonNumber,
                        showID: episode.showID,
                        stillPath: episode.stillPath,
                        voteAverage: episode.voteAverage,
                        voteCount: episode.voteCount
                    )
                }

                let seasonSD = SeasonSD(
                    id: seasonDetail.seasonModelID,
                    airDate: seasonDetail.airDate,
                    episodeCount: seasonDetail.episodes.count,
                    name: seasonDetail.name,
                    overview: seasonDetail.overview,
                    posterPath: seasonDetail.posterPath,
                    seasonNumber: seasonDetail.seasonNumber,
                    episodes: episodes
                )

                seasonModels.append(seasonSD)
            } catch {
                fetchErrors.append("Season \(seasonNumber): \(error.localizedDescription)")
                // Create placeholder episodes as fallback
                let episodeCount = season.episodeCount ?? 0
                let episodes = (1...max(1, episodeCount)).map { episodeNum in
                    EpisodeSD(
                        id: (season.id ?? 0) * 1000 + episodeNum,
                        episodeNumber: episodeNum,
                        name: "Episode \(episodeNum)",
                        seasonNumber: seasonNumber,
                        showID: showId
                    )
                }

                let seasonSD = SeasonSD(
                    id: season.id ?? 0,
                    airDate: season.airDate ?? "",
                    episodeCount: episodeCount,
                    name: season.name ?? "",
                    overview: season.overview ?? "",
                    posterPath: season.posterPath ?? "",
                    seasonNumber: seasonNumber,
                    episodes: episodes
                )

                seasonModels.append(seasonSD)
            }
        }

        // Find the first regular season (skip "Specials" which is usually season 0)
        let firstRegularSeason = seasonModels.first { ($0.seasonNumber ?? 0) > 0 }
        let initialSeasonNumber = firstRegularSeason?.seasonNumber ?? seasonModels.first?.seasonNumber ?? 1

        let tvShow = TVShowWatchingModel(
            id: showId,
            name: detail.name ?? "",
            overview: detail.overview ?? "",
            imagePath: detail.posterPath,
            lastUpdated: Date(),
            currentSeasonNumber: initialSeasonNumber,
            currentEpisodeNumber: 1,
            seasons: seasonModels
        )

        mocWatching.insert(tvShow)

        do {
            try mocWatching.save()
            print("TV Show saved successfully with \(seasonModels.count) seasons!")

            if !fetchErrors.isEmpty {
                print("Some seasons used placeholder data: \(fetchErrors.joined(separator: ", "))")
            }
        } catch {
            saveError = error.localizedDescription
            showSaveError = true
        }
    }

    private func fetchSeasonDetail(showId: Int, seasonNumber: Int) async throws -> SeasonModel {
        try await withCheckedThrowingContinuation { continuation in
            seasonService.fetchSeasonDetail(from: .season(seasonID: showId, seasonNumber: seasonNumber)) { result in
                switch result {
                case .success(let seasonModel):
                    continuation.resume(returning: seasonModel)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

#Preview {
    DetailTVShowView(state: .tvShow, id: 71712)
}
