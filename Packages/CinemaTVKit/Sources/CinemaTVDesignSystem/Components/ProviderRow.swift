//
//  ProviderRow.swift
//  CinemaTVKit
//
//  Rail de provedores de streaming — substitui ProvidersView e
//  WatchProvidersView.
//

import SwiftUI
import CinemaTVCore

public struct ProviderRow: View {
    private let title: LocalizedStringKey
    private let providers: [WatchProvider]
    private let onTap: (() -> Void)?

    public init(title: LocalizedStringKey, providers: [WatchProvider], onTap: (() -> Void)? = nil) {
        self.title = title
        self.providers = providers
        self.onTap = onTap
    }

    public var body: some View {
        if !providers.isEmpty {
            VStack(alignment: .leading, spacing: DSSpacing.sm) {
                Text(title)
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)
                ScrollView(.horizontal) {
                    HStack(spacing: DSSpacing.sm) {
                        ForEach(providers) { provider in
                            providerLogo(provider)
                        }
                    }
                    .padding(.horizontal, DSSpacing.lg)
                }
                .scrollIndicators(.hidden)
            }
        }
    }

    @ViewBuilder
    private func providerLogo(_ provider: WatchProvider) -> some View {
        let logo = PosterImage(path: provider.logoPath, kind: .profile)
            .frame(width: 44, height: 44)
            .clipShape(.rect(cornerRadius: DSRadius.poster))
            .accessibilityLabel(Text(verbatim: provider.providerName))

        if let onTap {
            Button(action: onTap) { logo }
                .buttonStyle(.plain)
        } else {
            logo
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    ProviderRow(
        title: "Stream",
        providers: [
            WatchProvider(providerId: 8, providerName: "Netflix", logoPath: nil),
            WatchProvider(providerId: 337, providerName: "Disney+", logoPath: nil)
        ],
        onTap: {}
    )
    .padding(.vertical)
}
