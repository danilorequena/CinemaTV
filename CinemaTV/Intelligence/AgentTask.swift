//
//  AgentTask.swift
//  CinemaTV
//
//  Descreve uma tarefa para o motor de IA. Livre de FoundationModels de
//  propósito (molde do VisualTextExtractor): a política de roteamento fica
//  pura e testável; a ponte com o framework mora no AgentEngine.
//

import Foundation

struct AgentTask: Sendable, Equatable {
    enum Complexity: Sendable, Equatable {
        /// Extração/classificação curta — sempre on-device.
        case light
        /// Geração típica (desambiguação, parágrafos curtos).
        case standard
        /// Raciocínio longo ou contexto grande — candidata ao PCC.
        case hard
    }

    /// Esforço de raciocínio quando a tarefa roda no Private Cloud Compute
    /// (mapeia para ContextOptions.ReasoningLevel; ignorado on-device).
    enum Reasoning: Sendable, Equatable {
        case light
        case moderate
        case deep
    }

    var complexity: Complexity = .standard
    var allowsPrivateCloud: Bool = true
    var reasoning: Reasoning = .light
}
