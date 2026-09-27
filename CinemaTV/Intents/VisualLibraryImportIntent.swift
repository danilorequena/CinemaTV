import AppIntents

#if canImport(VisualIntelligence)
import VisualIntelligence

/// The “more results” continuation from a user-selected screenshot region.
/// Search remains read-only; the app opens a review before any library change.
@AppIntent(schema: .visualIntelligence.semanticContentSearch)
struct ReviewVisualContentsIntent {
    var semanticContent: SemanticContentDescriptor

    @Dependency private var router: AppRouter

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let pixels = semanticContent.pixelBuffer else {
            router.presentLibraryImport()
            return .result(dialog: "Choose screenshots or enter the titles you want to import.")
        }
        let lines = await VisualTextRecognizer.recognizedLines(in: pixels)
        try Task.checkCancellation()
        // Preserve all lines here. List extraction has its own filtering and
        // limits; the search query's top-three ranking is unsuitable for a list.
        let text = LibraryImportExtractor.filteredOCRText(from: lines.map {
            LibraryImportExtractor.OCRLine(text: $0.text, boundingBox: $0.boundingBox, confidence: $0.confidence)
        })
        router.presentLibraryImport(text: text)
        return .result(dialog: "Review the titles in CinemaTV before adding them.")
    }
}
#endif
