import SwiftUI
import CinemaTVCore
import CinemaTVDesignSystem

struct StreamingServicePicker: View {
    private enum CatalogState {
        case loading
        case loaded(region: String, providers: [WatchProvider])
        case failed(region: String)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.tmdbClient) private var client
    @AppStorage(TMDBRegion.overrideKey, store: TMDBRegion.store) private var regionOverride = ""
    @AppStorage(StreamingServicePreferences.storageKey) private var preferencesData = Data()
    @State private var catalog: CatalogState = .loading
    @State private var selection: Set<Int> = []
    @State private var searchText = ""
    @State private var retryID = 0

    let allowsSkipping: Bool

    init(allowsSkipping: Bool = false) {
        self.allowsSkipping = allowsSkipping
    }

    private var region: String {
        regionOverride.isEmpty ? TMDBRegion.deviceDefault : regionOverride
    }

    private var canSave: Bool {
        if case .loaded(let loadedRegion, _) = catalog { loadedRegion == region } else { false }
    }

    var body: some View {
        let region = region
        NavigationStack {
            List {
                Section {
                    LabeledContent("Region", value: TMDBRegion.localizedName(for: region))
                }
                Section {
                    catalogRows
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search Streaming Services"
            )
            .navigationTitle("My Streaming Services")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        if allowsSkipping {
                            Text("Not Now")
                        } else {
                            Text("Cancel")
                        }
                    }
                    .accessibilityIdentifier("streaming.picker.cancel")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                        .accessibilityIdentifier("streaming.picker.save")
                }
            }
        }
        .task(id: "\(region)-\(retryID)") {
            await loadCatalog(for: region)
        }
    }

    @ViewBuilder
    private var catalogRows: some View {
        switch catalog {
        case .loaded(let loadedRegion, let providers) where loadedRegion == region:
            if providers.isEmpty {
                Text("No streaming services found for this region.")
                    .foregroundStyle(.secondary)
            } else {
                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let matches = providers.filter {
                    query.isEmpty || $0.providerName.localizedStandardContains(query)
                }

                if matches.isEmpty {
                    Text("No matching streaming services.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(matches) { provider in
                        providerRow(provider)
                    }
                }
            }
        case .failed(let failedRegion) where failedRegion == region:
            Text("We couldn’t load streaming services.")
                .foregroundStyle(.secondary)
            Button("Try Again", systemImage: "arrow.clockwise") {
                retryID += 1
            }
            .accessibilityIdentifier("streaming.picker.retry")
        default:
            ProgressView("Loading streaming services")
        }
    }

    private func providerRow(_ provider: WatchProvider) -> some View {
        let isSelected = selection.contains(provider.id)
        return Button {
            if isSelected {
                selection.remove(provider.id)
            } else {
                selection.insert(provider.id)
            }
        } label: {
            HStack(spacing: DSSpacing.sm) {
                PosterImage(path: provider.logoPath, kind: .profile)
                    .frame(width: 32, height: 32)
                    .clipShape(.rect(cornerRadius: 7))
                    .accessibilityHidden(true)
                Text(verbatim: provider.providerName)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.primary)
                        .accessibilityHidden(true)
                }
            }
            .frame(minHeight: 36)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("streaming.picker.provider.\(provider.id)")
    }

    private func loadCatalog(for region: String) async {
        guard !Task.isCancelled, region == TMDBRegion.current else { return }
        catalog = .loading
        let client = client
        let parameters = ["watch_region": region]
        do {
            async let movies: WatchProviderCatalogResponse = client.fetch(
                .movieWatchProviderCatalog,
                parameters: parameters
            )
            async let shows: WatchProviderCatalogResponse = client.fetch(
                .tvWatchProviderCatalog,
                parameters: parameters
            )
            let (movieCatalog, showCatalog) = try await (movies, shows)
            let providers = movieCatalog.providers(for: region, including: showCatalog)
            guard !Task.isCancelled, region == TMDBRegion.current else { return }

            let preferences = StreamingServicePreferences(data: preferencesData)
            selection = preferences.providerIDs(for: region).intersection(providers.map(\.id))
            catalog = .loaded(region: region, providers: providers)
        } catch {
            guard !Task.isCancelled, region == TMDBRegion.current else { return }
            catalog = .failed(region: region)
        }
    }

    private func save() {
        guard canSave, region == TMDBRegion.current else { return }
        var preferences = StreamingServicePreferences(data: preferencesData)
        preferences.setProviderIDs(selection, for: region)
        preferencesData = preferences.data
        dismiss()
    }
}
