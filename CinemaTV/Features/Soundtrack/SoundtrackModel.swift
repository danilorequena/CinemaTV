//
//  SoundtrackModel.swift
//  CinemaTV
//
//  Estado da seção de trilha sonora. Deliberadamente separado do
//  MovieDetailModel/TVShowDetailModel (all-or-nothing): trilha é enfeite —
//  qualquer falha (busca, autorização, IA, guardrail) termina em .idle e a
//  seção simplesmente não aparece; nunca .failed na tela.
//
//  Pipeline do load: cache → autorização → busca → rank heurístico →
//  veredito do LLM (desambiguação + "sobre a trilha") → hidratação → cache.
//  IA indisponível ou com erro degrada para o pick heurístico, sem texto.
//

import Foundation
import os
import CinemaTVCore
import CinemaTVDesignSystem

struct SoundtrackQuery: Sendable, Equatable {
    let kind: SoundtrackFinder.MediaKind
    let tmdbID: Int
    let title: String
    let originalTitle: String?
    let releaseYear: Int?
    let composers: [String]
}

struct SoundtrackDisplay: Sendable {
    let album: SoundtrackAlbum
    /// nil quando a IA está indisponível — a seção rende sem o parágrafo.
    let about: String?
}

@MainActor
@Observable
final class SoundtrackModel {
    /// A seção falha em silêncio por design; o Console (subsystem do app,
    /// category "Soundtrack") é o único lugar que conta o porquê.
    private static let logger = Logger(
        subsystem: "com.danilorequena.CinemaTV",
        category: "Soundtrack"
    )

    private(set) var state: LoadState<SoundtrackDisplay> = .idle

    func load(
        catalog: AppleMusicCatalog,
        agent: AgentEngine,
        cache: SoundtrackCache = SoundtrackCache(),
        query: SoundtrackQuery
    ) async {
        if case .loaded = state { return }
        state = .loading

        let storefront = await catalog.currentStorefront()

        // 1. Cache fresco: nem busca, nem LLM.
        if let cached = cache.entry(kind: query.kind, tmdbID: query.tmdbID, storefront: storefront) {
            guard let albumID = cached.albumID else {
                Self.logger.info("\(query.title): cache negativo — seção ausente")
                state = .idle
                return
            }
            do {
                let album = try await catalog.album(id: albumID)
                Self.logger.info("\(query.title): cache hit (album \(albumID))")
                state = .loaded(SoundtrackDisplay(album: album, about: cached.about))
            } catch {
                Self.logger.error("\(query.title): hidratação do cache falhou: \(String(describing: error))")
                state = .idle
            }
            return
        }

        // 2. Autorização negada: seção ausente, sem insistir.
        guard await catalog.requestAuthorizationIfNeeded() else {
            Self.logger.notice("\(query.title): sem autorização do Apple Music — seção ausente")
            state = .idle
            return
        }

        // 3. Termos em ordem de precisão até aparecer candidato. Erro de
        // busca (rede, token do MusicKit) NÃO vira cache negativo — só
        // "zero resultados" genuíno pode ser lembrado por 30 dias.
        var candidates: [SoundtrackCandidate] = []
        var searchFailed = false
        let terms = SoundtrackFinder.searchTerms(
            title: query.title,
            originalTitle: query.originalTitle,
            kind: query.kind
        )
        for term in terms {
            do {
                candidates = try await catalog.searchAlbums(term: term, limit: 10)
            } catch {
                searchFailed = true
                Self.logger.error("\(query.title): busca '\(term)' falhou: \(String(describing: error))")
                continue
            }
            if !candidates.isEmpty { break }
        }
        guard !candidates.isEmpty else {
            if searchFailed {
                Self.logger.error("\(query.title): todas as buscas falharam — seção ausente, sem cache")
            } else {
                Self.logger.info("\(query.title): catálogo sem resultados — cache negativo")
                storeNegative(in: cache, query: query, storefront: storefront)
            }
            state = .idle
            return
        }
        Self.logger.info("\(query.title): \(candidates.count) candidatos")

        // 4. Sinais baratos antes do modelo.
        let scored = SoundtrackFinder.rank(
            candidates,
            title: query.title,
            releaseYear: query.releaseYear,
            composers: query.composers
        )
        let heuristicPick = SoundtrackFinder.confidentPick(scored)
        let shortlist = SoundtrackFinder.shortlist(scored)

        // 5. Veredito do agente; qualquer AgentError degrada em silêncio.
        var chosenID = heuristicPick?.id
        var about: String?
        if !shortlist.isEmpty {
            let prompt = SoundtrackPrompt.verdictPrompt(
                title: query.title,
                releaseYear: query.releaseYear,
                composers: query.composers,
                kind: query.kind,
                candidates: shortlist
            )
            var verdict: SoundtrackVerdict?
            do {
                verdict = try await agent.respond(
                    to: prompt,
                    generating: SoundtrackVerdict.self,
                    instructions: SoundtrackPrompt.instructions(),
                    task: AgentTask(complexity: .standard)
                )
            } catch {
                Self.logger.notice("\(query.title): agente indisponível (\(String(describing: error))) — fallback heurístico")
            }
            if let verdict, verdict.confidence >= 0.5 {
                if let id = verdict.albumID, shortlist.contains(where: { $0.id == id }) {
                    chosenID = id
                    about = verdict.about
                } else if verdict.albumID == nil, heuristicPick == nil {
                    // Modelo confiante de que nenhum candidato serve e a
                    // heurística concorda: cache negativo.
                    chosenID = nil
                }
            }
        }

        guard let chosenID else {
            Self.logger.info("\(query.title): nenhum candidato aprovado — cache negativo")
            storeNegative(in: cache, query: query, storefront: storefront)
            state = .idle
            return
        }

        // 6. Hidrata faixas/artwork e persiste o veredito.
        let album: SoundtrackAlbum
        do {
            album = try await catalog.album(id: chosenID)
        } catch {
            Self.logger.error("\(query.title): hidratação do álbum \(chosenID) falhou: \(String(describing: error))")
            state = .idle
            return
        }
        Self.logger.info("\(query.title): álbum \(chosenID) escolhido (about: \(about != nil))")
        cache.store(
            SoundtrackCache.Entry(albumID: chosenID, about: about, storefront: storefront, savedAt: .now),
            kind: query.kind,
            tmdbID: query.tmdbID
        )
        state = .loaded(SoundtrackDisplay(album: album, about: about))
    }

    private func storeNegative(in cache: SoundtrackCache, query: SoundtrackQuery, storefront: String?) {
        cache.store(
            SoundtrackCache.Entry(albumID: nil, about: nil, storefront: storefront, savedAt: .now),
            kind: query.kind,
            tmdbID: query.tmdbID
        )
    }
}
