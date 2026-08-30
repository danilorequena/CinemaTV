//
//  VisualTextExtractorTests.swift
//  CinemaTVTests
//
//  Extração de termos de busca a partir do OCR de prints de streaming e
//  ranking dos resultados do Visual Intelligence por título.
//

import Foundation
import CoreGraphics
import Testing
import CinemaTVCore
@testable import CinemaTV

// MARK: - Extração de termos do OCR

@Suite("VisualTextExtractor search terms")
struct VisualTextExtractorTests {
    private func line(
        _ text: String,
        height: CGFloat = 0.05,
        width: CGFloat = 0.5,
        y: CGFloat = 0.5,
        confidence: Float = 0.9
    ) -> VisualTextExtractor.RecognizedLine {
        VisualTextExtractor.RecognizedLine(
            text: text,
            boundingBox: CGRect(x: 0.1, y: y, width: width, height: height),
            confidence: confidence
        )
    }

    @Test("Low-confidence lines are dropped")
    func dropsLowConfidence() {
        let terms = VisualTextExtractor.searchTerms(
            from: [line("Dune Part Two", confidence: 0.3)],
            excluding: []
        )
        #expect(terms.isEmpty)
    }

    @Test(
        "Streaming UI chrome is dropped",
        arguments: ["Play", "My List", "Continue Watching", "Assistir", "Minha Lista", "Continuar Assistindo"]
    )
    func dropsUIChrome(text: String) {
        #expect(VisualTextExtractor.searchTerms(from: [line(text)], excluding: []).isEmpty)
    }

    @Test(
        "Episode markers, times and rating badges are dropped",
        arguments: ["S1 E4", "Season 2", "Temporada 3", "2:15", "97%", "1h 45m", "TV-MA", "PG-13", "4K", "HD", "16+"]
    )
    func dropsJunk(text: String) {
        #expect(VisualTextExtractor.searchTerms(from: [line(text)], excluding: []).isEmpty)
    }

    @Test("The tallest text ranks first, regardless of input order")
    func ranksByProminence() {
        let terms = VisualTextExtractor.searchTerms(
            from: [
                line("More like this: Blade Runner", height: 0.02),
                line("Dune: Part Two", height: 0.08),
            ],
            excluding: []
        )
        #expect(terms.first == "Dune: Part Two")
    }

    @Test("Terms already covered by system labels are skipped (case/diacritic-insensitive)")
    func dedupesAgainstLabels() {
        let terms = VisualTextExtractor.searchTerms(
            from: [line("CIDADE DE DEUS"), line("Dune: Part Two", height: 0.02)],
            excluding: ["Cidade de Deus"]
        )
        #expect(terms == ["Dune: Part Two"])
    }

    @Test("Duplicate lines collapse to one term")
    func dedupesWithinLines() {
        let terms = VisualTextExtractor.searchTerms(
            from: [line("The Matrix"), line("THE MATRIX", height: 0.02)],
            excluding: []
        )
        #expect(terms == ["The Matrix"])
    }

    @Test("Output is capped at the limit")
    func capsAtLimit() {
        let lines = (1...6).map { line("Some Movie Title \($0)") }
        let terms = VisualTextExtractor.searchTerms(from: lines, excluding: [], limit: 3)
        #expect(terms.count == 3)
    }

    @Test("Whitespace is trimmed and collapsed")
    func normalizesWhitespace() {
        let terms = VisualTextExtractor.searchTerms(
            from: [line("  Dune:   Part  Two  ")],
            excluding: []
        )
        #expect(terms == ["Dune: Part Two"])
    }

    @Test("Empty input produces empty output")
    func emptyInput() {
        #expect(VisualTextExtractor.searchTerms(from: [], excluding: []).isEmpty)
    }
}

// MARK: - Ranking por título nos resultados

@Suite("VisualMediaResult title-preferring ranking")
struct VisualMediaResultRankingTests {
    private func item(id: Int, type: MediaItem.MediaType, title: String = "Item") -> MediaItem {
        MediaItem(
            id: id,
            title: title,
            overview: "",
            posterPath: nil,
            backdropPath: nil,
            voteAverage: 0,
            releaseDate: nil,
            mediaType: type
        )
    }

    @Test("Items whose title matches an OCR term float to the front")
    func matchingTitlesRankFirst() throws {
        let results = VisualMediaResult.results(
            from: [
                item(id: 1, type: .movie, title: "Blade Runner"),
                item(id: 2, type: .movie, title: "Dune: Part Two"),
            ],
            preferringTitlesMatching: ["Dune: Part Two"]
        )

        try #require(results.count == 2)
        guard case .movie(let first) = results[0] else {
            Issue.record("Expected .movie as first result")
            return
        }
        #expect(first.id == 2)
    }

    @Test("Matching is case- and diacritic-insensitive, both containment directions")
    func matchingIsLenient() throws {
        let results = VisualMediaResult.results(
            from: [
                item(id: 1, type: .movie, title: "Other Movie"),
                item(id: 2, type: .tvShow, title: "Cidade de Deus"),
            ],
            preferringTitlesMatching: ["CIDADE DE DEUS: Especial"]
        )

        try #require(results.count == 2)
        guard case .tvShow(let first) = results[0] else {
            Issue.record("Expected .tvShow as first result")
            return
        }
        #expect(first.id == 2)
    }

    @Test("Empty terms preserve the original order")
    func emptyTermsKeepOrder() throws {
        let results = VisualMediaResult.results(
            from: [
                item(id: 1, type: .movie, title: "First"),
                item(id: 2, type: .movie, title: "Second"),
            ],
            preferringTitlesMatching: []
        )

        try #require(results.count == 2)
        guard case .movie(let first) = results[0] else {
            Issue.record("Expected .movie as first result")
            return
        }
        #expect(first.id == 1)
    }

    @Test("Dedup and the 10-result cap still hold with ranking")
    func invariantsPreserved() {
        let items = (1...25).map {
            item(id: $0, type: .movie, title: "Movie \($0)")
        } + [item(id: 1, type: .movie, title: "Movie 1")]

        let results = VisualMediaResult.results(
            from: items,
            preferringTitlesMatching: ["Movie 20"]
        )
        #expect(results.count == 10)
    }
}
