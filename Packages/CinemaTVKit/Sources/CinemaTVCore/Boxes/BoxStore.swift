import Foundation
import SwiftData

public enum BoxStoreError: Error, LocalizedError, Equatable, Sendable {
    case emptyTitle
    case titleTooLong
    case descriptionTooLong
    case emptyContents
    case tooManyContents
    case emptyContentTitle
    case duplicateContents
    case reviewTooLong
    case invalidRating
    case corruptedPayload
    case originalIsReadOnly
    case emptyDisplayName
    case displayNameTooLong

    public var errorDescription: String? {
        switch self {
        case .emptyTitle: String(localized: "Give your box a title.", bundle: .module)
        case .titleTooLong: String(localized: "A box title can have up to 120 characters.", bundle: .module)
        case .descriptionTooLong: String(localized: "A box description can have up to 2,000 characters.", bundle: .module)
        case .emptyContents: String(localized: "Add at least one item to your box.", bundle: .module)
        case .tooManyContents: String(localized: "A box can have up to 200 items.", bundle: .module)
        case .emptyContentTitle: String(localized: "Each item needs a title.", bundle: .module)
        case .duplicateContents: String(localized: "Each item in a box must have a different identifier.", bundle: .module)
        case .reviewTooLong: String(localized: "A review can have up to 10,000 characters.", bundle: .module)
        case .invalidRating: String(localized: "The rating must be between 0.5 and 5 stars.", bundle: .module)
        case .corruptedPayload: String(localized: "This box could not be read. Its saved data is incomplete or damaged.", bundle: .module)
        case .originalIsReadOnly: String(localized: "A received original cannot be edited. Create your own version inspired by it.", bundle: .module)
        case .emptyDisplayName: String(localized: "Enter your author name.", bundle: .module)
        case .displayNameTooLong: String(localized: "Your author name can have up to 80 characters.", bundle: .module)
        }
    }
}

@MainActor
public final class BoxStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public convenience init(container: ModelContainer) {
        self.init(context: container.mainContext)
    }

    public func draft(for record: PersonalBox) throws -> BoxDraft {
        guard let payload = record.payload else { throw BoxStoreError.corruptedPayload }
        do {
            let draft = try JSONDecoder().decode(BoxDraft.self, from: payload)
            guard draft.id == record.id else { throw BoxStoreError.corruptedPayload }
            return draft
        } catch {
            throw BoxStoreError.corruptedPayload
        }
    }

    @discardableResult
    public func save(_ draft: BoxDraft) throws -> PersonalBox {
        let matching = try records().filter { $0.id == draft.id }
        guard !matching.contains(where: { $0.isOriginal == true || $0.sourceEditionID != nil }) else {
            throw BoxStoreError.originalIsReadOnly
        }
        try Self.validate(draft)
        let payload = try JSONEncoder().encode(draft)
        let now = Date()
        if let existing = matching.first {
            // Surface existing corruption instead of overwriting unreadable saved work.
            _ = try self.draft(for: existing)
            let previousTitle = existing.title
            let previousPayload = existing.payload
            let previousUpdatedAt = existing.updatedAt
            existing.title = draft.title
            existing.payload = payload
            existing.updatedAt = now
            do {
                try context.save()
            } catch {
                existing.title = previousTitle
                existing.payload = previousPayload
                existing.updatedAt = previousUpdatedAt
                throw error
            }
            return existing
        }
        let record = PersonalBox(
            id: draft.id,
            title: draft.title,
            payload: payload,
            isOriginal: false,
            createdAt: now,
            updatedAt: now
        )
        try insertAndSave(record)
        return record
    }

    public func delete(_ record: PersonalBox) throws {
        try saveStructuralChange {
            context.delete(record)
        }
    }

    public func profile() throws -> BoxAuthorProfile {
        let descriptor = FetchDescriptor<BoxAuthorProfile>(sortBy: [SortDescriptor(\.createdAt)])
        if let existing = try context.fetch(descriptor).first {
            if existing.id?.isEmpty != false {
                let previousID = existing.id
                existing.id = UUID().uuidString
                do {
                    try context.save()
                } catch {
                    existing.id = previousID
                    throw error
                }
            }
            return existing
        }
        let profile = BoxAuthorProfile(id: UUID().uuidString, displayName: "", createdAt: Date())
        try insertAndSave(profile)
        return profile
    }

    public func saveDisplayName(_ name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw BoxStoreError.emptyDisplayName }
        guard trimmed.count <= 80 else { throw BoxStoreError.displayNameTooLong }
        let profile = try profile()
        let previousName = profile.displayName
        profile.displayName = trimmed
        do {
            try context.save()
        } catch {
            profile.displayName = previousName
            throw error
        }
    }

    public func makeEdition(from record: PersonalBox) throws -> BoxEdition {
        let snapshot = try draft(for: record)
        try Self.validate(snapshot)
        return BoxEdition(box: snapshot)
    }

    @discardableResult
    public func importOriginal(_ edition: BoxEdition) throws -> PersonalBox {
        if let existing = try records().first(where: { $0.sourceEditionID == edition.id }) {
            _ = try draft(for: existing)
            return existing
        }
        try Self.validate(edition.box)
        var localSnapshot = edition.box
        localSnapshot.id = UUID()
        let payload = try JSONEncoder().encode(localSnapshot)
        let now = Date()
        let record = PersonalBox(
            id: localSnapshot.id,
            title: localSnapshot.title,
            payload: payload,
            isOriginal: true,
            sourceEditionID: edition.id,
            createdAt: now,
            updatedAt: now
        )
        try insertAndSave(record)
        return record
    }

    public nonisolated static func inspiredDraft(
        from edition: BoxEdition,
        authorID: String,
        authorName: String
    ) -> BoxDraft {
        var draft = edition.box
        draft.id = UUID()
        draft.authorID = authorID
        draft.authorName = authorName
        draft.inspiredByName = edition.box.authorName
        draft.inspiredByEditionID = edition.id
        draft.contents = draft.contents.map { content in
            var copy = content
            copy.id = UUID()
            return copy
        }
        return draft
    }

    /// Shared by local edits and remote edition decoding before any persistence.
    public nonisolated static func validate(_ draft: BoxDraft) throws {
        guard !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BoxStoreError.emptyTitle
        }
        guard draft.title.count <= 120 else { throw BoxStoreError.titleTooLong }
        guard draft.description.count <= 2_000 else { throw BoxStoreError.descriptionTooLong }
        guard !draft.contents.isEmpty else { throw BoxStoreError.emptyContents }
        guard draft.contents.count <= 200 else { throw BoxStoreError.tooManyContents }
        guard Set(draft.contents.map(\.id)).count == draft.contents.count else {
            throw BoxStoreError.duplicateContents
        }
        for content in draft.contents {
            guard !content.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw BoxStoreError.emptyContentTitle
            }
            if content.kind == .review, (content.text?.count ?? 0) > 10_000 {
                throw BoxStoreError.reviewTooLong
            }
            if let rating = content.rating, !rating.isFinite || !(0.5...5).contains(rating) {
                throw BoxStoreError.invalidRating
            }
        }
    }

    private func records() throws -> [PersonalBox] {
        // Filtering in memory avoids SwiftData's predicate collision with PersistentModel.id.
        try context.fetch(FetchDescriptor<PersonalBox>())
    }

    private func insertAndSave<Model: PersistentModel>(_ model: Model) throws {
        try saveStructuralChange {
            context.insert(model)
        }
    }

    /// SwiftData tracks inserts and deletes separately; inverse mutations do not
    /// cancel those registrations after a failed save. A private undo group does,
    /// without rolling back pending changes owned by another feature.
    private func saveStructuralChange(_ change: () -> Void) throws {
        context.processPendingChanges()
        let previousUndoManager = context.undoManager
        let operationUndoManager = UndoManager()
        operationUndoManager.groupsByEvent = false
        context.undoManager = operationUndoManager
        defer { context.undoManager = previousUndoManager }

        operationUndoManager.beginUndoGrouping()
        change()
        context.processPendingChanges()
        // SwiftData may close the explicit group while processing pending changes.
        if operationUndoManager.groupingLevel > 0 {
            operationUndoManager.endUndoGrouping()
        }

        do {
            try context.save()
        } catch {
            operationUndoManager.undo()
            context.processPendingChanges()
            throw error
        }
    }
}
