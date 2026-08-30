//
//  AgentRoutingPolicy.swift
//  CinemaTV
//
//  Decisão pura de qual modelo atende uma tarefa. Regras:
//  - .light/.standard → on-device; PCC só como fallback e sem gastar quota
//    de quem já está perto do limite.
//  - .hard → PCC quando permitido/disponível e com quota; senão on-device.
//  - nil → nenhum modelo utilizável; o chamador degrada sem IA (regra dura:
//    toda feature cliente precisa de fallback sem IA).
//

import Foundation

enum AgentRoutingPolicy {
    enum Route: Sendable, Equatable {
        case onDevice
        case privateCloud
    }

    static func route(
        task: AgentTask,
        onDeviceAvailable: Bool,
        privateCloudAvailable: Bool,
        quotaLevel: AgentStatus.Quota.Level?
    ) -> Route? {
        let privateCloudUsable = task.allowsPrivateCloud
            && privateCloudAvailable
            && quotaLevel != .limitReached

        switch task.complexity {
        case .hard:
            if privateCloudUsable { return .privateCloud }
            return onDeviceAvailable ? .onDevice : nil

        case .light, .standard:
            if onDeviceAvailable { return .onDevice }
            // Fallback ao PCC: perto do limite diário, a quota fica
            // reservada para tarefas .hard.
            if privateCloudUsable && quotaLevel != .approachingLimit {
                return .privateCloud
            }
            return nil
        }
    }
}
