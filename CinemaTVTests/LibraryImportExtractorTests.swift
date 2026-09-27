//
//  LibraryImportExtractorTests.swift
//  CinemaTVTests
//

import CoreGraphics
import Foundation
import Testing
import UIKit
import CinemaTVCore
@testable import CinemaTV

@Suite("Library import extraction")
struct LibraryImportExtractorTests {
    @Test("Explicit lists remove bullets and extract trailing years")
    func parsesExplicitLists() throws {
        let titles = try LibraryImportExtractor.fallbackTitles(from: """
        1. Dune: Part Two (2024)
        • Cidade de Deus (2002); - Up
        """)

        #expect(titles.count == 3)
        #expect(titles[0].title == "Dune: Part Two")
        #expect(titles[0].year == "2024")
        #expect(titles[1].title == "Cidade de Deus")
        #expect(titles[1].year == "2002")
        #expect(titles[2].title == "Up")
        #expect(titles[2].year == nil)
    }

    @Test("Fallback keeps commas and conjunctions inside a title")
    func preservesTitlePunctuationAndConjunctions() throws {
        let titles = try LibraryImportExtractor.fallbackTitles(from: "Once Upon a Time in America, Extended Cut\nMe and Earl and the Dying Girl")

        #expect(titles.count == 2)
        #expect(titles[0].title == "Once Upon a Time in America, Extended Cut")
        #expect(titles[1].title == "Me and Earl and the Dying Girl")
    }

    @Test("Fallback accepts short and numeric titles")
    func preservesShortAndNumericTitles() throws {
        let titles = try LibraryImportExtractor.fallbackTitles(from: "1917; It; Up")

        #expect(titles.map(\.title) == ["1917", "It", "Up"])
    }

    @Test("Natural speech asks for an explicit list when AI cannot help")
    func rejectsNaturalSpeechAsOneFallbackTitle() {
        #expect(throws: LibraryImportExtractor.Error.explicitListRequired) {
            try LibraryImportExtractor.fallbackTitles(from: "Add Dune and Arrival to my watchlist")
        }
    }

    @Test("Grounding rejects invented titles and unsupported years")
    func groundsGeneratedTitlesInSource() throws {
        let generated = LibraryImportGeneratedResult(titles: [
            LibraryImportGeneratedTitle(title: "Dune: Part Two", year: "2024"),
            LibraryImportGeneratedTitle(title: "Arrival", year: "2016"),
            LibraryImportGeneratedTitle(title: "Invented Movie", year: nil),
        ])

        let titles = try LibraryImportExtractor.groundedTitles(
            generated,
            in: "Please add Dune: Part Two (2024) and Arrival."
        )

        #expect(titles.count == 2)
        #expect(titles[0].title == "Dune: Part Two")
        #expect(titles[0].year == "2024")
        #expect(titles[1].title == "Arrival")
        #expect(titles[1].year == nil)
    }

    @Test("Grounding matches token boundaries for short titles")
    func groundingRejectsShortSubstringMatches() throws {
        let generated = LibraryImportGeneratedResult(titles: [
            LibraryImportGeneratedTitle(title: "Up", year: nil),
        ])

        let titles = try LibraryImportExtractor.groundedTitles(generated, in: "Setup complete")

        #expect(titles.isEmpty)
    }

    @Test("Guided generation reports a fifty-one-title overflow")
    func rejectsGeneratedOverflowBeforeGrounding() {
        let generated = LibraryImportGeneratedResult(
            titles: Array(
                repeating: LibraryImportGeneratedTitle(title: "Dune", year: nil),
                count: 51
            )
        )

        #expect(throws: LibraryImportExtractor.Error.tooManyTitles) {
            try LibraryImportExtractor.groundedTitles(generated, in: "Dune")
        }
    }

    @Test("OCR filtering removes interface labels but preserves short and numeric titles")
    func filtersOCRInterfaceText() {
        let lines = [
            LibraryImportExtractor.OCRLine(text: "Continue Watching", boundingBox: CGRect(x: 0, y: 0.9, width: 1, height: 0.05), confidence: 0.99),
            LibraryImportExtractor.OCRLine(text: "1917", boundingBox: CGRect(x: 0, y: 0.7, width: 1, height: 0.05), confidence: 0.95),
            LibraryImportExtractor.OCRLine(text: "It", boundingBox: CGRect(x: 0, y: 0.5, width: 1, height: 0.05), confidence: 0.95),
            LibraryImportExtractor.OCRLine(text: "Up", boundingBox: CGRect(x: 0, y: 0.3, width: 1, height: 0.05), confidence: 0.95),
            LibraryImportExtractor.OCRLine(text: "TV-MA", boundingBox: CGRect(x: 0, y: 0.1, width: 1, height: 0.05), confidence: 0.95),
        ]

        #expect(LibraryImportExtractor.filteredOCRText(from: lines) == "1917\nIt\nUp")
    }

    @Test("A smaller adjacent OCR year is attached to its title")
    func attachesVisuallyAssociatedOCRYear() {
        let lines = [
            LibraryImportExtractor.OCRLine(text: "Dune", boundingBox: CGRect(x: 0.1, y: 0.60, width: 0.5, height: 0.08), confidence: 0.98),
            LibraryImportExtractor.OCRLine(text: "2021", boundingBox: CGRect(x: 0.1, y: 0.55, width: 0.15, height: 0.03), confidence: 0.96),
            LibraryImportExtractor.OCRLine(text: "1917", boundingBox: CGRect(x: 0.1, y: 0.40, width: 0.5, height: 0.08), confidence: 0.98),
        ]

        #expect(LibraryImportExtractor.filteredOCRText(from: lines) == "Dune (2021)\n1917")
    }

    @Test("A rendered screenshot is decoded and OCRed as a title list")
    @MainActor
    func extractsTitlesFromRenderedScreenshot() async throws {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1_200, height: 900), format: format)
        let imageData = renderer.pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1_200, height: 900))

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 64, weight: .semibold),
                .foregroundColor: UIColor.black,
            ]
            for (index, text) in ["My List", "Dune (2021)", "Arrival (2016)", "1917"].enumerated() {
                text.draw(at: CGPoint(x: 100, y: 100 + (index * 175)), withAttributes: attributes)
            }
        }

        let titles = try await LibraryImportExtractor().titles(fromImages: [imageData])

        #expect(titles.count == 3)
        #expect(titles[0].title == "Dune")
        #expect(titles[0].year == "2021")
        #expect(titles[1].title == "Arrival")
        #expect(titles[1].year == "2016")
        #expect(titles[2].title == "1917")
        #expect(titles[2].year == nil)
    }

    @Test("OCR preserves remakes with the same title and different years")
    func preservesRepeatedTitleBeforeAssociatingYears() throws {
        let lines = [
            LibraryImportExtractor.OCRLine(text: "Dune", boundingBox: CGRect(x: 0.1, y: 0.80, width: 0.5, height: 0.08), confidence: 0.98),
            LibraryImportExtractor.OCRLine(text: "1984", boundingBox: CGRect(x: 0.1, y: 0.75, width: 0.15, height: 0.03), confidence: 0.96),
            LibraryImportExtractor.OCRLine(text: "Dune", boundingBox: CGRect(x: 0.1, y: 0.60, width: 0.5, height: 0.08), confidence: 0.98),
            LibraryImportExtractor.OCRLine(text: "2021", boundingBox: CGRect(x: 0.1, y: 0.55, width: 0.15, height: 0.03), confidence: 0.96),
        ]
        let text = LibraryImportExtractor.filteredOCRText(from: lines)
        let titles = try LibraryImportExtractor.fallbackTitles(from: text)
        #expect(titles == [LibraryImportTitle(title: "Dune", year: "1984"), LibraryImportTitle(title: "Dune", year: "2021")])
    }

    @Test("More than ten screenshots fails before image decoding")
    func rejectsTooManyImages() async {
        let extractor = LibraryImportExtractor()

        await #expect(throws: LibraryImportExtractor.Error.tooManyImages) {
            try await extractor.titles(fromImages: Array(repeating: Data(), count: 11))
        }
    }

    @Test("An oversized screenshot fails before image decoding")
    func rejectsOversizedImage() async {
        let extractor = LibraryImportExtractor()
        let data = Data(count: LibraryImportExtractor.maximumImageByteCount + 1)

        await #expect(throws: LibraryImportExtractor.Error.imageTooLarge(index: 1)) {
            try await extractor.titles(fromImages: [data])
        }
    }

    @Test("Invalid image data reports the failing screenshot")
    func rejectsInvalidImageData() async {
        let extractor = LibraryImportExtractor()

        await #expect(throws: LibraryImportExtractor.Error.unreadableImage(index: 1)) {
            try await extractor.titles(fromImages: [Data("not an image".utf8)])
        }
    }

    @Test("More than fifty parsed titles reports the limit")
    func rejectsTooManyTitles() async {
        let extractor = LibraryImportExtractor()
        let text = (1...51).map { "Movie \($0)" }.joined(separator: ";")

        await #expect(throws: LibraryImportExtractor.Error.tooManyTitles) {
            try await extractor.titles(from: text)
        }
    }

    @Test("Oversized text is rejected before model generation")
    func rejectsOversizedText() async {
        let extractor = LibraryImportExtractor()
        let text = String(repeating: "Dune ", count: 2_401)

        await #expect(throws: LibraryImportExtractor.Error.textTooLong) {
            try await extractor.titles(from: text)
        }
    }

    @Test("Cancellation propagates before parsing")
    func propagatesCancellation() async {
        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await LibraryImportExtractor().titles(from: "Dune; Arrival")
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
