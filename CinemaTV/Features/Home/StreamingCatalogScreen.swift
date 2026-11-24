import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct StreamingCatalogScreen: View {
    private enum PaginationRequest: Equatable {
        case automatic(lastItemID: Int)
        case retry(UUID)
    }

    let providerName: String
    let query: StreamingAvailabilityQuery

    @Environment(\.tmdbClient) private var client
    @ScaledMetric(relativeTo: .subheadline) private var minimumCardWidth: CGFloat = 110
    @State private var model: StreamingCatalogModel
    @State private var paginationRequest: PaginationRequest?

    init(
        providerName: String,
        query: StreamingAvailabilityQuery,
        firstPageItems: [MediaItem],
        nextPage: Int?
    ) {
        self.providerName = providerName
        self.query = query
        _model = State(initialValue: StreamingCatalogModel(firstPageItems: firstPageItems, nextPage: nextPage))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DSSpacing.lg) {
                Text("Availability data provided by JustWatch")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)

                grid
                paginationFooter
            }
            .padding(DSSpacing.lg)
        }
        .accessibilityIdentifier("streaming.catalog")
        .navigationTitle(Text(verbatim: providerName))
        .navigationBarTitleDisplayMode(.inline)
        .task(id: paginationRequest) {
            switch paginationRequest {
            case .automatic(let lastItemID) where lastItemID == model.items.last?.id:
                await model.loadMore(client: client, query: query)
            case .retry:
                await model.retry(client: client, query: query)
            default:
                break
            }
        }
    }

    private var grid: some View {
        let columns = [GridItem(.adaptive(minimum: minimumCardWidth), spacing: DSSpacing.md)]
        let zoomScope = "streaming-catalog-\(query.kind)-\(query.providerID)"

        return LazyVGrid(columns: columns, spacing: DSSpacing.lg) {
            ForEach(model.items) { item in
                let selection = MediaSelection(item: item, scope: zoomScope)
                NavigationLink(value: selection) {
                    MediaCard(item: item, zoomSourceID: selection.sourceID)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("streaming.catalog.item.\(item.id)")
                .onScrollVisibilityChange(threshold: 0.05) { isVisible in
                    guard isVisible, item.id == model.items.last?.id, model.nextPage != nil,
                          !model.isLoadingMore, model.errorMessage == nil else { return }
                    paginationRequest = .automatic(lastItemID: item.id)
                }
            }
        }
    }

    @ViewBuilder
    private var paginationFooter: some View {
        if model.isLoadingMore {
            ProgressView("Loading titles")
                .frame(maxWidth: .infinity)
        } else if model.errorMessage != nil {
            VStack(spacing: DSSpacing.sm) {
                Text("Couldn’t load more titles.")
                    .font(.dsCaption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try Again", systemImage: "arrow.clockwise") {
                    paginationRequest = .retry(UUID())
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("streaming.catalog.retry")
            }
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    NavigationStack {
        StreamingCatalogScreen(
            providerName: "Preview Service",
            query: StreamingAvailabilityQuery(kind: .movie, region: "US", providerID: 8, today: "2026-01-01"),
            firstPageItems: [.dsPreview],
            nextPage: nil
        )
    }
}
