import CloudKit
import Foundation

public enum BoxSharingError: Error, LocalizedError, Sendable {
    case sharingNotConfigured
    case iCloudUnavailable
    case invalidEdition
    case unsupportedEdition
    case editionTooLarge
    case editionConflict
    case editionNotFound

    public var errorDescription: String? {
        switch self {
        case .sharingNotConfigured:
            String(localized: "Box sharing has not been configured yet.", bundle: .module)
        case .iCloudUnavailable:
            String(localized: "Sign in to iCloud in Settings to publish your box.", bundle: .module)
        case .invalidEdition:
            String(localized: "This box edition contains invalid data.", bundle: .module)
        case .unsupportedEdition:
            String(localized: "This edition requires a newer version of CinemaTV.", bundle: .module)
        case .editionTooLarge:
            String(localized: "This edition exceeds the size allowed for sharing.", bundle: .module)
        case .editionConflict:
            String(localized: "A different edition has already been published with this identifier.", bundle: .module)
        case .editionNotFound:
            String(localized: "This box edition is unavailable.", bundle: .module)
        }
    }
}

/// Public immutable snapshots. iCloud identity stays internal; no CinemaTV account is needed.
public actor BoxSharingService {
    private static let recordType = "CinemaTVBoxEdition"
    private static let schemaVersion = 1
    private static let maximumPayloadBytes = 8 * 1_024 * 1_024
    private let containerIdentifier: String
    private let baseURL: URL?

    public init(
        containerIdentifier: String = "iCloud.com.danilorequena.CinemaTV",
        baseURL: URL? = nil
    ) {
        self.containerIdentifier = containerIdentifier
        self.baseURL = baseURL
    }

    private var container: CKContainer { CKContainer(identifier: containerIdentifier) }

    public func accountAvailable() async throws -> Bool {
        try await container.accountStatus() == .available
    }

    /// Internal ownership identity; never place this value in a public record field.
    public func userRecordName() async throws -> String {
        guard try await accountAvailable() else { throw BoxSharingError.iCloudUnavailable }
        return try await container.userRecordID().recordName
    }

    public func publish(_ edition: BoxEdition) async throws -> URL {
        // Fail before touching CloudKit if recipients cannot receive a working HTTPS link.
        guard let baseURL else { throw BoxSharingError.sharingNotConfigured }
        let link: URL
        do { link = try BoxShareLink.url(for: edition.id, baseURL: baseURL) }
        catch { throw BoxSharingError.sharingNotConfigured }
        try Self.validate(edition)
        guard try await accountAvailable() else { throw BoxSharingError.iCloudUnavailable }

        let snapshot = Self.publicSnapshot(edition)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let payload = try encoder.encode(snapshot)
        guard payload.count <= Self.maximumPayloadBytes else { throw BoxSharingError.editionTooLarge }
        let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("cinematv-box-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: temporaryURL) }
        try payload.write(to: temporaryURL, options: [.atomic, .completeFileProtection])

        let database = container.publicCloudDatabase
        let recordID = Self.recordID(for: edition.id)
        let record = CKRecord(recordType: Self.recordType, recordID: recordID)
        record["schemaVersion"] = Self.schemaVersion as NSNumber
        record["editionID"] = edition.id.uuidString.lowercased() as NSString
        record["payload"] = CKAsset(fileURL: temporaryURL)

        do {
            // A fresh record has no server change tag. This policy cannot overwrite an existing edition.
            let results = try await database.modifyRecords(
                saving: [record], deleting: [], savePolicy: .ifServerRecordUnchanged, atomically: false
            )
            guard let result = results.saveResults[recordID] else { throw BoxSharingError.invalidEdition }
            _ = try result.get()
        } catch let error as CKError where error.code == .serverRecordChanged {
            // The first upload may have succeeded before a connection dropped. Only an identical retry succeeds.
            let existing = try await fetch(editionID: edition.id)
            guard existing == snapshot else { throw BoxSharingError.editionConflict }
        }
        return link
    }

    /// World-readable records can be received without signing in to iCloud.
    public func fetch(editionID: UUID) async throws -> BoxEdition {
        let record: CKRecord
        do { record = try await container.publicCloudDatabase.record(for: Self.recordID(for: editionID)) }
        catch let error as CKError where error.code == .unknownItem { throw BoxSharingError.editionNotFound }
        guard record.recordType == Self.recordType,
              record.recordID == Self.recordID(for: editionID),
              let version = record["schemaVersion"] as? NSNumber else { throw BoxSharingError.invalidEdition }
        guard version == NSNumber(value: Self.schemaVersion) else { throw BoxSharingError.unsupportedEdition }
        guard let storedID = record["editionID"] as? String,
              UUID(uuidString: storedID) == editionID,
              let asset = record["payload"] as? CKAsset,
              let fileURL = asset.fileURL, fileURL.isFileURL else { throw BoxSharingError.invalidEdition }
        // Bound reads even when an untrusted record advertises a small or absent size.
        let handle = try FileHandle(forReadingFrom: fileURL)
        defer { try? handle.close() }
        let payload = try handle.read(upToCount: Self.maximumPayloadBytes + 1) ?? Data()
        guard payload.count <= Self.maximumPayloadBytes else { throw BoxSharingError.editionTooLarge }
        let edition: BoxEdition
        do { edition = try JSONDecoder().decode(BoxEdition.self, from: payload) }
        catch { throw BoxSharingError.invalidEdition }
        guard edition.id == editionID else { throw BoxSharingError.invalidEdition }
        try Self.validate(edition)
        // Ignore any identity values supplied by a modified client.
        return Self.publicSnapshot(edition)
    }

    private static func recordID(for id: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: "box-\(id.uuidString.lowercased())")
    }

    private static func validate(_ edition: BoxEdition) throws {
        guard edition.createdAt.timeIntervalSince1970.isFinite,
              !edition.box.authorName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              edition.box.authorName.count <= 80,
              (edition.box.inspiredByName?.count ?? 0) <= 80,
              Set(edition.box.contents.map(\.id)).count == edition.box.contents.count
        else { throw BoxSharingError.invalidEdition }
        do { try BoxStore.validate(edition.box) }
        catch { throw BoxSharingError.invalidEdition }
        for content in edition.box.contents {
            guard content.title.count <= 500, content.subtitle.count <= 2_000,
                  (content.authorName?.count ?? 0) <= 80,
                  (content.text?.count ?? 0) <= 10_000,
                  content.mediaID.map({ $0 > 0 }) ?? true,
                  content.seriesID.map({ $0 > 0 }) ?? true,
                  content.seasonNumber.map({ $0 >= 0 }) ?? true,
                  content.episodeNumber.map({ $0 > 0 }) ?? true
            else { throw BoxSharingError.invalidEdition }
            if let url = content.externalURL {
                guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      parts.scheme?.lowercased() == "https",
                      let host = parts.host, !host.isEmpty,
                      parts.user == nil, parts.password == nil else { throw BoxSharingError.invalidEdition }
            }
        }
    }

    private static func publicSnapshot(_ edition: BoxEdition) -> BoxEdition {
        var snapshot = edition
        // Scope a public pseudonym to this edition. Never publish the account's CKRecord name.
        snapshot.box.authorID = "edition:\(edition.id.uuidString.lowercased())"
        for index in snapshot.box.contents.indices {
            snapshot.box.contents[index].authorID = "edition:\(edition.id.uuidString.lowercased())"
        }
        return snapshot
    }
}
