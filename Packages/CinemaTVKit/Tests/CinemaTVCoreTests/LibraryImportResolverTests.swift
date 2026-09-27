import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct LibraryImportResolverTests {
    @Test func normalizesTitlePrioritizesExactMatchesAndDeduplicatesIdentity() async throws {
        let exactMovie = item(id: 1, title: "Amélie", type: .movie)
        let approximateMovie = item(id: 2, title: "The Fabulous Destiny of Amélie Poulain", type: .movie)
        let exactShow = item(id: 1, title: "Amelie", type: .tvShow)
        let resolver = LibraryImportResolver { query in
            #expect(query == "  AMELIE ")
            return [approximateMovie, exactMovie, exactMovie, exactShow]
        }

        let matches = try await resolver.resolve([LibraryImportTitle(title: "  AMELIE ")])

        let match = try #require(matches.first)
        #expect(match.errorMessage == nil)
        #expect(match.candidates == [exactMovie, exactShow, approximateMovie])
    }

    @Test func yearFiltersMismatchesWithoutCollapsingAmbiguousCandidates() async throws {
        let duneMovie = item(id: 11, title: "Dune", year: "1984", type: .movie)
        let duneShow = item(id: 12, title: "Dune", year: "1984", type: .tvShow)
        let remake = item(id: 13, title: "Dune", year: "2021", type: .movie)
        let resolver = LibraryImportResolver { _ in [remake, duneMovie, duneShow] }

        let matches = try await resolver.resolve([
            LibraryImportTitle(title: "Dune", year: "1984")
        ])

        #expect(matches.first?.candidates == [duneMovie, duneShow])
    }

    @Test func networkFailureStaysAttachedToItsQuery() async throws {
        let resolver = LibraryImportResolver { query in
            if query == "Broken" { throw TestFailure.transport }
            return [self.item(id: 4, title: query, type: .movie)]
        }

        let matches = try await resolver.resolve([
            LibraryImportTitle(title: "Broken"),
            LibraryImportTitle(title: "Working")
        ])

        #expect(matches.count == 2)
        #expect(matches[0].candidates.isEmpty)
        #expect(matches[0].errorMessage != nil)
        #expect(matches[1].candidates.map(\.title) == ["Working"])
    }

    @Test func rejectsMoreThanFiftyTitlesBeforeSearching() async throws {
        let resolver = LibraryImportResolver { _ in
            Issue.record("Search must not run")
            return []
        }

        await #expect(throws: LibraryImportError.tooManyTitles(count: 51, maximum: 50)) {
            try await resolver.resolve((1...51).map { LibraryImportTitle(title: "Title \($0)") })
        }
    }

    private func item(
        id: Int,
        title: String,
        year: String? = nil,
        type: MediaItem.MediaType
    ) -> MediaItem {
        MediaItem(
            id: id,
            title: title,
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: year.map { "\($0)-01-01" },
            mediaType: type
        )
    }
}

private enum TestFailure: Error {
    case transport
}
