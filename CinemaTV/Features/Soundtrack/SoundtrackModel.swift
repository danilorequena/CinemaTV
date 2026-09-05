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
//  veredito do LLM (álbum de score + álbum de canções + "sobre a trilha")
//  → hidratação → cache. IA indisponível ou com erro degrada para os picks
//  heurísticos, sem texto.
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

/// Um grupo da seção (canções OU instrumental): as faixas e o álbum de onde
/// vêm — que pode diferir entre os grupos (score + compilação de canções).
struct SoundtrackGroup: Sendable {
    /// nil quando o grupo é de canções avulsas resolvidas no catálogo
    /// (título sem álbum de canções no Apple Music, caso Awesome Mix).
    let album: SoundtrackCandidate?
    let tracks: [SoundtrackTrack]
}

struct SoundtrackDisplay: Sendable {
    /// nil quando a IA está indisponível — a seção rende sem o parágrafo.
    let about: String?
    /// Grupos de canções e instrumental; pelo menos um é não-nil. Mesmo
    /// álbum nos dois = header único com fileiras rotuladas; álbuns
    /// distintos = header compacto por grupo.
    let songs: SoundtrackGroup?
    let instrumental: SoundtrackGroup?
    /// true quando a IA participou da curadoria (veredito aceito ou canções
    /// avulsas do PCC) — a seção mostra o aviso de Apple Intelligence. No
    /// caminho puramente heurístico o aviso seria falso, então some.
    let aiAssisted: Bool
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
                let primary = try await catalog.album(id: albumID)
                // Falha só nas canções degrada para o primário.
                var songsAlbum: SoundtrackAlbum?
                if let songsID = cached.songsAlbumID {
                    songsAlbum = try? await catalog.album(id: songsID)
                }
                var looseSongs: [SoundtrackTrack] = []
                if songsAlbum == nil, let ids = cached.songIDs, !ids.isEmpty {
                    looseSongs = (try? await catalog.songs(ids: ids)) ?? []
                }
                Self.logger.info("\(query.title): cache hit (album \(albumID), songs \(cached.songsAlbumID ?? "-"), avulsas \(cached.songIDs?.count ?? 0))")
                state = .loaded(Self.display(primary: primary, songsAlbum: songsAlbum, looseSongs: looseSongs, about: cached.about, query: query))
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

        // 3. Une os candidatos de TODOS os termos (dedupe por id): o termo
        // preciso acha o score, mas às vezes só o termo genérico ou o do
        // título original traz a compilação de canções (caso Awesome Mix,
        // que não aparece na busca por "... Original Motion Picture
        // Soundtrack"). Erro de busca (rede, token do MusicKit) NÃO vira
        // cache negativo — só "zero resultados" genuíno pode ser lembrado
        // por 30 dias.
        var seenIDs = Set<String>()
        var candidates: [SoundtrackCandidate] = []
        var searchFailed = false
        let terms = SoundtrackFinder.searchTerms(
            title: query.title,
            originalTitle: query.originalTitle,
            kind: query.kind
        )
        for term in terms {
            do {
                let found = try await catalog.searchAlbums(term: term, limit: 10)
                for candidate in found where seenIDs.insert(candidate.id).inserted {
                    candidates.append(candidate)
                }
            } catch {
                searchFailed = true
                Self.logger.error("\(query.title): busca '\(term)' falhou: \(String(describing: error))")
            }
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
        // Lista completa em debug: é o que permite diagnosticar por que um
        // álbum de canções não foi escolhido (ausente vs. mal ranqueado).
        Self.logger.debug("\(query.title): \(candidates.map { "[\($0.id)] \($0.title) — \($0.artistName)" }.joined(separator: " | "))")

        // 4. Sinais baratos antes do modelo.
        let scored = SoundtrackFinder.rank(
            candidates,
            title: query.title,
            releaseYear: query.releaseYear,
            composers: query.composers
        )
        let heuristicScorePick = SoundtrackFinder.confidentPick(scored)
        let heuristicSongsPick = SoundtrackFinder.songsPick(scored, composers: query.composers)
        let shortlist = SoundtrackFinder.shortlist(scored)

        // 5. Veredito do agente (score + canções numa geração); qualquer
        // AgentError degrada em silêncio para os picks heurísticos.
        var scoreID = heuristicScorePick?.id
        var songsID = heuristicSongsPick?.id
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
            if let verdict {
                Self.logger.info("\(query.title): veredito score=\(verdict.scoreAlbumID ?? "nil") songs=\(verdict.songsAlbumID ?? "nil") conf=\(verdict.confidence)")
            }
            if let verdict, verdict.confidence >= 0.5 {
                let validIDs = Set(shortlist.map(\.id))
                var accepted = false
                if let id = verdict.scoreAlbumID, validIDs.contains(id) {
                    scoreID = id
                    accepted = true
                }
                if let id = verdict.songsAlbumID, validIDs.contains(id) {
                    songsID = id
                    accepted = true
                }
                if accepted {
                    about = verdict.about
                } else if verdict.scoreAlbumID == nil, verdict.songsAlbumID == nil,
                          heuristicScorePick == nil, heuristicSongsPick == nil {
                    // Modelo confiante de que nenhum candidato serve e a
                    // heurística concorda: cache negativo.
                    scoreID = nil
                    songsID = nil
                }
            }
        }

        // Sem score, a compilação de canções vira o álbum primário.
        guard let primaryID = scoreID ?? songsID else {
            Self.logger.info("\(query.title): nenhum candidato aprovado — cache negativo")
            storeNegative(in: cache, query: query, storefront: storefront)
            state = .idle
            return
        }
        let distinctSongsID = songsID != primaryID ? songsID : nil

        // 6. Hidrata faixas/artwork e persiste o veredito. Falha só no
        // álbum de canções degrada para o primário.
        let primary: SoundtrackAlbum
        do {
            primary = try await catalog.album(id: primaryID)
        } catch {
            Self.logger.error("\(query.title): hidratação do álbum \(primaryID) falhou: \(String(describing: error))")
            state = .idle
            return
        }
        var songsAlbum: SoundtrackAlbum?
        if let distinctSongsID {
            songsAlbum = try? await catalog.album(id: distinctSongsID)
        }

        // 7. Sem álbum de canções e sem vocais no primário (score puro):
        // o PCC lista as canções famosas do título e o catálogo resolve
        // uma a uma — caso Awesome Mix, cujas compilações saíram do Apple
        // Music mas as canções originais continuam lá. nil = fallback não
        // tentado (sem PCC): não vira cache "sem canções".
        var looseSongs: [SoundtrackTrack]?
        if songsAlbum == nil {
            let split = SoundtrackFinder.splitTracks(
                primary.tracks,
                albumArtist: primary.candidate.artistName,
                composers: query.composers
            )
            if split.songs.isEmpty {
                looseSongs = await resolveNotableSongs(catalog: catalog, agent: agent, query: query, primary: primary)
            }
        }

        Self.logger.info("\(query.title): álbum \(primaryID) escolhido (songs: \(distinctSongsID ?? "-"), avulsas: \(looseSongs?.count ?? 0), about: \(about != nil))")
        cache.store(
            SoundtrackCache.Entry(
                albumID: primaryID,
                songsAlbumID: distinctSongsID,
                songIDs: looseSongs?.map(\.id),
                about: about,
                storefront: storefront,
                savedAt: .now
            ),
            kind: query.kind,
            tmdbID: query.tmdbID
        )
        state = .loaded(Self.display(primary: primary, songsAlbum: songsAlbum, looseSongs: looseSongs ?? [], about: about, query: query))
    }

    /// Fallback de canções avulsas — SÓ no Private Cloud Compute: o modelo
    /// on-device não conhece trilhas de filmes e alucina, e a busca do
    /// catálogo casa por palavras do título, sem ligação com o filme. Cada
    /// canção listada pelo PCC é verificada no catálogo (título E artista
    /// precisam bater); menos de duas resolvidas é sinal de chute e a
    /// fileira não aparece. nil = não tentou (sem PCC); [] = tentou e nada.
    private func resolveNotableSongs(
        catalog: AppleMusicCatalog,
        agent: AgentEngine,
        query: SoundtrackQuery,
        primary: SoundtrackAlbum
    ) async -> [SoundtrackTrack]? {
        let status = agent.status()
        guard status.privateCloud.isAvailable, status.quota?.level != .limitReached else {
            Self.logger.info("\(query.title): sem PCC para canções avulsas — fileira ausente")
            return nil
        }

        let verdict: NotableSongsVerdict
        do {
            verdict = try await agent.respond(
                to: SoundtrackPrompt.notableSongsPrompt(
                    title: query.title,
                    releaseYear: query.releaseYear,
                    kind: query.kind
                ),
                generating: NotableSongsVerdict.self,
                instructions: SoundtrackPrompt.notableSongsInstructions(),
                task: AgentTask(complexity: .hard)
            )
        } catch {
            Self.logger.notice("\(query.title): PCC indisponível para canções avulsas (\(String(describing: error)))")
            return nil
        }
        Self.logger.debug("\(query.title): PCC listou: \(verdict.songs.map { "\($0.title) — \($0.artist)" }.joined(separator: " | "))")

        let primaryTrackIDs = Set(primary.tracks.map(\.id))
        let primaryTitles = Set(primary.tracks.map { SoundtrackFinder.normalize($0.title) })
        var songs: [SoundtrackTrack] = []
        var seenIDs = Set<String>()
        for notable in verdict.songs.prefix(8) {
            guard let found = try? await catalog.searchSongs(term: "\(notable.title) \(notable.artist)", limit: 5) else { continue }
            let plausible = SoundtrackFinder.plausibleSongCandidates(found)
            guard let match = SoundtrackFinder.bestSongMatch(title: notable.title, artist: notable.artist, in: plausible),
                  seenIDs.insert(match.id).inserted,
                  !primaryTrackIDs.contains(match.id),
                  !primaryTitles.contains(SoundtrackFinder.normalize(match.title))
            else { continue }
            songs.append(match)
        }
        Self.logger.info("\(query.title): \(songs.count)/\(verdict.songs.count) canções do PCC resolvidas no catálogo")

        // Uma única canção resolvida é mais chute do que trilha; melhor
        // fileira ausente do que errada.
        guard songs.count >= 2 else { return [] }
        return songs
    }

    /// Monta o display: com álbum de canções distinto, cada álbum vira um
    /// grupo inteiro; com canções avulsas, elas viram o grupo de canções
    /// (sem álbum); com um álbum só, splitTracks separa vocais de score.
    private static func display(
        primary: SoundtrackAlbum,
        songsAlbum: SoundtrackAlbum?,
        looseSongs: [SoundtrackTrack],
        about: String?,
        query: SoundtrackQuery
    ) -> SoundtrackDisplay {
        // IA participou quando o veredito foi aceito (gera o about) ou
        // quando as canções avulsas vieram do PCC. Pick heurístico puro
        // (agente indisponível) não leva o aviso de Apple Intelligence.
        let aiAssisted = about != nil || !looseSongs.isEmpty
        if let songsAlbum {
            return SoundtrackDisplay(
                about: about,
                songs: SoundtrackGroup(album: songsAlbum.candidate, tracks: songsAlbum.tracks),
                instrumental: SoundtrackGroup(album: primary.candidate, tracks: primary.tracks),
                aiAssisted: aiAssisted
            )
        }
        if !looseSongs.isEmpty {
            return SoundtrackDisplay(
                about: about,
                songs: SoundtrackGroup(album: nil, tracks: looseSongs),
                instrumental: SoundtrackGroup(album: primary.candidate, tracks: primary.tracks),
                aiAssisted: aiAssisted
            )
        }
        let split = SoundtrackFinder.splitTracks(
            primary.tracks,
            albumArtist: primary.candidate.artistName,
            composers: query.composers
        )
        // Ambos vazios (álbum sem faixas hidratáveis): fileira única vazia,
        // comportamento idêntico ao anterior.
        guard !split.songs.isEmpty || !split.instrumental.isEmpty else {
            return SoundtrackDisplay(
                about: about,
                songs: nil,
                instrumental: SoundtrackGroup(album: primary.candidate, tracks: primary.tracks),
                aiAssisted: aiAssisted
            )
        }
        return SoundtrackDisplay(
            about: about,
            songs: split.songs.isEmpty ? nil : SoundtrackGroup(album: primary.candidate, tracks: split.songs),
            instrumental: split.instrumental.isEmpty ? nil : SoundtrackGroup(album: primary.candidate, tracks: split.instrumental),
            aiAssisted: aiAssisted
        )
    }

    private func storeNegative(in cache: SoundtrackCache, query: SoundtrackQuery, storefront: String?) {
        cache.store(
            SoundtrackCache.Entry(albumID: nil, about: nil, storefront: storefront, savedAt: .now),
            kind: query.kind,
            tmdbID: query.tmdbID
        )
    }
}
