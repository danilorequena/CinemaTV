//
//  AgentRoutingPolicyTests.swift
//  CinemaTVTests
//
//  A política de roteamento é pura de propósito: aqui cobrimos a matriz
//  de decisão sem tocar no FoundationModels.
//

import Testing
@testable import CinemaTV

struct AgentRoutingPolicyTests {
    @Test func standardPrefersOnDevice() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .standard),
            onDeviceAvailable: true,
            privateCloudAvailable: true,
            quotaLevel: .belowLimit
        )
        #expect(route == .onDevice)
    }

    @Test func hardPrefersPrivateCloud() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .hard),
            onDeviceAvailable: true,
            privateCloudAvailable: true,
            quotaLevel: .belowLimit
        )
        #expect(route == .privateCloud)
    }

    @Test func hardFallsBackOnDeviceWhenQuotaReached() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .hard),
            onDeviceAvailable: true,
            privateCloudAvailable: true,
            quotaLevel: .limitReached
        )
        #expect(route == .onDevice)
    }

    @Test func hardStillUsesPrivateCloudWhenApproachingLimit() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .hard),
            onDeviceAvailable: true,
            privateCloudAvailable: true,
            quotaLevel: .approachingLimit
        )
        #expect(route == .privateCloud)
    }

    @Test func standardFallsBackToPrivateCloudWhenOnDeviceUnavailable() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .standard),
            onDeviceAvailable: false,
            privateCloudAvailable: true,
            quotaLevel: .belowLimit
        )
        #expect(route == .privateCloud)
    }

    @Test func standardReservesQuotaWhenApproachingLimit() {
        // Perto do limite diário, tarefas comuns não gastam PCC.
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .standard),
            onDeviceAvailable: false,
            privateCloudAvailable: true,
            quotaLevel: .approachingLimit
        )
        #expect(route == nil)
    }

    @Test func disallowedPrivateCloudNeverRoutesToIt() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .hard, allowsPrivateCloud: false),
            onDeviceAvailable: false,
            privateCloudAvailable: true,
            quotaLevel: .belowLimit
        )
        #expect(route == nil)
    }

    @Test func nothingAvailableReturnsNil() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(),
            onDeviceAvailable: false,
            privateCloudAvailable: false,
            quotaLevel: nil
        )
        #expect(route == nil)
    }

    @Test func lightTaskNeverEscalatesBeyondFallbackRules() {
        let route = AgentRoutingPolicy.route(
            task: AgentTask(complexity: .light),
            onDeviceAvailable: true,
            privateCloudAvailable: true,
            quotaLevel: .belowLimit
        )
        #expect(route == .onDevice)
    }
}
