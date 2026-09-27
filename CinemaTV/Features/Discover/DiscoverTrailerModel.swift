import Foundation
import Observation
import CinemaTVCore

/// Uma única reprodução por feed; respostas de uma página antiga são descartadas.
@MainActor
@Observable
final class DiscoverTrailerModel {
    enum Phase: Equatable {
        case idle
        case loading
        case preparing(Video)
        case ready(Video)
        case failed
        case unavailable
    }

    private(set) var movieID: Int?
    private(set) var phase: Phase = .idle
    @ObservationIgnored private var task: Task<Void, Never>?
    private(set) var playbackID = UUID()
    private var cache: [Int: Video] = [:]

    var video: Video? {
        switch phase {
        case .preparing(let video), .ready(let video): video
        default: nil
        }
    }

    var isReady: Bool {
        if case .ready = phase { return true }
        return false
    }

    var watchURL: URL? {
        guard let movieID, let video = cache[movieID] else { return nil }
        var url = URLComponents(string: "https://www.youtube.com/watch")
        url?.queryItems = [URLQueryItem(name: "v", value: video.key)]
        return url?.url
    }

    func play(_ item: MediaItem, client: TMDBClient) {
        play(item, fetch: { try await client.fetch(.movieVideos(id: item.id)) })
    }

    func play(_ item: MediaItem, fetch: @escaping @MainActor () async throws -> VideosResponse) {
        if movieID == item.id, phase == .loading || video != nil { return }
        close()
        let token = playbackID
        movieID = item.id
        phase = .loading
        task = Task {
            do {
                let selected: Video?
                if let cached = cache[item.id] {
                    selected = cached
                } else {
                    let response = try await fetch()
                    guard token == playbackID, !Task.isCancelled else { return }
                    selected = Self.preferredTrailer(in: response.results)
                }
                guard token == playbackID, !Task.isCancelled else { return }
                guard let selected else {
                    phase = .unavailable
                    return
                }
                cache[item.id] = selected
                phase = .preparing(selected)
                // Uma falha no embed não pode deixar a capa carregando para sempre.
                try await Task.sleep(for: .seconds(15))
                guard token == playbackID, !Task.isCancelled else { return }
                if case .preparing = phase { phase = .failed }
            } catch {
                guard token == playbackID, !Task.isCancelled else { return }
                phase = .failed
            }
        }
    }

    static func preferredTrailer(in videos: [Video]) -> Video? {
        let trailers = videos.filter { $0.isYouTubeTrailer && !$0.key.isEmpty }
        return trailers.first(where: { $0.official == true }) ?? trailers.first
    }

    func playerReady(for video: Video, playbackID: UUID) {
        guard playbackID == self.playbackID, case .preparing(video) = phase else { return }
        phase = .ready(video)
        task?.cancel()
    }

    func playerFailed(for video: Video, playbackID: UUID) {
        guard playbackID == self.playbackID, self.video == video else { return }
        phase = .failed
        task?.cancel()
    }

    func close() {
        task?.cancel()
        task = nil
        playbackID = UUID()
        movieID = nil
        phase = .idle
    }
}
