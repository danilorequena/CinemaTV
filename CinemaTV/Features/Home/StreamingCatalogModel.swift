import Foundation
import CinemaTVCore

@MainActor
@Observable
final class StreamingCatalogModel {
    // Discover accepts page numbers up to 500 even when totalPages is higher.
    private static let maximumPage = 500

    private(set) var items: [MediaItem] = []
    private(set) var nextPage: Int?
    private(set) var errorMessage: String?
    private(set) var isLoadingMore = false
    @ObservationIgnored private var knownIDs: Set<Int> = []

    init(firstPageItems: [MediaItem], nextPage: Int?) {
        self.nextPage = nextPage
        items = firstPageItems.filter { knownIDs.insert($0.id).inserted }
    }

    func loadMore(client: TMDBClient, query: StreamingAvailabilityQuery) async {
        guard errorMessage == nil else { return }
        await fetchMore(client: client, query: query)
    }

    func retry(client: TMDBClient, query: StreamingAvailabilityQuery) async {
        guard errorMessage != nil else { return }
        await fetchMore(client: client, query: query)
    }

    private func fetchMore(client: TMDBClient, query: StreamingAvailabilityQuery) async {
        guard !Task.isCancelled, !isLoadingMore, nextPage != nil else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }

        do {
            while let page = nextPage {
                guard !Task.isCancelled else { return }
                let response: PagedResponse<MediaItem> = try await client.fetch(
                    query.discoverEndpoint,
                    page: page,
                    parameters: query.parameters
                )
                guard !Task.isCancelled else { return }
                guard response.page == page else {
                    throw TMDBError.invalidResponse(statusCode: nil)
                }

                nextPage = response.hasMorePages && page < Self.maximumPage ? page + 1 : nil
                let newItems = response.results.filter { knownIDs.insert($0.id).inserted }
                if !newItems.isEmpty {
                    items.append(contentsOf: newItems)
                    break
                }
            }
            // Keep the failed state until the retry completes so it can resume after cancellation.
            errorMessage = nil
        } catch {
            guard !Task.isCancelled else { return }
            errorMessage = error.localizedDescription
        }
    }
}
