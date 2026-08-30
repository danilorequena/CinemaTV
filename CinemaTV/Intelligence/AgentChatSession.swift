//
//  AgentChatSession.swift
//  CinemaTV
//
//  Sessão multi-turn sobre uma LanguageModelSession — a costura para o
//  futuro chat/assistente. Nenhuma UI usa isto ainda; nasce junto com o
//  motor para o AgentEngine já expor o seam correto (tools + transcript).
//

import Foundation
import FoundationModels
import Observation

@MainActor
@Observable
final class AgentChatSession {
    @ObservationIgnored private let session: LanguageModelSession

    private(set) var isResponding = false

    /// Histórico completo da conversa (prompts, respostas, tool calls).
    var transcript: Transcript { session.transcript }

    init(session: LanguageModelSession) {
        self.session = session
    }

    /// Um turno da conversa; o contexto acumula na própria sessão.
    func send(_ prompt: String) async throws(AgentError) -> String {
        isResponding = true
        defer { isResponding = false }
        do {
            return try await session.respond(to: prompt).content
        } catch {
            throw AgentEngine.mapError(error)
        }
    }

    /// Variante streaming para UI incremental.
    func stream(_ prompt: String) -> LanguageModelSession.ResponseStream<String> {
        session.streamResponse(to: prompt)
    }
}
