//
//  ReleaseDatesTests.swift
//  CinemaTVKit
//

import Foundation
import Testing
@testable import CinemaTVCore

@Suite struct ReleaseDatesTests {
    private let now = try! Date("2026-08-28T12:00:00Z", strategy: .iso8601)

    @Test func pastAndTodayCountAsReleased() {
        #expect(ReleaseDates.hasPassed("2020-01-01", asOf: now))
        // O próprio dia da estreia conta como lançado.
        #expect(ReleaseDates.hasPassed("2026-08-28", asOf: now))
        #expect(!ReleaseDates.hasPassed("2026-08-29", asOf: now))
        #expect(!ReleaseDates.hasPassed("2999-12-31", asOf: now))
    }

    @Test func missingOrUnparsableDatesArePermissive() {
        #expect(ReleaseDates.hasPassed(nil, asOf: now))
        #expect(ReleaseDates.hasPassed("", asOf: now))
        #expect(ReleaseDates.hasPassed("soon", asOf: now))
    }

    @Test func yearOnlyFallback() {
        // MovieEntity só carrega o ano; ano corrente ou passado libera.
        #expect(ReleaseDates.hasPassed("2026", asOf: now))
        #expect(ReleaseDates.hasPassed("1999", asOf: now))
        #expect(!ReleaseDates.hasPassed("2027", asOf: now))
    }
}
