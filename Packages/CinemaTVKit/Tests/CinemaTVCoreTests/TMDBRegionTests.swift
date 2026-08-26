//
//  TMDBRegionTests.swift
//  CinemaTVKit
//

import Foundation
import Testing
@testable import CinemaTVCore

struct TMDBRegionTests {
    @Test func overrideWinsOverDeviceDefault() throws {
        let defaults = try makeCleanDefaults(suite: "TMDBRegionTests.override")
        defaults.set("BR", forKey: TMDBRegion.overrideKey)
        #expect(TMDBRegion.current(in: defaults) == "BR")
    }

    @Test func emptyOverrideFallsBackToDeviceDefault() throws {
        let defaults = try makeCleanDefaults(suite: "TMDBRegionTests.empty")
        defaults.set("", forKey: TMDBRegion.overrideKey)
        #expect(TMDBRegion.current(in: defaults) == TMDBRegion.deviceDefault)
    }

    @Test func missingOverrideFallsBackToDeviceDefault() throws {
        let defaults = try makeCleanDefaults(suite: "TMDBRegionTests.missing")
        #expect(TMDBRegion.current(in: defaults) == TMDBRegion.deviceDefault)
    }

    @Test func selectableRegionsAreCountryCodes() {
        let regions = TMDBRegion.selectableRegions
        #expect(regions.contains("BR"))
        #expect(regions.contains("US"))
        #expect(regions.allSatisfy { $0.count == 2 })
    }

    private func makeCleanDefaults(suite: String) throws -> UserDefaults {
        let defaults = try #require(UserDefaults(suiteName: suite))
        defaults.removePersistentDomain(forName: suite)
        return defaults
    }
}
