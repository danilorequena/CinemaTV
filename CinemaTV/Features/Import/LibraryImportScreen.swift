//
//  LibraryImportScreen.swift
//  CinemaTV
//
//  Bounded text and screenshot import with a review step before persistence.
//

import CinemaTVCore
import Observation
import PhotosUI
import SwiftData
import SwiftUI

struct LibraryImportScreen: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.tmdbClient) private var client

    @State private var model: LibraryImportScreenModel

    init(initialText: String = "", initialDestination: LibraryImportDestination = .watched) {
        self.initialText = initialText
        _model = State(initialValue: LibraryImportScreenModel(initialText: initialText, destination: initialDestination))
    }

    let initialText: String

    var body: some View {
        NavigationStack {
            Form {
                if let completion = model.completion {
                    resultSections(completion)
                } else {
                    sourceSection
                    destinationSection
                    progressSection
                    analysisErrorSection
                    reviewSections
                    saveSection
                }
            }
            .navigationTitle("Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if model.completion == nil {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { dismiss() }
                            .disabled(model.isSaving)
                    }
                } else {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
            }
            .disabled(model.isSaving)
            .overlay {
                if model.isSaving {
                    savingOverlay
                }
            }
        }
        .interactiveDismissDisabled(model.isSaving)
        .task {
            model.analyzeInitialTextIfNeeded(client: client)
        }
        .onChange(of: model.text) {
            model.sourceDidChange()
        }
        .onChange(of: model.photoItems) {
            model.sourceDidChange()
        }
        .onDisappear {
            model.cancelTasks()
        }
    }

    private var sourceSection: some View {
        Section {
            TextEditor(text: Binding(
                get: { model.text },
                set: { model.text = $0 }
            ))
            .frame(minHeight: 120)
            .accessibilityLabel("Movie and TV show titles")

            Button("Review Titles", systemImage: "text.magnifyingglass") {
                model.analyzeText(client: client)
            }
            .disabled(model.isAnalyzing || model.trimmedText.isEmpty)

            PhotosPicker(
                selection: Binding(
                    get: { model.photoItems },
                    set: { model.photoItems = $0 }
                ),
                maxSelectionCount: LibraryImportExtractor.maximumImageCount,
                matching: .images
            ) {
                Label("Choose Screenshots", systemImage: "photo.on.rectangle.angled")
            }
            .disabled(model.isAnalyzing)

            if !model.photoItems.isEmpty {
                LabeledContent("Screenshots", value: "\(model.photoItems.count)")
                Button("Review Screenshots", systemImage: "viewfinder") {
                    model.analyzePhotos(client: client)
                }
                .disabled(model.isAnalyzing)
            }
        } header: {
            Text("Titles or Screenshots")
        } footer: {
            Text("Enter up to 50 titles, one per line, or choose up to 10 screenshots. CinemaTV reviews catalog matches before saving anything.")
        }
    }

    private var destinationSection: some View {
        Section {
            Picker(
                "Add As",
                selection: Binding(
                    get: { model.destination },
                    set: { model.destination = $0 }
                )
            ) {
                Text("Watched").tag(LibraryImportDestination.watched)
                Text("Want to Watch").tag(LibraryImportDestination.watchlist)
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Library destination")
        } header: {
            Text("Destination")
        } footer: {
            if model.destination == .watched {
                Text("Movies are marked watched. For TV shows, all aired episodes in regular seasons are marked watched; specials and future episodes are excluded.")
            } else {
                Text("Movies are added to Want to Watch. TV shows are added without changing episode progress.")
            }
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if model.isAnalyzing {
            Section {
                HStack(spacing: 12) {
                    ProgressView()
                    Text(model.analysisUsesPhotos ? "Reading screenshots and finding matches…" : "Finding catalog matches…")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(model.analysisUsesPhotos ? "Reading screenshots and finding matches" : "Finding catalog matches")
            }
        }
    }

    @ViewBuilder
    private var analysisErrorSection: some View {
        if let message = model.analysisErrorMessage {
            Section("Couldn't Review Import") {
                Label(message, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
                Button("Try Again", systemImage: "arrow.clockwise") {
                    model.retryAnalysis(client: client)
                }
                .disabled(model.isAnalyzing || !model.canRetry)
            }
        }
    }

    @ViewBuilder
    private var reviewSections: some View {
        if let review = model.review {
            Section {
                ForEach(review.rows) { row in
                    matchRow(row)
                }
            } header: {
                Text("Review Matches")
            } footer: {
                if review.omittedTitles.isEmpty {
                    Text("All matched titles are selected.")
                } else {
                    Text("\(review.omittedTitles.count) title(s) will be omitted unless you select a match.")
                }
            }

            if let message = model.saveErrorMessage {
                Section("Couldn't Finish Saving") {
                    Label(message, systemImage: "exclamationmark.circle")
                        .foregroundStyle(.red)
                    Text("Your reviewed selections are still here. Try saving again.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func matchRow(_ row: LibraryImportReview.Row) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(queryLabel(for: row))
                .font(.headline)

            if let message = row.match.errorMessage {
                Label(message, systemImage: "wifi.exclamationmark")
                    .font(.subheadline)
                    .foregroundStyle(.red)
            } else if row.match.candidates.isEmpty {
                Label("No catalog matches found", systemImage: "magnifyingglass")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else {
                Picker(
                    "Match",
                    selection: selectionBinding(for: row.id)
                ) {
                    Text("Skip This Title").tag(nil as String?)
                    ForEach(row.match.candidates.map(LibraryImportCandidateChoice.init)) { choice in
                        Text(LibraryImportPresentation.label(choice.item))
                            .tag(Optional(choice.id))
                    }
                }
                .accessibilityLabel("Match for \(row.match.query.title)")

                if row.match.candidates.count == 1 {
                    Text("Unique matches are selected automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if row.selectedID == nil {
                    Text("Choose the correct result or skip this title.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var saveSection: some View {
        if let review = model.review {
            Section {
                Button {
                    model.save(
                        client: client,
                        container: modelContext.container
                    )
                } label: {
                    Label(
                        "Save \(review.selectedItems.count) Title(s)",
                        systemImage: model.destination == .watched ? "checkmark.circle.fill" : "bookmark.fill"
                    )
                    .frame(maxWidth: .infinity)
                }
                .disabled(review.selectedItems.isEmpty || model.isSaving)
                .accessibilityHint("Saves only the selected catalog matches")
            }
        }
    }

    @ViewBuilder
    private func resultSections(_ completion: LibraryImportCompletion) -> some View {
        Section {
            LibraryImportResultView(completion: completion)
        }

        if !completion.omittedTitles.isEmpty {
            Section("Not Added") {
                LabeledContent("Omitted titles", value: "\(completion.omittedTitles.count)")
                Text(completion.omittedTitles.joined(separator: "\n"))
                    .foregroundStyle(.secondary)
            }
        }

        if !completion.lookupFailures.isEmpty {
            Section("Search Failures") {
                ForEach(completion.lookupFailures, id: \.self) { failure in
                    Label(failure, systemImage: "wifi.exclamationmark")
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var savingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Saving your library…")
                .font(.headline)
        }
        .padding(24)
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Saving your library")
    }

    private func queryLabel(for row: LibraryImportReview.Row) -> String {
        [row.match.query.title, row.match.query.year]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func selectionBinding(for rowID: UUID) -> Binding<String?> {
        Binding(
            get: {
                model.review?.rows.first(where: { $0.id == rowID })?.selectedID
            },
            set: { selectedID in
                model.select(selectedID, for: rowID)
            }
        )
    }
}

private struct LibraryImportCandidateChoice: Identifiable {
    let item: MediaItem

    var id: String {
        LibraryImportPresentation.identity(item)
    }
}

@MainActor
@Observable
private final class LibraryImportScreenModel {
    enum SourceKind {
        case text
        case photos
    }

    var text: String
    var photoItems: [PhotosPickerItem] = []
    var destination: LibraryImportDestination = .watched
    var review: LibraryImportReview?
    var completion: LibraryImportCompletion?
    var analysisErrorMessage: String?
    var saveErrorMessage: String?
    var isAnalyzing = false
    var isSaving = false
    var analysisUsesPhotos = false

    @ObservationIgnored private var analysisTask: Task<Void, Never>?
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private var analysisGeneration = 0
    @ObservationIgnored private var lastSourceKind: SourceKind?
    @ObservationIgnored private var didAnalyzeInitialText = false

    init(initialText: String, destination: LibraryImportDestination) {
        text = initialText
        self.destination = destination
    }

    var trimmedText: String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var canRetry: Bool {
        switch lastSourceKind {
        case .text: !trimmedText.isEmpty
        case .photos: !photoItems.isEmpty
        case nil: false
        }
    }

    func analyzeInitialTextIfNeeded(client: TMDBClient) {
        guard !didAnalyzeInitialText, !trimmedText.isEmpty else { return }
        didAnalyzeInitialText = true
        analyzeText(client: client)
    }

    func analyzeText(client: TMDBClient) {
        guard !trimmedText.isEmpty else { return }
        lastSourceKind = .text
        beginAnalysis(source: .text(trimmedText), client: client)
    }

    func analyzePhotos(client: TMDBClient) {
        guard !photoItems.isEmpty else { return }
        lastSourceKind = .photos
        beginAnalysis(source: .photos(photoItems), client: client)
    }

    func retryAnalysis(client: TMDBClient) {
        switch lastSourceKind {
        case .text: analyzeText(client: client)
        case .photos: analyzePhotos(client: client)
        case nil: break
        }
    }

    func sourceDidChange() {
        guard !isSaving else { return }
        invalidateAnalysis()
        review = nil
        completion = nil
        analysisErrorMessage = nil
        saveErrorMessage = nil
    }

    func select(_ selectedID: String?, for rowID: UUID) {
        guard let index = review?.rows.firstIndex(where: { $0.id == rowID }) else { return }
        review?.rows[index].selectedID = selectedID
        saveErrorMessage = nil
    }

    func save(client: TMDBClient, container: ModelContainer) {
        guard !isSaving, let review else { return }
        let items = review.selectedItems
        guard !items.isEmpty else { return }

        saveTask?.cancel()
        isSaving = true
        saveErrorMessage = nil
        let omittedTitles = review.omittedTitles
        let lookupFailures = review.rows.compactMap { row in
            row.match.errorMessage.map { "\(row.match.query.title): \($0)" }
        }
        let selectedDestination = destination

        saveTask = Task { [weak self] in
            guard let self else { return }
            do {
                let report = try await LibraryImportWriter(container: container, client: client)
                    .save(items, destination: selectedDestination)
                LibraryImportPresentation.index(report, destination: selectedDestination)
                completion = LibraryImportCompletion(
                    report: report,
                    omittedTitles: omittedTitles,
                    lookupFailures: lookupFailures
                )
            } catch is CancellationError {
                // Dismissal or source replacement owns cancellation.
            } catch {
                saveErrorMessage = error.localizedDescription
            }
            isSaving = false
            saveTask = nil
        }
    }

    func cancelTasks() {
        invalidateAnalysis()
        saveTask?.cancel()
        saveTask = nil
        isSaving = false
    }

    private func beginAnalysis(source: AnalysisSource, client: TMDBClient) {
        invalidateAnalysis()
        analysisGeneration += 1
        let generation = analysisGeneration

        review = nil
        completion = nil
        analysisErrorMessage = nil
        saveErrorMessage = nil
        isAnalyzing = true
        analysisUsesPhotos = source.usesPhotos

        analysisTask = Task { [weak self] in
            guard let self else { return }
            do {
                let titles: [LibraryImportTitle]
                switch source {
                case .text(let sourceText):
                    titles = try await LibraryImportExtractor().titles(from: sourceText)
                case .photos(let items):
                    let imageData = try await loadImageData(from: items)
                    titles = try await LibraryImportExtractor().titles(fromImages: imageData)
                }

                try Task.checkCancellation()
                let matches = try await LibraryImportResolver(client: client).resolve(titles)
                try Task.checkCancellation()
                guard analysisGeneration == generation else { return }
                review = LibraryImportReview(matches: matches)
            } catch is CancellationError {
                // A new source or dismissal invalidated this result.
            } catch {
                guard analysisGeneration == generation else { return }
                analysisErrorMessage = error.localizedDescription
            }

            guard analysisGeneration == generation else { return }
            isAnalyzing = false
            analysisTask = nil
        }
    }

    private func loadImageData(from items: [PhotosPickerItem]) async throws -> [Data] {
        guard items.count <= LibraryImportExtractor.maximumImageCount else {
            throw LibraryImportExtractor.Error.tooManyImages
        }

        var result: [Data] = []
        result.reserveCapacity(items.count)
        for (offset, item) in items.enumerated() {
            try Task.checkCancellation()
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw LibraryImportExtractor.Error.unreadableImage(index: offset + 1)
            }
            guard data.count <= LibraryImportExtractor.maximumImageByteCount else {
                throw LibraryImportExtractor.Error.imageTooLarge(index: offset + 1)
            }
            result.append(data)
        }
        return result
    }

    private func invalidateAnalysis() {
        analysisTask?.cancel()
        analysisTask = nil
        analysisGeneration += 1
        isAnalyzing = false
    }
}

private enum AnalysisSource {
    case text(String)
    case photos([PhotosPickerItem])

    var usesPhotos: Bool {
        switch self {
        case .text: false
        case .photos: true
        }
    }
}
