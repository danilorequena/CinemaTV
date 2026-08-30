//
//  AppleIntelligenceSection.swift
//  CinemaTV
//
//  Seção de Ajustes com o estado dos modelos (on-device e Private Cloud
//  Compute) e a quota diária do PCC. Segundo — e último — import de
//  FoundationModels no app: o objeto vivo de limitIncreaseSuggestion
//  (com .show()) não cabe no snapshot AgentStatus.
//

import SwiftUI
import FoundationModels
import CinemaTVDesignSystem

@MainActor
@Observable
final class AppleIntelligenceStatusModel {
    private(set) var status: AgentStatus?
    /// Objeto do framework que apresenta o fluxo de upgrade (iCloud+).
    @ObservationIgnored
    private var limitIncreaseSuggestion: PrivateCloudComputeLanguageModel.QuotaUsage.LimitIncreaseSuggestion?

    func refresh(engine: AgentEngine) {
        let status = engine.status()
        self.status = status
        limitIncreaseSuggestion = status.privateCloud.isAvailable
            ? PrivateCloudComputeLanguageModel().quotaUsage.limitIncreaseSuggestion
            : nil
    }

    func showLimitIncreaseOptions() {
        limitIncreaseSuggestion?.show()
    }
}

struct AppleIntelligenceSection: View {
    @Environment(\.agentEngine) private var engine
    @State private var model = AppleIntelligenceStatusModel()

    var body: some View {
        Section {
            if let status = model.status {
                LabeledContent {
                    Text(stateLabel(status.onDevice))
                        .foregroundStyle(.secondary)
                } label: {
                    Text("On-device model")
                }
                LabeledContent {
                    Text(stateLabel(status.privateCloud))
                        .foregroundStyle(.secondary)
                } label: {
                    Text("Private Cloud Compute")
                }
                if let quota = status.quota {
                    quotaRow(quota)
                    if quota.canRequestIncrease {
                        Button("Request Higher Limit") {
                            model.showLimitIncreaseOptions()
                        }
                        .tint(DSColor.accent)
                    }
                }
            }
        } header: {
            Text("Apple Intelligence")
                .onAppear { model.refresh(engine: engine) }
        } footer: {
            Text("Powers features like movie soundtracks. Private Cloud Compute keeps requests private, and its daily limit resets every day.")
        }
    }

    private func quotaRow(_ quota: AgentStatus.Quota) -> some View {
        LabeledContent {
            switch quota.level {
            case .belowLimit:
                Text("Below limit")
                    .foregroundStyle(.secondary)
            case .approachingLimit:
                Text("Approaching limit")
                    .foregroundStyle(.orange)
            case .limitReached:
                if let reset = quota.resetDate {
                    Text("Reached — resets \(reset, format: .relative(presentation: .named))")
                        .foregroundStyle(.red)
                } else {
                    Text("Reached")
                        .foregroundStyle(.red)
                }
            }
        } label: {
            Text("Daily usage")
        }
    }

    private func stateLabel(_ state: AgentStatus.ModelState) -> LocalizedStringKey {
        switch state {
        case .available:
            "Available"
        case .unavailable(.appleIntelligenceNotEnabled):
            "Apple Intelligence is off"
        case .unavailable(.deviceNotEligible):
            "Device not supported"
        case .unavailable(.modelNotReady):
            "Model not ready"
        case .unavailable(.systemNotReady):
            "Not ready"
        case .unavailable(.unknown):
            "Unavailable"
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            AppleIntelligenceSection()
        }
    }
}
