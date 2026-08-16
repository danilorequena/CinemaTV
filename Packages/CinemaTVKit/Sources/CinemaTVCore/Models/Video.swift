//
//  Video.swift
//  CinemaTVKit
//

import Foundation

public struct VideosResponse: Decodable, Sendable {
    public let id: Int
    public let results: [Video]
}

public struct Video: Identifiable, Hashable, Sendable, Decodable {
    public let id: String
    public let key: String
    public let name: String
    public let site: String
    public let type: String
    public let official: Bool?

    public init(id: String, key: String, name: String, site: String, type: String, official: Bool?) {
        self.id = id
        self.key = key
        self.name = name
        self.site = site
        self.type = type
        self.official = official
    }

    public var isYouTubeTrailer: Bool {
        site.caseInsensitiveCompare("YouTube") == .orderedSame && type == "Trailer"
    }

    public var youTubeEmbedURL: URL? {
        URL(string: "https://www.youtube.com/embed/\(key)")
    }

    public var youTubeThumbnailURL: URL? {
        URL(string: "https://img.youtube.com/vi/\(key)/hqdefault.jpg")
    }
}
