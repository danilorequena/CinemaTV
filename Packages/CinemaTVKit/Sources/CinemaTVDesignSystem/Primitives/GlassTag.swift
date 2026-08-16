//
//  GlassTag.swift
//  CinemaTVKit
//
//  Capsule Liquid Glass para metadados flutuando sobre imagem (gêneros,
//  "Watched", ano). Substitui o WatchedTagView legado.
//  Regra: vários GlassTags juntos devem estar num GlassEffectContainer
//  (InfoPillRow já faz isso).
//

import SwiftUI

public struct GlassTag: View {
    private let text: LocalizedStringKey
    private let systemImage: String?
    private let tint: Color?
    private let unionID: String?
    private let unionNamespace: Namespace.ID?

    /// unionID/unionNamespace: tags irmãs com o mesmo par fundem o glass
    /// numa superfície contínua (glassEffectUnion).
    public init(
        _ text: LocalizedStringKey,
        systemImage: String? = nil,
        tint: Color? = nil,
        unionID: String? = nil,
        unionNamespace: Namespace.ID? = nil
    ) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
        self.unionID = unionID
        self.unionNamespace = unionNamespace
    }

    public var body: some View {
        HStack(spacing: DSSpacing.xs) {
            if let systemImage {
                // Decorativo: sem isso o VoiceOver lia o nome do símbolo
                // ("calendar, 1999") junto com o texto da tag.
                Image(systemName: systemImage)
                    .accessibilityHidden(true)
            }
            Text(text)
        }
        .font(.dsCaption)
        .padding(.horizontal, DSSpacing.md)
        .padding(.vertical, DSSpacing.xs + 2)
        .glassEffect(tint.map { .regular.tint($0.opacity(0.6)) } ?? .regular, in: .capsule)
        .modifier(GlassUnionModifier(id: unionID, namespace: unionNamespace))
    }
}

/// glassEffectUnion só quando id e namespace existem.
private struct GlassUnionModifier: ViewModifier {
    let id: String?
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let id, let namespace {
            content.glassEffectUnion(id: id, namespace: namespace)
        } else {
            content
        }
    }
}

/// Linha de GlassTags dentro de um único GlassEffectContainer.
public struct InfoPillRow: View {
    public struct Pill: Identifiable {
        public let id: String
        public let text: LocalizedStringKey
        public let systemImage: String?

        public init(id: String, text: LocalizedStringKey, systemImage: String? = nil) {
            self.id = id
            self.text = text
            self.systemImage = systemImage
        }
    }

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Namespace private var unionNamespace

    private let pills: [Pill]
    /// true: quebra linha quando a largura acaba (em vez de estourar) —
    /// para pills ao lado de elementos fixos como o RatingGauge.
    private let wraps: Bool

    public init(pills: [Pill], wraps: Bool = false) {
        self.pills = pills
        self.wraps = wraps
    }

    public var body: some View {
        GlassEffectContainer(spacing: DSSpacing.sm) {
            // Em tamanhos de acessibilidade a linha de pills estoura a
            // largura da tela; empilha na vertical.
            let layout = dynamicTypeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: DSSpacing.sm))
                : (wraps
                    ? AnyLayout(DSFlowLayout(spacing: DSSpacing.sm))
                    : AnyLayout(HStackLayout(spacing: DSSpacing.sm)))
            layout {
                ForEach(pills) { pill in
                    // Sem glassEffectUnion: cada metadado é uma pill própria
                    // (a união fundia tudo num blob, pior com wrapping).
                    GlassTag(pill.text, systemImage: pill.systemImage)
                }
            }
        }
    }
}

#Preview("Wrapping ao lado do gauge", traits: .sizeThatFitsLayout) {
    HStack(alignment: .top, spacing: DSSpacing.md) {
        InfoPillRow(
            pills: [
                .init(id: "year", text: "2020", systemImage: "calendar"),
                .init(id: "seasons", text: "4 Seasons", systemImage: "square.stack"),
                .init(id: "episodes", text: "44 episodes", systemImage: "play.tv"),
                .init(id: "g1", text: "Comedy"),
                .init(id: "g2", text: "Drama")
            ],
            wraps: true
        )
        Spacer(minLength: DSSpacing.md)
        RatingGauge(value: 8.4)
            .frame(width: 48, height: 48)
    }
    .padding()
}

#Preview("Tags", traits: .sizeThatFitsLayout) {
    ZStack {
        LinearGradient(colors: [.purple, .black], startPoint: .top, endPoint: .bottom)
        VStack(spacing: DSSpacing.lg) {
            GlassTag("Watched", systemImage: "checkmark", tint: .green)
            InfoPillRow(pills: [
                .init(id: "year", text: "1999", systemImage: "calendar"),
                .init(id: "runtime", text: "2h 16m", systemImage: "clock"),
                .init(id: "genre", text: "Sci-Fi")
            ])
        }
        .padding()
    }
    .frame(height: 200)
}
