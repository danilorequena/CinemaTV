//
//  GlassSegmentedPicker.swift
//  CinemaTVDesignSystem
//
//  Substituto glass do Picker(.segmented): pills num GlassEffectContainer
//  onde a seleção morfa de um segmento para o outro via glassEffectID.
//

import SwiftUI

public struct GlassSegmentedPicker<Value: Hashable>: View {
    public struct Segment {
        let value: Value
        // Text (não LocalizedStringKey): a string resolve no catálogo do
        // módulo que criou o Text, não no do DS.
        let label: Text

        public init(_ value: Value, label: Text) {
            self.value = value
            self.label = label
        }
    }

    @Binding private var selection: Value
    private let segments: [Segment]

    @Namespace private var namespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    public init(selection: Binding<Value>, segments: [Segment]) {
        self._selection = selection
        self.segments = segments
    }

    public var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: DSSpacing.xs))
            : AnyLayout(HStackLayout(spacing: DSSpacing.xs))

        GlassEffectContainer(spacing: DSSpacing.xs) {
            layout {
                ForEach(segments, id: \.value) { segment in
                    segmentButton(segment)
                }
            }
        }
    }

    private func segmentButton(_ segment: Segment) -> some View {
        let isSelected = segment.value == selection

        return Button {
            withAnimation(DSMotion.respecting(reduceMotion, DSMotion.snappy)) {
                selection = segment.value
            }
        } label: {
            segment.label
                .font(.subheadline.weight(.semibold))
                // Pill não hifeniza: encolhe um pouco antes de quebrar linha.
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .padding(.vertical, DSSpacing.sm)
                .padding(.horizontal, DSSpacing.lg)
                .frame(maxWidth: .infinity)
                .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .modifier(SelectedGlass(isSelected: isSelected, namespace: namespace))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// Só o segmento selecionado carrega glass; como o glassEffectID é o mesmo,
/// a pill morfa de posição quando a seleção muda.
private struct SelectedGlass: ViewModifier {
    let isSelected: Bool
    let namespace: Namespace.ID

    func body(content: Content) -> some View {
        if isSelected {
            content
                .glassEffect(.regular.tint(DSColor.accent.opacity(0.6)).interactive(), in: .capsule)
                .glassEffectID("selection", in: namespace)
        } else {
            content
        }
    }
}

#Preview("GlassSegmentedPicker") {
    @Previewable @State var selection = 0

    VStack(spacing: DSSpacing.xl) {
        GlassSegmentedPicker(
            selection: $selection,
            segments: [
                .init(0, label: Text(verbatim: "Movies")),
                .init(1, label: Text(verbatim: "TV Shows"))
            ]
        )
        .padding(.horizontal, DSSpacing.lg)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
        LinearGradient(colors: [.indigo, .black], startPoint: .top, endPoint: .bottom)
    )
}
