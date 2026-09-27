import Foundation
import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct BoxStoreTests {
    private let container: ModelContainer
    private let store: BoxStore

    init() throws {
        container = try ModelContainerFactory.makeInMemory()
        store = BoxStore(container: container)
    }

    private var sample: BoxDraft {
        BoxDraft(
            title: "Noites no espaço",
            description: "Uma viagem pelo cinema.",
            coverStyle: .cosmic,
            authorID: "author-1",
            authorName: "Ana",
            contents: [
                BoxContent(kind: .movie, title: "Interstellar", mediaID: 157336, posterPath: "/space.jpg"),
                BoxContent(kind: .review, title: "Minha impressão", text: "Uma história sobre tempo.", rating: 5, authorID: "author-1", authorName: "Ana")
            ]
        )
    }

    @Test func savedBoxPersistsInAReopenedDiskStore() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "boxes-test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Boxes.store")
        let expected = sample
        do {
            let diskContainer = try diskContainer(at: url)
            let diskStore = BoxStore(context: ModelContext(diskContainer))
            try diskStore.save(expected)
        }

        let reopenedContainer = try diskContainer(at: url)
        let reopenedContext = ModelContext(reopenedContainer)
        let saved = try #require(reopenedContext.fetch(FetchDescriptor<PersonalBox>()).first)
        #expect(try BoxStore(context: reopenedContext).draft(for: saved) == expected)
        #expect(saved.title == "Noites no espaço")
        #expect(saved.createdAt != nil)
        #expect(saved.updatedAt != nil)
    }

    @Test func savingAnEditedDraftUpdatesOneRecord() throws {
        var draft = sample
        let original = try store.save(draft)
        let createdAt = original.createdAt
        draft.title = "Novas viagens"
        draft.contents.removeLast()
        let updated = try store.save(draft)

        #expect(updated.persistentModelID == original.persistentModelID)
        #expect(updated.createdAt == createdAt)
        #expect(try store.draft(for: updated).title == "Novas viagens")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 1)
    }

    @Test func editionIsAnIndependentSnapshotAfterEditingSource() throws {
        var draft = sample
        let record = try store.save(draft)
        let edition = try store.makeEdition(from: record)
        let encodedEdition = try JSONEncoder().encode(edition)
        draft.title = "Outro título"
        draft.contents[1].text = "Outra opinião"
        try store.save(draft)

        #expect(edition.box.title == "Noites no espaço")
        #expect(edition.box.contents[1].text == "Uma história sobre tempo.")
        #expect(try JSONDecoder().decode(BoxEdition.self, from: encodedEdition) == edition)
        #expect(try store.makeEdition(from: record).id != edition.id)
    }

    @Test func importingOwnEditionUsesASeparateReadOnlyRecord() throws {
        let source = try store.save(sample)
        let edition = try store.makeEdition(from: source)
        let imported = try store.importOriginal(edition)
        var importedDraft = try store.draft(for: imported)
        importedDraft.title = "Tentativa de edição"

        #expect(imported.id != source.id)
        #expect(importedDraft.id == imported.id)
        #expect(imported.sourceEditionID == edition.id)
        #expect(imported.isOriginal == true)
        #expect(throws: BoxStoreError.originalIsReadOnly) { try store.save(importedDraft) }
        #expect(try store.draft(for: source).title == "Noites no espaço")
        #expect(try store.draft(for: imported).title == "Noites no espaço")
    }

    @Test func reimportingAnEditionDoesNotDuplicateOrOverwriteIt() throws {
        let edition = BoxEdition(box: sample)
        let original = try store.importOriginal(edition)
        var changedEdition = edition
        changedEdition.box.title = "Different payload with same edition ID"
        let again = try store.importOriginal(changedEdition)

        #expect(again.persistentModelID == original.persistentModelID)
        #expect(try store.draft(for: again).title == "Noites no espaço")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 1)
    }

    @Test func importedOriginalRemainsReadOnlyInAnotherContext() throws {
        let record = try store.importOriginal(BoxEdition(box: sample))
        let context = ModelContext(container)
        let otherStore = BoxStore(context: context)
        let reopened = try #require(context.fetch(FetchDescriptor<PersonalBox>()).first)
        var draft = try otherStore.draft(for: reopened)
        draft.description = "Changed"

        #expect(record.id == draft.id)
        #expect(throws: BoxStoreError.originalIsReadOnly) { try otherStore.save(draft) }
    }

    @Test func adaptationCreatesNewIdentitiesAndPreservesNoteAttribution() throws {
        let edition = BoxEdition(box: sample)
        let adapted = BoxStore.inspiredDraft(from: edition, authorID: "author-2", authorName: "Bruno")

        #expect(adapted.id != edition.box.id)
        #expect(Set(adapted.contents.map(\.id)).isDisjoint(with: edition.box.contents.map(\.id)))
        #expect(adapted.authorID == "author-2")
        #expect(adapted.authorName == "Bruno")
        #expect(adapted.inspiredByName == "Ana")
        #expect(adapted.inspiredByEditionID == edition.id)
        #expect(adapted.contents[1].authorID == "author-1")
        #expect(adapted.contents[1].authorName == "Ana")
        #expect(adapted.contents[1].text == "Uma história sobre tempo.")
        let saved = try store.save(adapted)
        #expect(saved.isOriginal == false)
    }

    @Test func deletingRemovesPersonalAndImportedBoxes() throws {
        let own = try store.save(sample)
        let original = try store.importOriginal(BoxEdition(box: sample))
        try store.delete(own)
        try store.delete(original)

        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 0)
    }

    @Test func missingAndCorruptPayloadsAreReported() throws {
        for payload in [nil, Data("not JSON".utf8)] as [Data?] {
            let record = PersonalBox(id: UUID(), title: "Existing box", payload: payload)
            container.mainContext.insert(record)
            try container.mainContext.save()
            #expect(throws: BoxStoreError.corruptedPayload) { try store.draft(for: record) }
            #expect(throws: BoxStoreError.corruptedPayload) { try store.makeEdition(from: record) }
        }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 2)
    }

    @Test func invalidDraftsAreRejectedWithoutSavingRows() throws {
        var emptyTitle = sample
        emptyTitle.title = " \n\t "
        var longTitle = sample
        longTitle.title = String(repeating: "a", count: 121)
        var longDescription = sample
        longDescription.description = String(repeating: "a", count: 2_001)
        var emptyContents = sample
        emptyContents.contents = []
        var tooManyContents = sample
        tooManyContents.contents = (0..<201).map { BoxContent(kind: .movie, title: "Movie \($0)") }
        var emptyContentTitle = sample
        emptyContentTitle.contents[0].title = "\n "
        var longReview = sample
        longReview.contents[1].text = String(repeating: "a", count: 10_001)

        for (draft, error) in [
            (emptyTitle, BoxStoreError.emptyTitle),
            (longTitle, .titleTooLong),
            (longDescription, .descriptionTooLong),
            (emptyContents, .emptyContents),
            (tooManyContents, .tooManyContents),
            (emptyContentTitle, .emptyContentTitle),
            (longReview, .reviewTooLong)
        ] {
            #expect(throws: error) { try store.save(draft) }
        }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 0)
    }

    @Test func validationAcceptsExactLimits() throws {
        var draft = sample
        draft.title = String(repeating: "a", count: 120)
        draft.description = String(repeating: "a", count: 2_000)
        draft.contents = (0..<200).map { BoxContent(kind: .movie, title: "Movie \($0)") }
        draft.contents[0] = BoxContent(kind: .review, title: "Review", text: String(repeating: "a", count: 10_000))

        #expect(try store.draft(for: store.save(draft)) == draft)
    }

    @Test func invalidEditPreservesPreviouslySavedPayload() throws {
        var draft = sample
        let record = try store.save(draft)
        draft.contents = []
        #expect(throws: BoxStoreError.emptyContents) { try store.save(draft) }
        #expect(try store.draft(for: record).contents.count == 2)
    }

    @Test func invalidRatingsAreRejectedBeforeEncodingOrSaving() throws {
        for rating in [0.0, 0.4, 5.1, Double.infinity, Double.nan] {
            var draft = sample
            draft.contents[1].rating = rating
            #expect(throws: BoxStoreError.invalidRating) { try store.save(draft) }
        }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 0)

        for rating in [nil, 0.5, 5.0] as [Double?] {
            var draft = sample
            draft.contents[1].rating = rating
            let record = try store.save(draft)
            #expect(try store.draft(for: record).contents[1].rating == rating)
        }
    }

    @Test func savingOverCorruptionDoesNotSilentlyReplaceData() throws {
        let draft = sample
        let damagedPayload = Data("damaged data".utf8)
        let damaged = PersonalBox(id: draft.id, title: draft.title, payload: damagedPayload)
        container.mainContext.insert(damaged)
        try container.mainContext.save()

        #expect(throws: BoxStoreError.corruptedPayload) { try store.save(draft) }
        #expect(damaged.payload == damagedPayload)
    }

    @Test func reimportDoesNotSilentlyHideAnExistingCorruptOriginal() throws {
        let edition = BoxEdition(box: sample)
        let record = try store.importOriginal(edition)
        record.payload = Data("damaged data".utf8)
        try container.mainContext.save()

        #expect(throws: BoxStoreError.corruptedPayload) { try store.importOriginal(edition) }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 1)
    }

    @Test func importValidatesEditionBeforeWriting() throws {
        var invalid = sample
        invalid.contents = []
        #expect(throws: BoxStoreError.emptyContents) { try store.importOriginal(BoxEdition(box: invalid)) }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 0)
    }

    @Test func duplicateContentIdentitiesAreRejectedWithoutWriting() throws {
        var draft = sample
        draft.contents[1].id = draft.contents[0].id

        #expect(throws: BoxStoreError.duplicateContents) { try store.save(draft) }
        #expect(throws: BoxStoreError.duplicateContents) { try store.importOriginal(BoxEdition(box: draft)) }
        #expect(try container.mainContext.fetchCount(FetchDescriptor<PersonalBox>()) == 0)
    }

    @Test func failedBoxUpdateRestoresValuesAndKeepsUnrelatedPendingChanges() throws {
        try withReadOnlyStore { (context: ModelContext, readOnlyStore: BoxStore) throws -> Void in
            let record = try #require(context.fetch(FetchDescriptor<PersonalBox>()).first)
            let profile = try #require(context.fetch(FetchDescriptor<BoxAuthorProfile>()).first)
            profile.displayName = "An unrelated pending change"
            let before = try readOnlyStore.draft(for: record)
            let updatedAt = record.updatedAt
            var changed = before
            changed.title = "Failed update"

            #expect(throws: (any Error).self) { try readOnlyStore.save(changed) }
            #expect(try readOnlyStore.draft(for: record) == before)
            #expect(record.title == "Noites no espaço")
            #expect(record.updatedAt == updatedAt)
            #expect(profile.displayName == "An unrelated pending change")
        }
    }

    @Test func failedInsertDoesNotLeaveABoxPendingToSave() throws {
        try withReadOnlyStore { (context: ModelContext, readOnlyStore: BoxStore) throws -> Void in
            let undoManager = UndoManager()
            context.undoManager = undoManager
            let profile = try #require(context.fetch(FetchDescriptor<BoxAuthorProfile>()).first)
            profile.displayName = "An unrelated pending change"
            let existingIDs = try context.fetch(FetchDescriptor<PersonalBox>()).map(\.persistentModelID)
            #expect(throws: (any Error).self) { try readOnlyStore.save(sample) }
            try verifyInsertionRecovery(in: context, model: PersonalBox.self, expectedIDs: existingIDs)
            #expect(profile.displayName == "An unrelated pending change")
            #expect(context.undoManager === undoManager)
        }
    }

    @Test func failedImportDoesNotLeaveAnOriginalPendingToSave() throws {
        try withReadOnlyStore { (context: ModelContext, readOnlyStore: BoxStore) throws -> Void in
            let existingIDs = try context.fetch(FetchDescriptor<PersonalBox>()).map(\.persistentModelID)
            #expect(throws: (any Error).self) { try readOnlyStore.importOriginal(BoxEdition(box: sample)) }
            try verifyInsertionRecovery(in: context, model: PersonalBox.self, expectedIDs: existingIDs)
        }
    }

    @Test func failedDisplayNameUpdateRestoresName() throws {
        try withReadOnlyStore { (context: ModelContext, readOnlyStore: BoxStore) throws -> Void in
            #expect(throws: (any Error).self) { try readOnlyStore.saveDisplayName("Failed name") }
            #expect(try readOnlyStore.profile().displayName == "Ana")
            #expect(context.deletedModelsArray.isEmpty)
        }
    }

    @Test func failedProfileCreationDoesNotLeaveAProfilePendingToSave() throws {
        try withReadOnlyStore(includeProfile: false) { (context: ModelContext, readOnlyStore: BoxStore) throws -> Void in
            #expect(throws: (any Error).self) { try readOnlyStore.profile() }
            try verifyInsertionRecovery(in: context, model: BoxAuthorProfile.self, expectedIDs: [])
        }
    }

    @Test func failedProfileIDRepairRestoresThePreviousValue() throws {
        try withReadOnlyStore { (context: ModelContext, readOnlyStore: BoxStore) throws -> Void in
            let profile = try #require(context.fetch(FetchDescriptor<BoxAuthorProfile>()).first)
            profile.id = nil

            #expect(throws: (any Error).self) { try readOnlyStore.profile() }
            #expect(profile.id == nil)
            #expect(profile.displayName == "Ana")
        }
    }

    @Test func failedDeleteKeepsTheRecordAndUnrelatedPendingChanges() throws {
        try withReadOnlyStore { (context: ModelContext, readOnlyStore: BoxStore) throws -> Void in
            let undoManager = UndoManager()
            context.undoManager = undoManager
            let record = try #require(context.fetch(FetchDescriptor<PersonalBox>()).first)
            let profile = try #require(context.fetch(FetchDescriptor<BoxAuthorProfile>()).first)
            profile.displayName = "An unrelated pending change"
            let identifier = record.persistentModelID

            #expect(throws: (any Error).self) { try readOnlyStore.delete(record) }
            #expect(context.deletedModelsArray.isEmpty)
            let remaining = try #require(context.fetch(FetchDescriptor<PersonalBox>()).first)
            #expect(remaining.persistentModelID == identifier)
            #expect(try readOnlyStore.draft(for: remaining).title == "Noites no espaço")
            #expect(profile.displayName == "An unrelated pending change")
            #expect(context.undoManager === undoManager)
        }
    }

    @Test func authorProfileIsCreatedOnceAndPersistsTrimmedName() throws {
        let first = try store.profile()
        let identifier = try #require(first.id)
        #expect(UUID(uuidString: identifier) != nil)
        #expect(first.createdAt != nil)
        try store.saveDisplayName("  Ana Lima \n")
        let reopenedStore = BoxStore(context: ModelContext(container))
        let again = try reopenedStore.profile()

        #expect(again.id == identifier)
        #expect(again.displayName == "Ana Lima")
        #expect(try container.mainContext.fetchCount(FetchDescriptor<BoxAuthorProfile>()) == 1)
    }

    @Test func invalidDisplayNamesDoNotReplaceSavedName() throws {
        try store.saveDisplayName("Ana")
        #expect(throws: BoxStoreError.emptyDisplayName) { try store.saveDisplayName(" \n ") }
        #expect(throws: BoxStoreError.displayNameTooLong) { try store.saveDisplayName(String(repeating: "a", count: 81)) }
        #expect(try store.profile().displayName == "Ana")
        try store.saveDisplayName(String(repeating: "a", count: 80))
        #expect(try store.profile().displayName?.count == 80)
    }

    private func diskContainer(at url: URL) throws -> ModelContainer {
        try ModelContainer(
            for: ModelContainerFactory.schema,
            configurations: [ModelConfiguration(schema: ModelContainerFactory.schema, url: url, cloudKitDatabase: .none)]
        )
    }

    private func verifyInsertionRecovery<Model: PersistentModel>(
        in context: ModelContext,
        model: Model.Type,
        expectedIDs: [PersistentIdentifier]
    ) throws {
        let descriptor = FetchDescriptor<Model>()
        let fetchedIDs = try context.fetch(descriptor).map(\.persistentModelID)
        let freshContext = ModelContext(context.container)
        freshContext.autosaveEnabled = false
        let freshIDs = try freshContext.fetch(descriptor).map(\.persistentModelID)

        #expect(context.insertedModelsArray.isEmpty)
        #expect(context.deletedModelsArray.isEmpty)
        #expect(fetchedIDs.count == expectedIDs.count)
        #expect(Set(fetchedIDs) == Set(expectedIDs))
        #expect(Set(freshIDs) == Set(expectedIDs))
    }

    private func withReadOnlyStore(
        includeProfile: Bool = true,
        _ operation: (ModelContext, BoxStore) throws -> Void
    ) throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "boxes-readonly-test-\(UUID())")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appending(path: "Boxes.store")
        do {
            let writableContainer = try diskContainer(at: url)
            let writableStore = BoxStore(context: ModelContext(writableContainer))
            try writableStore.save(sample)
            if includeProfile {
                try writableStore.saveDisplayName("Ana")
            }
        }
        let readOnlyContainer = try ModelContainer(
            for: ModelContainerFactory.schema,
            configurations: [ModelConfiguration(schema: ModelContainerFactory.schema, url: url, allowsSave: false, cloudKitDatabase: .none)]
        )
        let context = ModelContext(readOnlyContainer)
        context.autosaveEnabled = false
        try operation(context, BoxStore(context: context))
    }
}
