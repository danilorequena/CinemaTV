import Foundation

public struct LibraryImportResolver: Sendable {
    public static let maximumTitleCount = 50

    private let search: @Sendable (String) async throws -> [MediaItem]

    public init(client: TMDBClient) {
        self.init { query in
            let response: PagedResponse<MediaItem> = try await client.fetch(.multiSearch, query: query)
            return response.results
        }
    }

    init(search: @escaping @Sendable (String) async throws -> [MediaItem]) {
        self.search = search
    }

    public func resolve(_ titles: [LibraryImportTitle]) async throws -> [LibraryImportMatch] {
        guard titles.count <= Self.maximumTitleCount else {
            throw LibraryImportError.tooManyTitles(
                count: titles.count,
                maximum: Self.maximumTitleCount
            )
        }

        var matches: [LibraryImportMatch] = []
        matches.reserveCapacity(titles.count)

        for query in titles {
            try Task.checkCancellation()
            do {
                let results = try await search(query.title)
                try Task.checkCancellation()
                matches.append(LibraryImportMatch(
                    query: query,
                    candidates: candidates(from: results, for: query)
                ))
            } catch is CancellationError {
                throw CancellationError()
            } catch {
                matches.append(LibraryImportMatch(
                    query: query,
                    candidates: [],
                    errorMessage: error.localizedDescription
                ))
            }
        }
        return matches
    }

    private func candidates(
        from results: [MediaItem],
        for query: LibraryImportTitle
    ) -> [MediaItem] {
        let requestedYear = normalizedYear(query.year)
        var seen = Set<MediaIdentity>()
        let unique = results.filter { item in
            guard item.mediaType == .movie || item.mediaType == .tvShow else { return false }
            guard requestedYear == nil || item.releaseYear == requestedYear else { return false }
            return seen.insert(MediaIdentity(item)).inserted
        }

        let normalizedQuery = normalizedTitle(query.title)
        return unique.enumerated().sorted { lhs, rhs in
            let lhsIsExact = normalizedTitle(lhs.element.title) == normalizedQuery
            let rhsIsExact = normalizedTitle(rhs.element.title) == normalizedQuery
            if lhsIsExact != rhsIsExact { return lhsIsExact }
            return lhs.offset < rhs.offset
        }.map(\.element)
    }

    private func normalizedTitle(_ title: String) -> String {
        title
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private func normalizedYear(_ year: String?) -> String? {
        guard let year else { return nil }
        let digits = year.filter(\.isNumber)
        guard digits.count == 4 else { return nil }
        return digits
    }
}

private struct MediaIdentity: Hashable {
    let id: Int
    let type: MediaItem.MediaType

    init(_ item: MediaItem) {
        id = item.id
        type = item.mediaType
    }
}
