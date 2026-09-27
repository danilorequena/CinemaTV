#if DEBUG && os(iOS)
import SwiftUI

/// A cover can be auditioned freely; only the confirmation updates the box.
struct CollectorCoverPicker: View {
    let title: String
    @Binding var selection: BoxesArtworkKind

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var thumbnailWidth = 84.0
    @State private var draft: CoverChoice

    init(title: String, selection: Binding<BoxesArtworkKind>) {
        self.title = title
        _selection = selection
        _draft = State(initialValue: CoverChoice(kind: selection.wrappedValue))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    introduction
                        .padding(.horizontal, 24)

                    liveCover

                    choices
                }
                .padding(.top, 20)
                .padding(.bottom, 28)
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
            }
            .background(BoxesDirection.collector.background)
            .navigationTitle("Escolher capa")
            .toolbarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar", role: .cancel) { dismiss() }
                        .foregroundStyle(.primary)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                confirmation
            }
        }
        .preferredColorScheme(.dark)
        .tint(DSColor.accent)
    }

    private var coverTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Meu novo box" : trimmed
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Dê uma identidade\nà sua edição.")
                .font(.system(.title2, design: .serif, weight: .semibold))
                .fixedSize(horizontal: false, vertical: true)
            Text("Escolha a atmosfera das histórias que você reuniu.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var liveCover: some View {
        VStack(spacing: 20) {
            ZStack {
                Ellipse()
                    .fill(DSColor.accent.opacity(0.08))
                    .frame(width: 256, height: 220)
                    .blur(radius: 42)

                BoxesCover(
                    title: coverTitle.uppercased(),
                    subtitle: "UMA EDIÇÃO SUA",
                    kind: draft.kind
                )
                .frame(width: 150, height: 198)
                .rotation3DEffect(.degrees(-12), axis: (x: 0, y: 1, z: 0))
                .rotationEffect(.degrees(-3))
                .shadow(color: .black.opacity(0.8), radius: 20, x: 12, y: 16)
                .id(draft)
                .transition(.opacity)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 224)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(LinearGradient(
                        colors: [.clear, .white.opacity(0.18), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .frame(height: 1)
                    .padding(.horizontal, 24)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Prévia da capa \(draft.rawValue) para \(coverTitle)")

            VStack(spacing: 5) {
                Text(draft.rawValue)
                    .font(.headline)
                Text(draft.detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
            .accessibilityElement(children: .combine)
        }
    }

    private var choices: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CAPAS DA COLEÇÃO")
                .font(.system(.caption2, design: .monospaced, weight: .semibold))
                .tracking(1.5)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 14) {
                    ForEach(CoverChoice.allCases) { choice in
                        coverButton(choice)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 3)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func coverButton(_ choice: CoverChoice) -> some View {
        let isSelected = draft == choice

        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.22)) {
                draft = choice
            }
        } label: {
            VStack(spacing: 10) {
                BoxesArtwork(kind: choice.kind)
                    .aspectRatio(0.76, contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 6))
                    .padding(4)
                    .overlay {
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelected ? DSColor.accent : .white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.black, DSColor.accent)
                                .padding(9)
                        }
                    }

                Text(choice.rawValue)
                    .font(.caption.weight(isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? DSColor.accent : .white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(width: thumbnailWidth)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Capa \(choice.rawValue)")
        .accessibilityHint(choice.detail)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var confirmation: some View {
        Button {
            selection = draft.kind
            dismiss()
        } label: {
            Text("Usar capa")
                .font(.headline)
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(DSColor.accent, in: .rect(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: 640)
        .frame(maxWidth: .infinity)
        .background(BoxesDirection.collector.background)
    }

    private enum CoverChoice: String, CaseIterable, Identifiable {
        case cosmic = "Cósmica"
        case minimal = "Minimalista"
        case mystery = "Mistério"
        case comfort = "Aconchego"

        var id: Self { self }

        init(kind: BoxesArtworkKind) {
            self = switch kind {
            case .space: .cosmic
            case .arrival: .minimal
            case .dark: .mystery
            case .office: .comfort
            }
        }

        var kind: BoxesArtworkKind {
            switch self {
            case .cosmic: .space
            case .minimal: .arrival
            case .mystery: .dark
            case .comfort: .office
            }
        }

        var detail: String {
            switch self {
            case .cosmic: "Para histórias que atravessam o tempo."
            case .minimal: "O essencial também impressiona."
            case .mystery: "Cada história guarda um segredo."
            case .comfort: "Um lugar para voltar sempre."
            }
        }
    }
}

#Preview("Colecionador · Escolher capa") {
    @Previewable @State var selection: BoxesArtworkKind = .space
    CollectorCoverPicker(title: "Além do tempo", selection: $selection)
}
#endif
