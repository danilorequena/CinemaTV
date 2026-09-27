import AppIntents
import CinemaTVCore
import Foundation
import SwiftUI
import UniformTypeIdentifiers

enum LibraryImportDestinationValue: String, AppEnum {
    case watchlist
    case watched

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Library Destination"
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .watchlist: "Want to Watch",
        .watched: "Watched"
    ]

    var destination: LibraryImportDestination {
        switch self {
        case .watchlist: .watchlist
        case .watched: .watched
        }
    }
}

struct ImportTitlesIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Movies and Shows"
    static let description = IntentDescription("Adds several movies and TV shows from a spoken or written list. Reviews the matches before saving to your watchlist or watched history.")
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Dependency private var router: AppRouter

    @Parameter(title: "Titles", requestValueDialog: "Which movies and shows?", inputConnectionBehavior: .connectToPreviousIntentResult)
    var titles: String

    @Parameter(title: "Add As", requestValueDialog: "Have you watched these, or do you want to watch them?")
    var destination: LibraryImportDestinationValue

    static var parameterSummary: some ParameterSummary {
        Summary("Add \(\.$titles) as \(\.$destination)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        let queries = try await LibraryImportExtractor().titles(from: titles)
        let completion = try await LibraryImportIntentFlow.run(queries, destination: destination.destination, intent: self, router: router)
        return .result(dialog: "\(completion.summary)", view: LibraryImportResultView(completion: completion))
    }
}

struct ImportScreenshotsIntent: AppIntent {
    static let title: LocalizedStringResource = "Add Movies and Shows from Screenshots"
    static let description = IntentDescription("Reads titles from up to 10 images and reviews the movies and TV shows before adding them. Use images from Photos or the input of a sharing shortcut.")
    static var supportedModes: IntentModes { .foreground(.dynamic) }

    @Dependency private var router: AppRouter

    @Parameter(title: "Screenshots", supportedContentTypes: [.image], inputConnectionBehavior: .connectToPreviousIntentResult)
    var screenshots: [IntentFile]

    @Parameter(title: "Add As", requestValueDialog: "Have you watched these, or do you want to watch them?")
    var destination: LibraryImportDestinationValue

    static var parameterSummary: some ParameterSummary {
        Summary("Add contents of \(\.$screenshots) as \(\.$destination)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ShowsSnippetView {
        // Validate the count before materializing the images' data.
        guard screenshots.count <= 10 else { throw LibraryImportInputError.tooManyImages }
        for (index, file) in screenshots.enumerated() {
            try Task.checkCancellation()
            if let url = file.fileURL,
               let byteCount = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               byteCount > LibraryImportExtractor.maximumImageByteCount {
                throw LibraryImportExtractor.Error.imageTooLarge(index: index + 1)
            }
        }
        let queries = try await LibraryImportExtractor().titles(fromImages: screenshots.map(\.data))
        let completion = try await LibraryImportIntentFlow.run(queries, destination: destination.destination, intent: self, router: router)
        return .result(dialog: "\(completion.summary)", view: LibraryImportResultView(completion: completion))
    }
}

enum LibraryImportInputError: LocalizedError {
    case tooManyImages
    case noSelection

    var errorDescription: String? {
        switch self {
        case .tooManyImages: String(localized: "Choose up to 10 screenshots at a time.")
        case .noSelection: String(localized: "No titles were selected. Nothing was added to your library.")
        }
    }
}

struct LibraryImportCompletion {
    let report: LibraryImportReport
    let omittedTitles: [String]
    var lookupFailures: [String] = []
    var reviewRequested = false

    var summary: String {
        if reviewRequested {
            return String(localized: "Review this larger list in CinemaTV before saving. Nothing has been added yet.")
        }
        var result = LibraryImportPresentation.summary(report)
        if !omittedTitles.isEmpty {
            result += " " + String(localized: "Not selected or not found: \(omittedTitles.joined(separator: ", ")).")
        }
        if !lookupFailures.isEmpty {
            result += " " + String(localized: "Search failed: \(lookupFailures.joined(separator: "; ")).")
        }
        return result
    }
}

@MainActor
enum LibraryImportIntentFlow {
    static func run<Intent: AppIntent>(
        _ titles: [LibraryImportTitle],
        destination: LibraryImportDestination,
        intent: Intent,
        router: AppRouter
    ) async throws -> LibraryImportCompletion {
        // Keep a long catalog lookup and a 50-row confirmation out of Siri's
        // compact surface. Pass only extracted titles, never temporary images.
        if titles.count > 10 {
            try await intent.continueInForeground("Review this larger list in CinemaTV before saving.", alwaysConfirm: false)
            let text = titles.map { title in
                title.title + (title.year.map { " (\($0))" } ?? "")
            }.joined(separator: "\n")
            router.presentLibraryImport(text: text, destination: destination)
            return LibraryImportCompletion(report: .init(), omittedTitles: [], reviewRequested: true)
        }
        let client = IntentSupport.makeTMDBClient()
        let matches = try await LibraryImportResolver(client: client).resolve(titles)
        var review = LibraryImportReview(matches: matches)
        for index in review.rows.indices where review.rows[index].match.candidates.count > 1 {
            try Task.checkCancellation()
            let match = review.rows[index].match
            let choice = try await intent.requestChoice(
                between: choices(for: match),
                dialog: "Which result matches \(match.query.title)?"
            )
            // IntentChoiceOption is not Sendable. Recreate the value options
            // after the request; do not retain and reuse the transferred array.
            if let selected = choices(for: match).firstIndex(of: choice),
               selected < match.candidates.count {
                review.rows[index].selectedID = LibraryImportPresentation.identity(match.candidates[selected])
            }
        }
        let items = review.selectedItems
        guard !items.isEmpty else {
            // Include failed lookup messages so a network problem is not reported as “not found”.
            if let message = matches.compactMap(\.errorMessage).first {
                throw LibraryImportLookupError(message: message)
            }
            throw LibraryImportInputError.noSelection
        }
        let destinationName = LibraryImportPresentation.destinationLabel(destination)
        let lookupFailures = matches.compactMap { match in
            match.errorMessage.map { "\(match.query.title): \($0)" }
        }
        let labels = items.map(LibraryImportPresentation.label)
        let includesWatchedShows = destination == .watched && items.contains { $0.mediaType == .tvShow }
        var confirmation = String(localized: "Add these titles as \(destinationName): \(labels.joined(separator: "; "))?")
        if includesWatchedShows {
            confirmation += " " + String(localized: "For TV shows, all aired episodes in regular seasons will be marked as watched.")
        }
        if !review.omittedTitles.isEmpty {
            confirmation += " " + String(localized: "Not selected or not found: \(review.omittedTitles.joined(separator: ", ")).")
        }
        if !lookupFailures.isEmpty {
            confirmation += " " + String(localized: "Search failed: \(lookupFailures.joined(separator: "; ")).")
        }
        try await intent.requestConfirmation(
            actionName: .add,
            dialog: "\(confirmation)",
            snippetIntent: LibraryImportPreviewSnippetIntent(
                titles: labels,
                destination: destinationName,
                omitted: review.omittedTitles + lookupFailures,
                includesWatchedShows: includesWatchedShows
            )
        )
        try Task.checkCancellation()
        let report = try await LibraryImportWriter(container: AppContainer.shared, client: client)
            .save(items, destination: destination)
        LibraryImportPresentation.index(report, destination: destination)
        return LibraryImportCompletion(report: report, omittedTitles: review.omittedTitles, lookupFailures: lookupFailures)
    }

    private nonisolated static func choices(for match: LibraryImportMatch) -> sending [IntentChoiceOption] {
        match.candidates.enumerated().map { offset, item in
            IntentChoiceOption(title: "\(offset + 1). \(LibraryImportPresentation.label(item))")
        } + [IntentChoiceOption(title: "Skip This Title")]
    }
}

struct LibraryImportLookupError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

/// Serializable snapshot of the reviewed batch. Siri may render it repeatedly;
/// it never runs OCR, searches again, or saves anything.
struct LibraryImportPreviewSnippetIntent: SnippetIntent {
    static let title: LocalizedStringResource = "Review Library Import"

    @Parameter(title: "Titles") var titles: [String]
    @Parameter(title: "Destination") var destination: String
    @Parameter(title: "Not Selected") var omitted: [String]
    @Parameter(title: "Includes Watched Shows") var includesWatchedShows: Bool

    init() {}
    init(titles: [String], destination: String, omitted: [String], includesWatchedShows: Bool) {
        self.titles = titles
        self.destination = destination
        self.omitted = omitted
        self.includesWatchedShows = includesWatchedShows
    }

    @MainActor
    func perform() async throws -> some IntentResult & ShowsSnippetView {
        .result(view: VStack(alignment: .leading, spacing: 8) {
            Text("Add as \(destination)").font(.headline)
            Text(titles.joined(separator: "\n")).font(.subheadline)
            if includesWatchedShows {
                Text("For TV shows, all aired episodes in regular seasons will be marked as watched.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if !omitted.isEmpty {
                Text("Not selected or not found: \(omitted.joined(separator: ", ")).")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }.padding())
    }
}

struct LibraryImportResultView: View {
    let completion: LibraryImportCompletion

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(completion.reviewRequested ? "Review Library Import" : "Import Results", systemImage: "books.vertical").font(.headline)
            Text(completion.summary).font(.subheadline)
            ForEach(completion.report.failed + completion.report.skipped, id: \.item) { problem in
                Text("\(problem.item.title): \(problem.message)")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}
