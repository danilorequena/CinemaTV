//
//  LibraryImportExtractor.swift
//  CinemaTV
//
//  Extracts movie and TV-show titles without resolving catalog identities.
//  Natural-language input uses the app's one-shot agent bridge; explicit
//  lists and any model failure use a conservative deterministic parser.
//

import CinemaTVCore
import CoreGraphics
import Foundation
import FoundationModels
import ImageIO
import Vision

@Generable
struct LibraryImportGeneratedResult: Sendable {
    // Allow one sentinel item beyond the public limit so the extractor can
    // report overflow rather than having guided generation silently truncate.
    @Guide(description: "Every movie or TV show title explicitly present in the input, in source order", .maximumCount(51))
    var titles: [LibraryImportGeneratedTitle]
}

@Generable
struct LibraryImportGeneratedTitle: Sendable {
    @Guide(description: "The exact movie or TV show title as written or spoken in the input; never infer or invent a title")
    var title: String

    @Guide(description: "A four-digit release year only when it appears with this title in the input; otherwise null")
    var year: String?
}

struct LibraryImportExtractor: Sendable {
    static let maximumImageCount = 10
    static let maximumTitleCount = 50
    static let maximumImageByteCount = 20 * 1_024 * 1_024
    static let maximumTextCharacterCount = 12_000

    private static let thumbnailMaximumPixelSize = 2_048
    private let agent: AgentEngine

    init() {
        agent = AgentEngine()
    }

    func titles(from text: String) async throws -> [LibraryImportTitle] {
        try Task.checkCancellation()

        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { throw Error.noTitles }
        guard source.count <= Self.maximumTextCharacterCount else { throw Error.textTooLong }

        if Self.hasExplicitSeparators(source) {
            return try Self.fallbackTitles(from: source)
        }

        do {
            let generated = try await agent.respond(
                to: Self.extractionPrompt(for: source),
                generating: LibraryImportGeneratedResult.self,
                instructions: Self.extractionInstructions,
                task: AgentTask(complexity: .light, allowsPrivateCloud: false)
            )
            try Task.checkCancellation()

            let grounded = try Self.groundedTitles(generated, in: source)
            if !grounded.isEmpty {
                return grounded
            }
        } catch let extractionError as Error {
            throw extractionError
        } catch {
            if Task.isCancelled { throw CancellationError() }
        }

        try Task.checkCancellation()
        return try Self.fallbackTitles(from: source)
    }

    func titles(fromImages images: [Data]) async throws -> [LibraryImportTitle] {
        try Task.checkCancellation()
        guard !images.isEmpty else { throw Error.noImages }
        guard images.count <= Self.maximumImageCount else { throw Error.tooManyImages }

        for (offset, image) in images.enumerated() {
            guard image.count <= Self.maximumImageByteCount else {
                throw Error.imageTooLarge(index: offset + 1)
            }
        }

        var extracted: [LibraryImportTitle] = []
        for (offset, image) in images.enumerated() {
            try Task.checkCancellation()
            let index = offset + 1
            let lines = try await Self.recognizedLines(in: image, imageIndex: index)
            let text = Self.filteredOCRText(from: lines)
            guard !text.isEmpty else { throw Error.noTitlesInImage(index: index) }

            let imageTitles = try await titles(from: text)
            extracted.append(contentsOf: imageTitles)
            extracted = Self.deduplicated(extracted)
            guard extracted.count <= Self.maximumTitleCount else { throw Error.tooManyTitles }
        }

        guard !extracted.isEmpty else { throw Error.noTitles }
        return extracted
    }
}

extension LibraryImportExtractor {
    enum Error: Swift.Error, Equatable, Sendable, LocalizedError {
        case noTitles
        case explicitListRequired
        case textTooLong
        case tooManyTitles
        case noImages
        case tooManyImages
        case imageTooLarge(index: Int)
        case unreadableImage(index: Int)
        case noTitlesInImage(index: Int)

        var errorDescription: String? {
            switch self {
            case .noTitles:
                String(localized: "Enter at least one title.")
            case .explicitListRequired:
                String(localized: "Put each title on a new line or separate titles with semicolons, then try again.")
            case .textTooLong:
                String(localized: "The list is too long. Keep it under 12,000 characters.")
            case .tooManyTitles:
                String(localized: "You can import up to 50 titles at a time.")
            case .noImages:
                String(localized: "Choose at least one screenshot.")
            case .tooManyImages:
                String(localized: "You can import up to 10 screenshots at a time.")
            case .imageTooLarge(let index):
                String(localized: "Screenshot \(index) is larger than 20 MB.")
            case .unreadableImage(let index):
                String(localized: "Screenshot \(index) could not be read.")
            case .noTitlesInImage(let index):
                String(localized: "No titles were found in screenshot \(index).")
            }
        }
    }

    struct OCRLine: Sendable {
        var text: String
        var boundingBox: CGRect
        var confidence: Float
    }
}

// MARK: - Explicit-list fallback

extension LibraryImportExtractor {
    static func fallbackTitles(from text: String) throws -> [LibraryImportTitle] {
        let source = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !source.isEmpty else { throw Error.noTitles }

        let rawParts = source.components(separatedBy: CharacterSet(charactersIn: "\n;"))
        let hasMultipleParts = rawParts.lazy.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count > 1
        if !hasMultipleParts, looksLikeNaturalLanguageRequest(source) {
            throw Error.explicitListRequired
        }

        let titles = rawParts.compactMap { raw -> LibraryImportTitle? in
            var line = normalizedWhitespace(raw)
            guard !line.isEmpty else { return nil }
            line = removingListMarker(from: line)
            line = removingWrappingQuotes(from: line)
            guard !line.isEmpty, !isListHeader(line, inMultiItemList: hasMultipleParts) else { return nil }

            let parsed = titleAndYear(from: line)
            guard !parsed.title.isEmpty else { return nil }
            return LibraryImportTitle(title: parsed.title, year: parsed.year)
        }

        let result = deduplicated(titles)
        guard !result.isEmpty else { throw Error.noTitles }
        guard result.count <= maximumTitleCount else { throw Error.tooManyTitles }
        return result
    }

    private static func hasExplicitSeparators(_ text: String) -> Bool {
        text.contains("\n") || text.contains(";")
    }

    private static func looksLikeNaturalLanguageRequest(_ text: String) -> Bool {
        let normalized = groundingText(text)
        let requestPhrases = [
            "add ", "include ", "import ", "put ", "save ", "watchlist",
            "my list", "i want", "i watched", "i have watched",
            "adicione ", "adicionar ", "inclua ", "importar ", "coloque ",
            "salve ", "minha lista", "quero ", "assisti ", "ja assisti ",
        ]
        return requestPhrases.contains { normalized.hasPrefix($0) || normalized.contains(" \($0)") }
    }

    private static func removingListMarker(from text: String) -> String {
        let patterns = [
            #"^\s*[-*•–—]\s+"#,
            #"^\s*\d{1,3}[.)]\s+"#,
            #"^\s*\[[ xX]?\]\s+"#,
        ]
        var value = text
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(value.startIndex..., in: value)
            value = regex.stringByReplacingMatches(in: value, range: range, withTemplate: "")
        }
        return normalizedWhitespace(value)
    }

    private static func removingWrappingQuotes(from text: String) -> String {
        let quotePairs: [(Character, Character)] = [("\"", "\""), ("'", "'"), ("“", "”"), ("‘", "’")]
        guard text.count >= 2, let first = text.first, let last = text.last,
              quotePairs.contains(where: { $0.0 == first && $0.1 == last }) else {
            return text
        }
        return normalizedWhitespace(String(text.dropFirst().dropLast()))
    }

    private static func isListHeader(_ text: String, inMultiItemList: Bool) -> Bool {
        guard inMultiItemList else { return false }
        let value = groundingText(text).trimmingCharacters(in: CharacterSet(charactersIn: ":"))
        return ["movies", "films", "tv shows", "shows", "my list", "filmes", "series", "minha lista"].contains(value)
    }

    private static func titleAndYear(from text: String) -> (title: String, year: String?) {
        let pattern = #"\s*\(((?:18|19|20|21)\d{2})\)\s*$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return (text, nil) }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let yearRange = Range(match.range(at: 1), in: text),
              let wholeRange = Range(match.range(at: 0), in: text) else {
            return (text, nil)
        }
        let title = normalizedWhitespace(String(text[..<wholeRange.lowerBound]))
        return (title, String(text[yearRange]))
    }
}

// MARK: - Guided generation and grounding

extension LibraryImportExtractor {
    static func groundedTitles(
        _ generated: LibraryImportGeneratedResult,
        in source: String
    ) throws -> [LibraryImportTitle] {
        guard generated.titles.count <= maximumTitleCount else { throw Error.tooManyTitles }
        let groundedSource = groundingText(source)
        let titles = generated.titles.compactMap { candidate -> LibraryImportTitle? in
            let title = normalizedWhitespace(candidate.title)
            let groundedTitle = groundingText(title)
            guard !title.isEmpty, !groundedTitle.isEmpty else { return nil }

            let sourceContainsTitle = (" \(groundedSource) ").contains(" \(groundedTitle) ")
            guard sourceContainsTitle else { return nil }

            let year = candidate.year.flatMap { proposed -> String? in
                guard proposed.wholeMatch(of: #/(?:18|19|20|21)\d{2}/#) != nil,
                      (" \(groundedSource) ").contains(" \(groundedTitle) \(proposed) ") else { return nil }
                return proposed
            }
            return LibraryImportTitle(title: title, year: year)
        }

        let result = deduplicated(titles)
        guard result.count <= maximumTitleCount else { throw Error.tooManyTitles }
        return result
    }

    private static let extractionInstructions = """
    Extract only movie and TV show titles explicitly present in the person's input. Preserve source order and title spelling. Keep words such as "and", "e", and commas when they are part of a title. Never infer a title from context, translate a title, choose a catalog match, or add a release year that is absent from the input.
    """

    private static func extractionPrompt(for source: String) -> String {
        """
        Extract the movie and TV show titles from the input between the markers.
        <input>
        \(source)
        </input>
        """
    }
}

// MARK: - Screenshot OCR

extension LibraryImportExtractor {
    static func filteredOCRText(from lines: [OCRLine]) -> String {
        let candidates = lines
            .filter { $0.confidence >= 0.35 }
            .map { OCRLine(text: normalizedWhitespace($0.text), boundingBox: $0.boundingBox, confidence: $0.confidence) }
            .filter { !$0.text.isEmpty && !isOCRInterfaceText($0.text) }
            .sorted { lhs, rhs in
                if abs(lhs.boundingBox.midY - rhs.boundingBox.midY) > 0.02 {
                    return lhs.boundingBox.midY > rhs.boundingBox.midY
                }
                return lhs.boundingBox.minX < rhs.boundingBox.minX
            }

        var filtered: [OCRLine] = []
        for line in candidates {
            if isFourDigitYear(line.text), let previous = filtered.last,
               shouldAttach(yearLine: line, to: previous) {
                filtered[filtered.count - 1].text += " (\(line.text))"
                continue
            }
            filtered.append(line)
        }
        return filtered.map(\.text).joined(separator: "\n")
    }

    private static func recognizedLines(in data: Data, imageIndex: Int) async throws -> [OCRLine] {
        guard !data.isEmpty,
              let source = CGImageSourceCreateWithData(
                data as CFData,
                [kCGImageSourceShouldCache: false] as CFDictionary
              ),
              CGImageSourceGetCount(source) > 0 else {
            throw Error.unreadableImage(index: imageIndex)
        }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: thumbnailMaximumPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ]
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            throw Error.unreadableImage(index: imageIndex)
        }

        try Task.checkCancellation()
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.automaticallyDetectsLanguage = true
        request.recognitionLanguages = [
            Locale.Language(identifier: "en-US"),
            Locale.Language(identifier: "pt-BR"),
        ]
        request.usesLanguageCorrection = true

        do {
            let observations = try await request.perform(on: image)
            try Task.checkCancellation()
            return observations.compactMap { observation in
                guard let candidate = observation.topCandidates(1).first else { return nil }
                return OCRLine(
                    text: candidate.string,
                    boundingBox: observation.boundingBox.cgRect,
                    confidence: candidate.confidence
                )
            }
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw Error.unreadableImage(index: imageIndex)
        }
    }

    private static func isOCRInterfaceText(_ text: String) -> Bool {
        let normalized = groundingText(text)
        let labels: Set<String> = [
            "play", "resume", "watch", "watch now", "my list", "continue watching",
            "episodes", "trailers", "more info", "more like this", "download", "downloads",
            "share", "skip intro", "search", "home", "movies", "films", "tv shows",
            "assistir", "reproduzir", "retomar", "minha lista", "continuar assistindo",
            "episodios", "trailers e mais", "mais informacoes", "mais como este", "baixar",
            "downloads", "compartilhar", "pular abertura", "buscar", "inicio", "filmes", "series",
        ]
        if labels.contains(normalized) { return true }

        let patterns = [
            #"(?i)^S\d+\s*[:.,·-]?\s*E\d+$"#,
            #"(?i)^(season|temporada)\s+\d+$"#,
            #"(?i)^(tv-?(ma|14|pg|y7?|g)|pg-?13|nc-?17|hd|4k|uhd|hdr|cc|sdh|[lr]|\d{1,2}\+)$"#,
            #"^\d{1,2}:\d{2}$"#,
            #"^\d{1,3}%$"#,
            #"(?i)^\d+h(?:\s*\d+m)?$"#,
            #"(?i)^(https?://|www\.).+"#,
        ]
        return patterns.contains { pattern in
            guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
            return regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
        }
    }

    private static func isFourDigitYear(_ text: String) -> Bool {
        text.wholeMatch(of: #/(?:18|19|20|21)\d{2}/#) != nil
    }

    private static func shouldAttach(yearLine: OCRLine, to titleLine: OCRLine) -> Bool {
        guard !isFourDigitYear(titleLine.text),
              yearLine.boundingBox.height <= titleLine.boundingBox.height * 0.75 else {
            return false
        }
        let verticalGap = titleLine.boundingBox.minY - yearLine.boundingBox.maxY
        let isImmediatelyBelow = verticalGap >= -0.01 && verticalGap <= 0.04
        let isLeftAligned = abs(titleLine.boundingBox.minX - yearLine.boundingBox.minX) <= 0.08
        return isImmediatelyBelow && isLeftAligned
    }
}

// MARK: - Shared normalization

extension LibraryImportExtractor {
    private static func normalizedWhitespace(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacing(#/\s+/#) { _ in " " }
    }

    private static func groundingText(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        let scalars = folded.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(String(scalar)) : " "
        }
        return normalizedWhitespace(String(scalars))
    }

    private static func deduplicated(_ titles: [LibraryImportTitle]) -> [LibraryImportTitle] {
        var seen = Set<String>()
        return titles.filter { title in
            let key = "\(groundingText(title.title))|\(title.year ?? "")"
            return seen.insert(key).inserted
        }
    }
}
