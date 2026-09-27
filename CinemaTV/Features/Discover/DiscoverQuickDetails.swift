import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct DiscoverQuickDetails: View {
    @Environment(\.dismiss) private var dismiss
    let item: MediaItem
    let onFullDetails: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DSSpacing.lg) {
                    Text(verbatim: item.title)
                        .font(.title.bold())
                    HStack {
                        if let year = item.releaseYear { Text(verbatim: year) }
                        Label(item.voteAverage.formatted(.number.precision(.fractionLength(1))), systemImage: "star.fill")
                    }
                    .foregroundStyle(.secondary)
                    Text(verbatim: item.overview)
                        .font(.body)
                    Button("Full details", systemImage: "arrow.up.right") {
                        onFullDetails()
                    }
                    .buttonStyle(.glassProminent)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DSSpacing.lg)
            }
            .navigationTitle("Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close", systemImage: "xmark") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
