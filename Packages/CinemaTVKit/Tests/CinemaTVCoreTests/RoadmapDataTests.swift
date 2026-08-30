//
//  RoadmapDataTests.swift
//  CinemaTVCoreTests
//
//  Sanidade do conteúdo autoral do AppRoadmap: ids únicos, ordenação,
//  datas e textos válidos — erro de autoria quebra aqui, não na tela.
//

import Foundation
import Testing
@testable import CinemaTVCore

@Suite("AppRoadmap data")
struct RoadmapDataTests {
    @Test("Versões das releases são únicas")
    func releaseVersionsAreUnique() {
        let versions = AppRoadmap.releases.map(\.version)
        #expect(Set(versions).count == versions.count)
    }

    @Test("Releases vêm da mais nova para a mais antiga")
    func releasesAreSortedNewestFirst() {
        let dates = AppRoadmap.releases.map(\.date)
        #expect(dates == dates.sorted(by: >))
    }

    @Test("Datas de release são válidas")
    func releaseDatesAreValid() {
        for release in AppRoadmap.releases {
            #expect(release.date != .distantPast, "Data inválida na versão \(release.version)")
        }
    }

    @Test("Ids de entries são únicos no changelog inteiro")
    func entryIDsAreUnique() {
        let ids = AppRoadmap.releases.flatMap(\.entries).map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test("Nenhum texto ou crédito em branco")
    func noBlankTextsOrCredits() {
        for entry in AppRoadmap.releases.flatMap(\.entries) {
            #expect(!entry.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            if let credit = entry.credit {
                #expect(!credit.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
