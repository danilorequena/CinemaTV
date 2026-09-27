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

/// Disponibilidade regional do TMDB/JustWatch para filmes e séries.
/// O link abre a página do TMDB, que contém os links efetivos dos serviços.
public struct WatchProvidersSection: View {
    private let providers: RegionProviders?
    private let regionCode: String

    public init(providers: RegionProviders?, regionCode: String) {
        self.providers = providers
        self.regionCode = regionCode
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.md) {
            SectionHeader("Where to Watch")

            Text("Availability in \(TMDBRegion.localizedName(for: regionCode)) (\(regionCode))")
                .font(.dsCaption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DSSpacing.lg)

            if let providers, providers.hasOffers {
                ProviderRow(title: "Subscription", providers: providers.flatrate ?? [])
                ProviderRow(title: "Free", providers: providers.free ?? [])
                ProviderRow(title: "With ads", providers: providers.ads ?? [])
                ProviderRow(title: "Rent", providers: providers.rent ?? [])
                ProviderRow(title: "Buy", providers: providers.buy ?? [])
            } else {
                Text("No watch options found for this region.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DSSpacing.lg)
            }

            if let url = providers?.watchPageURL {
                Link(destination: url) {
                    Label("See watch options on TMDB", systemImage: "arrow.up.right")
                }
                .font(.dsCaption)
                .padding(.horizontal, DSSpacing.lg)
                .accessibilityHint("Opens TMDB's page with links to the services")
            }

            Text("Availability data provided by JustWatch")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.horizontal, DSSpacing.lg)
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
