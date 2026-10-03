import Foundation

public enum LifetimeDurationUnit: Sendable, Equatable {
    case month, week, day, hour, minute
}

public struct LifetimeDurationComponent: Sendable, Equatable {
    public let value: Int
    public let unit: LifetimeDurationUnit

    public init(value: Int, unit: LifetimeDurationUnit) {
        self.value = value
        self.unit = unit
    }
}

/// Display units are fixed durations: one day is 24 hours, one week is
/// seven days, and one month is four weeks. They are not calendar months.
public enum LifetimeDurationBreakdown {
    public static func components(for totalMinutes: Int) -> [LifetimeDurationComponent] {
        let units: [(LifetimeDurationUnit, Int)] = [
            (.month, 4 * 7 * 24 * 60),
            (.week, 7 * 24 * 60),
            (.day, 24 * 60),
            (.hour, 60),
            (.minute, 1)
        ]
        var remaining = max(totalMinutes, 0)
        var result: [LifetimeDurationComponent] = []
        for (unit, minutesPerUnit) in units {
            let count = remaining / minutesPerUnit
            guard count > 0 else { continue }
            result.append(LifetimeDurationComponent(value: count, unit: unit))
            if result.count == 2 { break }
            remaining %= minutesPerUnit
        }
        return result.isEmpty ? [LifetimeDurationComponent(value: 0, unit: .minute)] : result
    }
}
