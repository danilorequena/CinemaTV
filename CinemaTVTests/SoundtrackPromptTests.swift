//
//  SoundtrackPromptTests.swift
//  CinemaTVTests
//
//  A construção do prompt é pura: cobrimos conteúdo e ordem determinística
//  sem invocar o modelo.
//

import Foundation
import Testing
@testable import CinemaTV

struct SoundtrackPromptTests {
    private let candidates = [
        SoundtrackCandidate(id: "111", title: "Titanic: Music from the Motion Picture", artistName: "James Horner", releaseYear: 1997, trackCount: 15, artworkURL: nil, url: nil),
        SoundtrackCandidate(id: "222", title: "Titanic Karaoke Hits", artistName: "Karaoke Band", releaseYear: 2005, trackCount: nil, artworkURL: nil, url: nil),
    ]

    @Test func promptCarriesTitleYearComposersAndCandidates() {
        let prompt = SoundtrackPrompt.verdictPrompt(
            title: "Titanic",
            releaseYear: 1997,
            composers: ["James Horner"],
            kind: .movie,
            candidates: candidates
        )
        #expect(prompt.contains("MOVIE: Titanic (1997)"))
        #expect(prompt.contains("COMPOSERS: James Horner"))
        #expect(prompt.contains("1. id: 111"))
        #expect(prompt.contains("2. id: 222"))
        #expect(prompt.contains("tracks: unknown"))
    }

    @Test func promptIsDeterministicForSameInput() {
        let make = {
            SoundtrackPrompt.verdictPrompt(
                title: "Titanic",
                releaseYear: 1997,
                composers: ["James Horner"],
                kind: .movie,
                candidates: candidates
            )
        }
        #expect(make() == make())
    }

    @Test func tvPromptUsesShowLabelAndOmitsMissingSections() {
        let prompt = SoundtrackPrompt.verdictPrompt(
            title: "Game of Thrones",
            releaseYear: nil,
            composers: [],
            kind: .tv,
            candidates: candidates
        )
        #expect(prompt.contains("TV SHOW: Game of Thrones"))
        #expect(!prompt.contains("COMPOSERS:"))
        #expect(!prompt.contains("(nil)"))
    }

    @Test func instructionsForbidInventingIDs() {
        let instructions = SoundtrackPrompt.instructions(locale: Locale(identifier: "en_US"))
        #expect(instructions.contains("Never invent an id"))
        #expect(instructions.contains("karaoke"))
        // en_US não leva a frase de locale.
        #expect(!instructions.contains("The person's locale"))
    }

    @Test func instructionsAskForScoreAndSongsAlbums() {
        let instructions = SoundtrackPrompt.instructions(locale: Locale(identifier: "en_US"))
        #expect(instructions.contains("score album"))
        #expect(instructions.contains("songs album"))
        #expect(instructions.contains("SAME id"))
    }

    @Test func notableSongsPromptDemandsCertaintyAndVocals() {
        let prompt = SoundtrackPrompt.notableSongsPrompt(
            title: "Guardians of the Galaxy",
            releaseYear: 2014,
            kind: .movie
        )
        #expect(prompt.contains("MOVIE: Guardians of the Galaxy (2014)"))
        let instructions = SoundtrackPrompt.notableSongsInstructions()
        #expect(instructions.contains("VOCAL"))
        #expect(instructions.contains("empty list is a valid answer"))
        #expect(instructions.contains("original recording artist"))
    }

    @Test func nonEnglishLocaleAddsLanguageInstruction() {
        let instructions = SoundtrackPrompt.instructions(locale: Locale(identifier: "pt_BR"))
        #expect(instructions.contains("The person's locale is pt_BR."))
        #expect(instructions.contains("person's language"))
    }
}
