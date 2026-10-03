import CinemaTVCore
import CinemaTVDesignSystem
import SwiftUI

struct LifetimeShareSheet: View {
    @Environment(\.dismiss) private var dismiss
    let summary: LifetimeShareSummary
    @State private var image: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 18))
                            .accessibilityLabel("Preview of your Lifetime card")
                        ShareLink(
                            item: Image(uiImage: image),
                            preview: SharePreview(String(localized: "Your Story"), image: Image(uiImage: image))
                        ) {
                            Label("Share Card", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.glassProminent)
                        .accessibilityIdentifier("lifetime.share.confirm")
                    } else {
                        ProgressView("Preparing your card")
                    }
                }
                .padding(DSSpacing.lg)
            }
            .navigationTitle("Share Your Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .task {
                let renderer = ImageRenderer(content: LifetimeShareCard(summary: summary))
                renderer.scale = 3
                renderer.isOpaque = true
                image = renderer.uiImage
            }
        }
    }
}

private struct LifetimeShareCard: View {
    let summary: LifetimeShareSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CINEMATV / LIFETIME")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .tracking(2)
                .foregroundStyle(DSColor.accent)
            Spacer()
            Text("Your Story")
                .font(.system(size: 40, weight: .bold, design: .serif))
                .foregroundStyle(.white)
            Text(verbatim: LifetimeDurationLabel.primary(summary.totalKnownMinutes))
                .font(.system(size: 55, weight: .heavy, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .foregroundStyle(DSColor.accent)
                .padding(.top, 18)
            Text("Duration of titles marked as watched")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.78))
            if summary.totalKnownMinutes >= 24 * 60 {
                Text(verbatim: LifetimeDurationLabel.exactHours(summary.totalKnownMinutes))
                    .font(.system(size: 12))
                    .foregroundStyle(.white.opacity(0.65))
            }
            if summary.totalKnownMinutes >= 4 * 7 * 24 * 60 {
                Text("One month means four weeks here.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.65))
            }
            HStack(spacing: 24) {
                count(summary.movieCount, title: "MOVIES")
                count(summary.episodeCount, title: "EPISODES")
            }
            .padding(.top, 30)
            if let topGenre = summary.topGenre {
                Text("TOP GENRE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.62))
                    .padding(.top, 30)
                Text(verbatim: topGenre)
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text("Runtime known for \(summary.knownDurationCount) of \(summary.totalItemCount) titles")
                .font(.system(size: 11))
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(30)
        .frame(width: 360, height: 450, alignment: .leading)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14))
    }

    private func count(_ value: Int, title: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value.formatted())
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.65))
        }
    }
}

enum LifetimeDurationLabel {
    static func primary(_ minutes: Int) -> String {
        LifetimeDurationBreakdown.components(for: minutes).map { part in
            let number = part.value.formatted()
            switch part.unit {
            case .month: return "\(number) \(String(localized: part.value == 1 ? "month" : "months"))"
            case .week: return "\(number) \(String(localized: part.value == 1 ? "week" : "weeks"))"
            case .day: return "\(number) \(String(localized: part.value == 1 ? "day" : "days"))"
            case .hour: return "\(number)h"
            case .minute: return "\(number)min"
            }
        }.joined(separator: " · ")
    }

    static func exactHours(_ minutes: Int) -> String {
        let safeMinutes = max(0, minutes)
        return "\((safeMinutes / 60).formatted())h \((safeMinutes % 60).formatted())min"
    }
}
