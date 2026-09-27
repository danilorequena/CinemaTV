import CinemaTVCore
import Testing
@testable import CinemaTV

struct LibraryImportReviewTests {
    private func item(_ id: Int, type: MediaItem.MediaType = .movie) -> MediaItem {
        MediaItem(id: id, title: "Dune", overview: "", posterPath: nil,
                  backdropPath: nil, voteAverage: 0, releaseDate: "2021-10-22", mediaType: type)
    }

    @Test func ambiguousTitlesRequireSelectionAndCanBeSkipped() {
        let first = item(1)
        let second = item(2)
        var review = LibraryImportReview(matches: [
            LibraryImportMatch(query: .init(title: "Dune"), candidates: [first, second], errorMessage: nil)
        ])
        #expect(review.selectedItems.isEmpty)
        #expect(review.omittedTitles == ["Dune"])
        review.rows[0].selectedID = LibraryImportPresentation.identity(second)
        #expect(review.selectedItems == [second])
        review.rows[0].selectedID = nil
        #expect(review.selectedItems.isEmpty)
    }

    @Test func duplicateMatchesSaveOnceButMovieAndShowWithSameIDStayDistinct() {
        let movie = item(1)
        let show = item(1, type: .tvShow)
        let review = LibraryImportReview(matches: [
            LibraryImportMatch(query: .init(title: "Dune"), candidates: [movie], errorMessage: nil),
            LibraryImportMatch(query: .init(title: "Duna"), candidates: [movie], errorMessage: nil),
            LibraryImportMatch(query: .init(title: "Dune TV"), candidates: [show], errorMessage: nil)
        ])
        #expect(review.selectedItems == [movie, show])
    }

    @Test func failedLookupStaysVisibleAndCannotBeSelected() {
        let review = LibraryImportReview(matches: [
            LibraryImportMatch(query: .init(title: "Dune"), candidates: [], errorMessage: "Offline")
        ])
        #expect(review.rows.first?.match.errorMessage == "Offline")
        #expect(review.omittedTitles == ["Dune"])
        #expect(review.selectedItems.isEmpty)
    }
}
