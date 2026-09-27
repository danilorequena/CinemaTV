import Foundation

public struct WatchProviderCatalogResponse: Decodable, Sendable {
    public let results: [WatchProvider]

    /// O endpoint já filtra pelo `watch_region`; mantenha todos os itens
    /// retornados, mesmo se um deles não trouxer prioridade regional.
    public func providers(for region: String) -> [WatchProvider] {
        let regionCode = region.uppercased()
        let ordered = results.sorted { lhs, rhs in
            let lhsPriority = lhs.displayPriorities?[regionCode] ?? lhs.displayPriority ?? .max
            let rhsPriority = rhs.displayPriorities?[regionCode] ?? rhs.displayPriority ?? .max
            if lhsPriority != rhsPriority { return lhsPriority < rhsPriority }

            let nameOrder = lhs.providerName.localizedCaseInsensitiveCompare(rhs.providerName)
            if nameOrder != .orderedSame { return nameOrder == .orderedAscending }
            return lhs.providerId < rhs.providerId
        }

        var seenIDs = Set<Int>()
        return ordered.filter { seenIDs.insert($0.providerId).inserted }
    }
}
