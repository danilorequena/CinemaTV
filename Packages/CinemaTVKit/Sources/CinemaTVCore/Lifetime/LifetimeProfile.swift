import Foundation
import SwiftData

/// A private CloudKit-synced preference. A nil value is retained as a
/// tombstone so clearing a date also reaches devices that are offline.
@Model
public final class LifetimeProfile {
    public var birthDateISO: String?
    public var updatedAt: Date?

    public init(birthDateISO: String? = nil, updatedAt: Date? = nil) {
        self.birthDateISO = birthDateISO
        self.updatedAt = updatedAt
    }
}

@MainActor
public final class LifetimeProfileStore {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    public var birthDate: Date? {
        guard let profile = (try? context.fetch(FetchDescriptor<LifetimeProfile>()))?
            .max(by: { ($0.updatedAt ?? .distantPast) < ($1.updatedAt ?? .distantPast) }),
              let birthDateISO = profile.birthDateISO
        else { return nil }
        return Self.formatter.date(from: birthDateISO)
    }

    public func setBirthDate(_ date: Date?) throws {
        let value = date.map { Self.formatter.string(from: $0) }
        let now = Date.now
        let profiles = try context.fetch(FetchDescriptor<LifetimeProfile>())
        if profiles.isEmpty {
            context.insert(LifetimeProfile(birthDateISO: value, updatedAt: now))
        } else {
            // Consolidates a duplicate created while two devices were offline.
            for profile in profiles {
                profile.birthDateISO = value
                profile.updatedAt = now
            }
        }
        try context.save()
    }

    private static var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // The stored value is a calendar date, not an instant. Parsing in the
        // current time zone keeps the same birthday after travel.
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }
}
