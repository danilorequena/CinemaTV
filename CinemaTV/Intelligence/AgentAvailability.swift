//
//  AgentAvailability.swift
//  CinemaTV
//
//  Snapshot livre de framework do estado dos modelos (on-device e Private
//  Cloud Compute). Settings e testes consomem isto sem importar
//  FoundationModels; o AgentEngine faz o mapeamento.
//

import Foundation

struct AgentStatus: Sendable, Equatable {
    enum UnavailableReason: Sendable, Equatable {
        case appleIntelligenceNotEnabled
        case deviceNotEligible
        case modelNotReady
        case systemNotReady
        case unknown
    }

    enum ModelState: Sendable, Equatable {
        case available
        case unavailable(UnavailableReason)

        var isAvailable: Bool { self == .available }
    }

    struct Quota: Sendable, Equatable {
        enum Level: Sendable, Equatable {
            case belowLimit
            case approachingLimit
            case limitReached
        }

        var level: Level
        var resetDate: Date?
        var canRequestIncrease: Bool
    }

    var onDevice: ModelState
    var privateCloud: ModelState
    /// nil quando o PCC está indisponível (sem quota para reportar).
    var quota: Quota?
}
