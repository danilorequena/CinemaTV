import Foundation
import CinemaTVCore

struct LibraryImportRequest: Identifiable {
    let id = UUID()
    let text: String
    var destination: LibraryImportDestination = .watched
}

/// The review owns selections, never persistent models. Nothing is saved while
/// OCR, catalog lookup, or a Siri confirmation is running.
struct LibraryImportReview {
    struct Row: Identifiable {
        let id = UUID()
        let match: LibraryImportMatch
        var selectedID: String?

        var selectedItem: MediaItem? {
            match.candidates.first { LibraryImportPresentation.identity($0) == selectedID }
        }
    }

    var rows: [Row]

    init(matches: [LibraryImportMatch]) {
        rows = matches.map { match in
            Row(
                match: match,
                selectedID: match.candidates.count == 1
                    ? match.candidates.first.map(LibraryImportPresentation.identity) : nil
            )
        }
    }

    var selectedItems: [MediaItem] {
        var seen = Set<String>()
        return rows.compactMap(\.selectedItem).filter {
            seen.insert(LibraryImportPresentation.identity($0)).inserted
        }
    }

    var omittedTitles: [String] {
        rows.filter { $0.selectedItem == nil }.map { $0.match.query.title }
    }
}

enum LibraryImportPresentation {
    static func identity(_ item: MediaItem) -> String {
        "\(item.mediaType.rawValue):\(item.id)"
    }

    static func label(_ item: MediaItem) -> String {
        let kind = item.mediaType == .movie
            ? String(localized: "Movie") : String(localized: "TV Show")
        return [item.title, item.releaseYear, kind].compactMap { $0 }.joined(separator: " · ")
    }

    static func destinationLabel(_ destination: LibraryImportDestination) -> String {
        switch destination {
        case .watchlist: String(localized: "Want to Watch")
        case .watched: String(localized: "Watched")
        }
    }

    static func summary(_ report: LibraryImportReport) -> String {
        String(localized: "Saved: \(report.added.count). Already in your library: \(report.unchanged.count). Skipped: \(report.skipped.count). Failed: \(report.failed.count).")
    }

    static func index(_ report: LibraryImportReport, destination: LibraryImportDestination) {
        for item in report.added {
            switch item.mediaType {
            case .movie:
                if destination == .watched {
                    SpotlightIndexer.deindex(movieID: item.id)
                } else {
                    SpotlightIndexer.index(MovieEntity(item: item))
                }
            case .tvShow: SpotlightIndexer.index(TVShowEntity(item: item))
            case .person: break
            }
        }
    }
}
