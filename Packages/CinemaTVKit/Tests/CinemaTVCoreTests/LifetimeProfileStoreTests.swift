import Foundation
import SwiftData
import Testing
@testable import CinemaTVCore

@MainActor
@Suite struct LifetimeProfileStoreTests {
    @Test func savesOptionalBirthDateAndClearsItWithATombstone() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let store = LifetimeProfileStore(context: container.mainContext)
        let birthDate = try #require(ISO8601DateFormatter().date(from: "1990-05-14T12:00:00Z"))

        try store.setBirthDate(birthDate)
        #expect(Calendar.current.dateComponents([.year, .month, .day], from: try #require(store.birthDate)) == DateComponents(year: 1990, month: 5, day: 14))

        try store.setBirthDate(nil)
        #expect(store.birthDate == nil)
        #expect(try container.mainContext.fetch(FetchDescriptor<LifetimeProfile>()).count == 1)
    }

    @Test func newestProfileWinsWhenCloudKitTemporarilyDuplicatesRecords() throws {
        let container = try ModelContainerFactory.makeInMemory()
        let context = container.mainContext
        context.insert(LifetimeProfile(birthDateISO: "1980-01-01", updatedAt: .distantPast))
        context.insert(LifetimeProfile(birthDateISO: "2000-12-31", updatedAt: .now))
        try context.save()

        let store = LifetimeProfileStore(context: context)
        #expect(Calendar.current.dateComponents([.year, .month, .day], from: try #require(store.birthDate)) == DateComponents(year: 2000, month: 12, day: 31))
        try store.setBirthDate(nil)
        #expect(store.birthDate == nil)
    }
}
