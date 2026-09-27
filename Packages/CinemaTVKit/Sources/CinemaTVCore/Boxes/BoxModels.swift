import Foundation
import SwiftData

public enum BoxContentKind: String, Codable, CaseIterable, Sendable {
    case movie, series, season, episode, trailer, soundtrack, review
}

public struct BoxContent: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var kind: BoxContentKind
    public var title: String
    public var subtitle: String
    public var mediaID: Int?
    public var seriesID: Int?
    public var seasonNumber: Int?
    public var episodeNumber: Int?
    public var posterPath: String?
    public var externalURL: URL?
    public var text: String?
    public var rating: Double?
    public var authorID: String?
    public var authorName: String?

    public init(
        id: UUID = UUID(),
        kind: BoxContentKind,
        title: String,
        subtitle: String = "",
        mediaID: Int? = nil,
        seriesID: Int? = nil,
        seasonNumber: Int? = nil,
        episodeNumber: Int? = nil,
        posterPath: String? = nil,
        externalURL: URL? = nil,
        text: String? = nil,
        rating: Double? = nil,
        authorID: String? = nil,
        authorName: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.mediaID = mediaID
        self.seriesID = seriesID
        self.seasonNumber = seasonNumber
        self.episodeNumber = episodeNumber
        self.posterPath = posterPath
        self.externalURL = externalURL
        self.text = text
        self.rating = rating
        self.authorID = authorID
        self.authorName = authorName
    }
}

public enum BoxCoverStyle: String, Codable, CaseIterable, Sendable {
    case cosmic, minimal, mystery, comfort, poster
}

public struct BoxDraft: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var title: String
    public var description: String
    public var coverStyle: BoxCoverStyle
    public var coverPosterPath: String?
    public var authorID: String
    public var authorName: String
    public var inspiredByName: String?
    public var inspiredByEditionID: UUID?
    public var contents: [BoxContent]

    public init(
        id: UUID = UUID(),
        title: String = "",
        description: String = "",
        coverStyle: BoxCoverStyle = .cosmic,
        coverPosterPath: String? = nil,
        authorID: String = "",
        authorName: String = "",
        inspiredByName: String? = nil,
        inspiredByEditionID: UUID? = nil,
        contents: [BoxContent] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.coverStyle = coverStyle
        self.coverPosterPath = coverPosterPath
        self.authorID = authorID
        self.authorName = authorName
        self.inspiredByName = inspiredByName
        self.inspiredByEditionID = inspiredByEditionID
        self.contents = contents
    }
}

/// A value snapshot: subsequent changes to the source box cannot change this edition.
public struct BoxEdition: Identifiable, Codable, Hashable, Sendable {
    public var id: UUID
    public var createdAt: Date
    public var box: BoxDraft

    public init(id: UUID = UUID(), createdAt: Date = Date(), box: BoxDraft) {
        self.id = id
        self.createdAt = createdAt
        self.box = box
    }
}

/// Optional attributes and no uniqueness constraints keep the model CloudKit compatible.
@Model
public final class PersonalBox {
    public var id: UUID?
    public var title: String?
    public var payload: Data?
    public var isOriginal: Bool? = false
    public var sourceEditionID: UUID?
    public var createdAt: Date?
    public var updatedAt: Date?

    public init(
        id: UUID? = nil,
        title: String? = nil,
        payload: Data? = nil,
        isOriginal: Bool? = false,
        sourceEditionID: UUID? = nil,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.payload = payload
        self.isOriginal = isOriginal
        self.sourceEditionID = sourceEditionID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
public final class BoxAuthorProfile {
    public var id: String?
    public var displayName: String?
    public var createdAt: Date?

    public init(id: String? = nil, displayName: String? = nil, createdAt: Date? = nil) {
        self.id = id
        self.displayName = displayName
        self.createdAt = createdAt
    }
}
