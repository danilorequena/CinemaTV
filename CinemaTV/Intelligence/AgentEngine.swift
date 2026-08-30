//
//  AgentEngine.swift
//  CinemaTV
//
//  Motor de IA do app: única ponte com o FoundationModels para chamadas
//  one-shot. Struct Sendable sem estado (default estável no @Entry); o
//  roteamento on-device vs Private Cloud Compute é decidido por chamada
//  via AgentRoutingPolicy. Sessões multi-turn saem de makeSession
//  (AgentChatSession) — costura para o futuro chat/assistente.
//

import Foundation
import FoundationModels

struct AgentEngine: Sendable {
    init() {}

    // MARK: - Status

    /// Snapshot para Settings e para o roteamento.
    func status() -> AgentStatus {
        let onDevice = Self.state(of: SystemLanguageModel.default.availability)
        let privateCloudModel = PrivateCloudComputeLanguageModel()
        let privateCloud = Self.state(of: privateCloudModel.availability)
        let quota = privateCloud.isAvailable
            ? Self.quota(from: privateCloudModel.quotaUsage)
            : nil
        return AgentStatus(onDevice: onDevice, privateCloud: privateCloud, quota: quota)
    }

    // MARK: - One-shot

    /// Resposta em texto puro.
    func respond(
        to prompt: String,
        instructions: String? = nil,
        task: AgentTask = AgentTask()
    ) async throws(AgentError) -> String {
        let status = status()
        let route = try Self.resolveRoute(task: task, status: status)
        do {
            return try await perform(prompt: prompt, instructions: instructions, task: task, route: route)
        } catch {
            // Quota do PCC estourou no meio do caminho: uma tentativa
            // on-device antes de desistir, para o chamador não ver um erro
            // de classe diferente da rota que pediu.
            if case .quotaExhausted = error, route == .privateCloud, status.onDevice.isAvailable {
                return try await perform(prompt: prompt, instructions: instructions, task: task, route: .onDevice)
            }
            throw error
        }
    }

    /// Resposta estruturada via guided generation (@Generable).
    func respond<Content: Generable & Sendable>(
        to prompt: String,
        generating type: Content.Type,
        instructions: String? = nil,
        task: AgentTask = AgentTask()
    ) async throws(AgentError) -> Content {
        let status = status()
        let route = try Self.resolveRoute(task: task, status: status)
        do {
            return try await perform(prompt: prompt, generating: type, instructions: instructions, task: task, route: route)
        } catch {
            if case .quotaExhausted = error, route == .privateCloud, status.onDevice.isAvailable {
                return try await perform(prompt: prompt, generating: type, instructions: instructions, task: task, route: .onDevice)
            }
            throw error
        }
    }

    // MARK: - Multi-turn (costura para o chat futuro)

    /// Cria uma sessão multi-turn com transcript e tools. Nenhuma UI usa
    /// isso ainda; é a fundação do assistente.
    @MainActor
    func makeSession(
        task: AgentTask = AgentTask(),
        tools: [any Tool] = [],
        instructions: String? = nil
    ) throws(AgentError) -> AgentChatSession {
        let route = try Self.resolveRoute(task: task, status: status())
        return AgentChatSession(session: Self.makeLanguageModelSession(
            route: route,
            tools: tools,
            instructions: instructions
        ))
    }

    // MARK: - Execução

    private func perform(
        prompt: String,
        instructions: String?,
        task: AgentTask,
        route: AgentRoutingPolicy.Route
    ) async throws(AgentError) -> String {
        let session = Self.makeLanguageModelSession(route: route, tools: [], instructions: instructions)
        do {
            switch route {
            case .onDevice:
                return try await session.respond(to: prompt).content
            case .privateCloud:
                return try await session.respond(
                    to: prompt,
                    options: GenerationOptions(),
                    contextOptions: ContextOptions(reasoningLevel: Self.reasoningLevel(for: task))
                ).content
            }
        } catch {
            throw Self.mapError(error)
        }
    }

    private func perform<Content: Generable & Sendable>(
        prompt: String,
        generating type: Content.Type,
        instructions: String?,
        task: AgentTask,
        route: AgentRoutingPolicy.Route
    ) async throws(AgentError) -> Content {
        let session = Self.makeLanguageModelSession(route: route, tools: [], instructions: instructions)
        do {
            switch route {
            case .onDevice:
                return try await session.respond(to: prompt, generating: type).content
            case .privateCloud:
                return try await session.respond(
                    to: prompt,
                    generating: type,
                    options: GenerationOptions(),
                    contextOptions: ContextOptions(reasoningLevel: Self.reasoningLevel(for: task))
                ).content
            }
        } catch {
            throw Self.mapError(error)
        }
    }

    private static func resolveRoute(
        task: AgentTask,
        status: AgentStatus
    ) throws(AgentError) -> AgentRoutingPolicy.Route {
        guard let route = AgentRoutingPolicy.route(
            task: task,
            onDeviceAvailable: status.onDevice.isAvailable,
            privateCloudAvailable: status.privateCloud.isAvailable,
            quotaLevel: status.quota?.level
        ) else {
            throw AgentError.modelsUnavailable
        }
        return route
    }

    private static func makeLanguageModelSession(
        route: AgentRoutingPolicy.Route,
        tools: [any Tool],
        instructions: String?
    ) -> LanguageModelSession {
        switch route {
        case .onDevice:
            LanguageModelSession(model: SystemLanguageModel.default, tools: tools, instructions: instructions)
        case .privateCloud:
            LanguageModelSession(model: PrivateCloudComputeLanguageModel(), tools: tools, instructions: instructions)
        }
    }

    private static func reasoningLevel(for task: AgentTask) -> ContextOptions.ReasoningLevel {
        switch task.reasoning {
        case .light: .light
        case .moderate: .moderate
        case .deep: .deep
        }
    }

    // MARK: - Mapeamento framework → domínio

    private static func state(of availability: SystemLanguageModel.Availability) -> AgentStatus.ModelState {
        switch availability {
        case .available:
            .available
        case .unavailable(let reason):
            switch reason {
            case .appleIntelligenceNotEnabled: .unavailable(.appleIntelligenceNotEnabled)
            case .deviceNotEligible: .unavailable(.deviceNotEligible)
            case .modelNotReady: .unavailable(.modelNotReady)
            @unknown default: .unavailable(.unknown)
            }
        }
    }

    private static func state(of availability: PrivateCloudComputeLanguageModel.Availability) -> AgentStatus.ModelState {
        switch availability {
        case .available:
            .available
        case .unavailable(let reason):
            switch reason {
            case .deviceNotEligible: .unavailable(.deviceNotEligible)
            case .systemNotReady: .unavailable(.systemNotReady)
            @unknown default: .unavailable(.unknown)
            }
        }
    }

    private static func quota(from usage: PrivateCloudComputeLanguageModel.QuotaUsage) -> AgentStatus.Quota {
        let level: AgentStatus.Quota.Level
        if usage.isLimitReached {
            level = .limitReached
        } else if case .belowLimit(let info) = usage.status, info.isApproachingLimit {
            level = .approachingLimit
        } else {
            level = .belowLimit
        }
        return AgentStatus.Quota(
            level: level,
            resetDate: usage.resetDate,
            canRequestIncrease: usage.limitIncreaseSuggestion != nil
        )
    }

    static func mapError(_ error: any Error) -> AgentError {
        if let pccError = error as? PrivateCloudComputeLanguageModel.Error {
            switch pccError {
            case .quotaLimitReached:
                return .quotaExhausted(resetDate: nil)
            default:
                return .generationFailed(description: String(describing: pccError))
            }
        }
        if let modelError = error as? LanguageModelError {
            switch modelError {
            case .guardrailViolation:
                return .guardrailViolation
            case .refusal:
                return .refused
            case .contextSizeExceeded:
                return .contextWindowExceeded
            case .unsupportedLanguageOrLocale:
                return .unsupportedLanguage
            default:
                return .generationFailed(description: String(describing: modelError))
            }
        }
        return .generationFailed(description: String(describing: error))
    }
}
