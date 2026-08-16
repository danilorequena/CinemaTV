//
//  SectionHeader.swift
//  CinemaTVKit
//
//  Cabeçalho padrão de seção; substitui os headers duplicados dentro de
//  cada carousel legado.
//

import SwiftUI

public struct SectionHeader: View {
    private let title: Text
    private let onSeeAll: (() -> Void)?

    public init(_ title: LocalizedStringKey, onSeeAll: (() -> Void)? = nil) {
        // LocalizedStringKey vindo do app resolve no Bundle.main via Text.
        self.title = Text(title)
        self.onSeeAll = onSeeAll
    }

    /// Para chamadas internas do package, que precisam resolver a string no
    /// bundle do módulo (ex.: `Text("Cast", bundle: .module)`).
    public init(text: Text, onSeeAll: (() -> Void)? = nil) {
        self.title = text
        self.onSeeAll = onSeeAll
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            title
                .font(.dsSectionTitle)
                // O trait fica só no título: no HStack inteiro, o botão
                // "See All" também era anunciado como header.
                .accessibilityAddTraits(.isHeader)
            Spacer()
            if let onSeeAll {
                Button(action: onSeeAll) {
                    // HStack manual: Label põe o ícone à esquerda, e aqui o
                    // chevron precisa vir depois do texto.
                    HStack(spacing: DSSpacing.xs) {
                        Text("See All", bundle: .module)
                        Image(systemName: "chevron.right")
                            .font(.caption2.weight(.semibold))
                            .accessibilityHidden(true)
                    }
                    .font(.dsCaption)
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, DSSpacing.lg)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    VStack(spacing: DSSpacing.lg) {
        SectionHeader("Now Playing", onSeeAll: {})
        SectionHeader("Cast")
    }
    .padding(.vertical)
}
