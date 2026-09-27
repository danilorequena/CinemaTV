# Bulk library import implementation plan

**Goal:** Add several movies and TV shows to CinemaTV from a spoken/written list or screenshots, using Siri and Shortcuts as the primary entry points.

**Design:** Two thin App Intents accept text or image files and feed a common extraction, catalog resolution, confirmation, and persistence pipeline. OCR stays on device. Foundation Models extracts titles from natural language without choosing catalog identities. Catalog candidates are reviewed before writing; unresolved titles and failures remain visible. Existing single-item intents and Visual Intelligence search remain compatible.

**Platform:** Existing iOS 27 / Swift 6 app, Vision, Foundation Models through AgentEngine, App Intents, CinemaTVCore, SwiftData. No new dependencies or service credentials.

## Behavior

- Accept a mixed list of movies and shows, up to 50 titles / 10 screenshots per invocation; report limits instead of silently dropping items.
- Choose Watchlist or Watched explicitly. For watched TV, mark aired regular episodes; exclude future episodes and specials, preserve existing progress and watched dates. This interpretation of “already watched” is displayed explicitly before saving.
- Extract names and optional years. Do not split movie titles at conjunctions blindly. OCR UI labels must not become saved records without catalog resolution and confirmation.
- Resolve movies and shows against TMDB. Deduplicate by media type + ID, keep ambiguous candidates for user choice, preserve per-title search failures.
- Present the actual resolved titles and destination before any write. Cancellation writes nothing. Saving is idempotent, does not regress watched state, and reports partial failures accurately.
- Image actions accept explicit image input in Shortcuts and image selection. Do not claim Siri can automatically read arbitrary third-party screenshots; document supported invocation routes.
- Add an in-app Import sheet in Library using the same service for text and PhotosPicker images, review/correction, and result counts.
- Preserve all unrelated working-tree changes; no commit or branch operations are part of this task.

## Work and interfaces

- [x] Domain: create `CinemaTVCore/Import/LibraryImportModels.swift`, `LibraryImportResolver.swift`, and `LibraryImportWriter.swift`, plus package tests. Public `LibraryImportTitle(title: String, year: String? = nil)`; `LibraryImportDestination` (`watchlist`, `watched`); `LibraryImportMatch` (`query`, `candidates: [MediaItem]`, `errorMessage: String?`); `LibraryImportResolver.resolve(_ titles: [LibraryImportTitle]) async throws -> [LibraryImportMatch]`; `LibraryImportWriter.save(_ items: [MediaItem], destination: LibraryImportDestination) async throws -> LibraryImportReport` on MainActor. Inject TMDB fetch closures for offline tests. Report successful, unchanged, skipped, and failed items separately. Tests cover duplicates, ambiguity/year filtering, transport failure, watched preservation, future episodes, and cancellation.
- [x] Extraction: create app `Features/Import/LibraryImportExtractor.swift` and tests. `LibraryImportExtractor.titles(from text: String) async throws -> [LibraryImportTitle]` and `titles(fromImages images: [Data]) async throws -> [LibraryImportTitle]`. Use AgentEngine with a light on-device task and guided generation, validate extracted strings are grounded in source; fallback to conservative explicit list parsing when models unavailable. Vision reads each image, with bounds on count/size and useful invalid/empty-image errors. No network or persistence here.
- [x] Integration: create `Intents/LibraryImportIntents.swift` and `Features/Import/LibraryImportScreen.swift`; add AppShortcuts phrases, Portuguese localization, Xcode source/test references, and Library entry point. Siri disambiguation/confirmation and app review use the common matches/writer. Do not write from snippets or extraction.
- [x] Verification: run focused package and app tests, simulator build, device SDK build for VisualIntelligence availability, review the final changes, and document a real-device Siri / Shortcuts / screenshots checklist.

## Progress

Research: existing single-item intents, on-device OCR, catalog search, and SwiftData stores are reusable. Current VisualMediaQuery is a read-only search limited to three OCR terms and ten results; it must remain read-only.

Implementation complete: domain models/resolution/writer, extraction, Siri actions with spoken confirmation, in-app review, localized phrases, and Visual Intelligence continuation. The writer intentionally performs a single save per item in a private context so existing UI state is not rolled back. Library sections now use episode progress, because imported watched dates may be unknown.

Verification: simulator build passed; 13 domain tests and 20 app tests passed. Review findings fixed: repeated OCR title/year association, spoken names in confirmation, unknown episode dates, unnecessary season fetches for watchlist, initial next-episode caches, and library classification with unknown watched dates. Large Siri batches (>10 titles) hand off to the app for review with destination preserved. Real-device Siri runtime remains a manual check.

Final validation: iPhone device SDK build also passed (`/private/tmp/cinematv-bulk-device-validation.log`), including VisualLibraryImportIntent.swift. Simulator launch and Library screenshot verified. Manual tap verification was blocked by the locked host Mac; no Siri runtime or device interaction is claimed. Domain test log: `/private/tmp/cinematv-bulk-domain-validation.log`.
