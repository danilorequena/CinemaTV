import Foundation
import Observation
import CinemaTVCore
import CinemaTVDesignSystem

@MainActor
@Observable
final class DiscoverModel {
    struct Decision {
        let item: MediaItem
        let index: Int
    }

    private(set) var deck: [MediaItem] = []
    private(set) var history: [Decision] = []
    private(set) var state: LoadState<Bool> = .idle
    private(set) var isLoadingMore = false
    private(set) var paginationError: String?
    var actionError: String?
    var visibleItemID: MediaItem.ID?

    private let defaults: UserDefaults
    private static let previousOpeningKey = "discover.previousOpeningMovieID"
    private var hasStartedSession = false
    private var page = 0
    private var totalPages = Int.max
    private var decidedIDs: Set<Int> = []
    @ObservationIgnored private var loadingMoreTask: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Previews mantêm a ordem fornecida e não fazem requisições.
    init(previewDeck: [MediaItem]) {
        defaults = .standard
        deck = previewDeck
        visibleItemID = previewDeck.first?.id
        hasStartedSession = true
        page = 1
        totalPages = 1
        state = .loaded(true)
    }

    var canUndo: Bool { !history.isEmpty }

    var visibleItem: MediaItem? {
        deck.first(where: { $0.id == visibleItemID }) ?? deck.first
    }

    private var needsMoreMovies: Bool {
        guard page < totalPages else { return false }
        let index = deck.firstIndex(where: { $0.id == visibleItemID }) ?? 0
        return deck.count - index <= 4
    }

    /// Uma instância representa uma visita ao feed. Voltar do detalhe ou
    /// fechar um trailer não inicia outra sessão nem muda a posição.
    func loadInitial(client: TMDBClient) async {
        guard !Task.isCancelled else { return }
        switch state {
        case .loaded, .loading: return
        case .idle, .failed: break
        }
        state = .loading
        do {
            let response: PagedResponse<MediaItem> = try await client.fetch(.discoverMovies, page: 1)
            guard !Task.isCancelled else {
                state = .idle
                return
            }
            page = 1
            totalPages = response.totalPages
            deck = orderedNewMovies(response.results)
            visibleItemID = deck.first?.id
            state = .loaded(true)
        } catch {
            state = Task.isCancelled ? .idle : .failed(error.localizedDescription)
        }
    }

    /// Os gatilhos da view podem mudar durante a requisição. A tarefa é
    /// da sessão, compartilhada pelos chamadores, e só a saída a cancela.
    func loadMoreIfNeeded(client: TMDBClient) async {
        if let loadingMoreTask {
            await loadingMoreTask.value
        }
        guard !Task.isCancelled, case .loaded = state,
              needsMoreMovies, paginationError == nil else { return }
        // Outro chamador pode ter iniciado o próximo lote após o await.
        guard loadingMoreTask == nil else { return }
        isLoadingMore = true
        let task = Task {
            defer {
                isLoadingMore = false
                loadingMoreTask = nil
            }
            do {
                // Páginas vazias ou compostas apenas de duplicatas não
                // encerram o feed enquanto a API ainda tiver páginas.
                while needsMoreMovies, !Task.isCancelled {
                    let nextPage = page + 1
                    let response: PagedResponse<MediaItem> = try await client.fetch(.discoverMovies, page: nextPage)
                    guard !Task.isCancelled else { return }
                    page = nextPage
                    totalPages = response.totalPages
                    deck.append(contentsOf: orderedNewMovies(response.results))
                    if visibleItemID == nil {
                        visibleItemID = deck.first?.id
                    }
                }
            } catch {
                guard !Task.isCancelled else { return }
                paginationError = error.localizedDescription
            }
        }
        loadingMoreTask = task
        await task.value
    }

    func cancelLoading() {
        loadingMoreTask?.cancel()
    }

    /// Só embaralha o lote novo: páginas já vistas mantêm sua posição.
    private func orderedNewMovies(_ items: [MediaItem]) -> [MediaItem] {
        var knownIDs = decidedIDs.union(deck.map(\.id))
        var movies = items.filter {
            $0.mediaType == .movie && knownIDs.insert($0.id).inserted
        }.shuffled()

        if !hasStartedSession, let first = movies.first {
            let previousID = defaults.object(forKey: Self.previousOpeningKey) as? Int
            if movies.count > 1, first.id == previousID {
                movies.swapAt(0, Int.random(in: 1..<movies.count))
            }
            defaults.set(movies[0].id, forKey: Self.previousOpeningKey)
            hasStartedSession = true
        }
        return movies
    }

    @discardableResult
    func decide(_ item: MediaItem, wanted: Bool, store: WatchlistStore) -> Bool {
        guard let index = deck.firstIndex(where: { $0.id == item.id }) else { return false }
        actionError = nil
        if wanted {
            guard !store.isWatched(movieID: item.id) else { return false }
            do {
                try store.addToWatchlist(item)
                SpotlightIndexer.index(item)
                return true
            } catch {
                actionError = String(localized: "Couldn't save this movie. Please try again.")
                return false
            }
        }
        if visibleItemID == item.id {
            visibleItemID = deck.dropFirst(index + 1).first?.id
                ?? deck.prefix(index).last?.id
        }
        decidedIDs.insert(item.id)
        deck.remove(at: index)
        history.append(Decision(item: item, index: index))
        return true
    }

    func undoSkip() {
        guard let last = history.popLast() else { return }
        decidedIDs.remove(last.item.id)
        deck.insert(last.item, at: min(last.index, deck.count))
        visibleItemID = last.item.id
    }

    func retry(client: TMDBClient) async {
        if case .loaded = state {
            paginationError = nil
            await loadMoreIfNeeded(client: client)
        } else {
            await loadInitial(client: client)
        }
    }
}
