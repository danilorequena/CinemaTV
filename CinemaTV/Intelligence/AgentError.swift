//
//  AgentError.swift
//  CinemaTV
//
//  Fronteira do typed throws do motor de IA: os erros não tipados do
//  FoundationModels viram este domínio (no molde TMDBClient → TMDBError).
//

import Foundation

enum AgentError: Error, Equatable, Sendable {
    /// Nenhum modelo utilizável para a tarefa (roteamento devolveu nil).
    case modelsUnavailable
    /// Quota diária do Private Cloud Compute esgotada.
    case quotaExhausted(resetDate: Date?)
    /// Guardrails de segurança bloquearam prompt ou resposta.
    case guardrailViolation
    /// O modelo recusou responder.
    case refused
    /// Prompt + resposta excedem a janela de contexto do modelo.
    case contextWindowExceeded
    /// O idioma pedido não é suportado pelo modelo.
    case unsupportedLanguage
    /// Qualquer outra falha de geração.
    case generationFailed(description: String)
}

extension AgentError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .modelsUnavailable:
            String(localized: "Apple Intelligence is unavailable.")
        case .quotaExhausted:
            String(localized: "Daily Private Cloud Compute limit reached.")
        case .guardrailViolation, .refused:
            String(localized: "The model can't respond to this content.")
        case .contextWindowExceeded:
            String(localized: "The request is too long for the model.")
        case .unsupportedLanguage:
            String(localized: "This language isn't supported by the model.")
        case .generationFailed(let description):
            description
        }
    }
}
