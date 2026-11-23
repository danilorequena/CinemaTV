import Foundation

public struct StreamingServicePreferences: Sendable {
    public static let storageKey = "preferredStreamingServiceIDsByRegion"

    private var selections: [String: [Int]]

    public init(data: Data) {
        selections = (try? JSONDecoder().decode([String: [Int]].self, from: data)) ?? [:]
    }

    public var data: Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return (try? encoder.encode(selections)) ?? Data()
    }

    public func providerIDs(for region: String) -> Set<Int> {
        Set(selections[region.uppercased()] ?? [])
    }

    public mutating func setProviderIDs(_ ids: Set<Int>, for region: String) {
        selections[region.uppercased()] = ids.isEmpty ? nil : ids.sorted()
    }

    public func groupedProviders(
        _ providers: [WatchProvider],
        for region: String
    ) -> (preferred: [WatchProvider], other: [WatchProvider]) {
        let ids = providerIDs(for: region)
        return (
            preferred: providers.filter { ids.contains($0.id) },
            other: providers.filter { !ids.contains($0.id) }
        )
    }
}
