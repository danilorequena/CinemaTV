//
//  CinemaTVCoreTests.swift
//  CinemaTVKit
//

import Testing
@testable import CinemaTVCore

@Test func packageScaffoldIsWired() {
    #expect(CinemaTVCoreInfo.version == "1.0.0")
}
