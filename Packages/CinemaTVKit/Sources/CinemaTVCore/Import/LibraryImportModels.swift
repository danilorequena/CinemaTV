import Foundation

public struct LibraryImportTitle: Hashable, Sendable {
    public let title: String
    public let year: String?

    public init(title: String, year: String? = nil) {
        self.title = title
        self.year = year
    }
}

public enum LibraryImportDestination: String, Codable, Sendable {
    case watchlist
    case watched
}

public struct LibraryImportMatch: Hashable, Sendable {
    public let query: LibraryImportTitle
    public let candidates: [MediaItem]
    public let errorMessage: String?

    public init(
        query: LibraryImportTitle,
        candidates: [MediaItem],
        errorMessage: String? = nil
    ) {
        self.query = query
        self.candidates = candidates
        self.errorMessage = errorMessage
    }
}

public struct LibraryImportProblem: Hashable, Sendable {
    public let item: MediaItem
    public let message: String

    public init(item: MediaItem, message: String) {
        self.item = item
        self.message = message
    }
}

public struct LibraryImportReport: Hashable, Sendable {
    public let added: [MediaItem]
    public let unchanged: [MediaItem]
    public let skipped: [LibraryImportProblem]
    public let failed: [LibraryImportProblem]

    public init(
        added: [MediaItem] = [],
        unchanged: [MediaItem] = [],
        skipped: [LibraryImportProblem] = [],
        failed: [LibraryImportProblem] = []
    ) {
        self.added = added
        self.unchanged = unchanged
        self.skipped = skipped
        self.failed = failed
    }
}

public enum LibraryImportError: Error, Equatable, Sendable, LocalizedError {
    case tooManyTitles(count: Int, maximum: Int)

    public var errorDescription: String? {
        switch self {
        case .tooManyTitles(let count, let maximum):
            String(
                localized: "Import has \(count) titles; the limit is \(maximum).",
                bundle: .module
            )
        }
    }
}
