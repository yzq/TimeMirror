import Foundation

public struct WeeklySummary: Equatable, Sendable {
    public let totalDuration: TimeInterval
    public let categoryDurations: [TimeCategoryKind: TimeInterval]
    public let estimationAccuracy: Double?
    public let predominantStartHour: Int?
    public let entryCount: Int

    public var coreDuration: TimeInterval {
        categoryDurations[.coreCreation, default: 0]
    }
}

public enum ReviewCalculator {
    public static func weekInterval(containing date: Date, calendar: Calendar = .current) -> DateInterval {
        calendar.dateInterval(of: .weekOfYear, for: date)
            ?? DateInterval(start: calendar.startOfDay(for: date), duration: 7 * 86_400)
    }

    public static func summary(
        entries: [TimeEntrySnapshot],
        containing date: Date = .now,
        calendar: Calendar = .current
    ) -> WeeklySummary {
        let interval = weekInterval(containing: date, calendar: calendar)
        let included = entries.filter { interval.contains($0.startedAt) }

        var categoryDurations: [TimeCategoryKind: TimeInterval] = [:]
        var accuracySamples: [Double] = []
        var startsByHour: [Int: Int] = [:]

        for entry in included {
            categoryDurations[entry.category, default: 0] += entry.duration
            let hour = calendar.component(.hour, from: entry.startedAt)
            startsByHour[hour, default: 0] += 1

            if let estimate = entry.estimatedMinutes, estimate > 0, entry.duration > 0 {
                let estimateSeconds = Double(estimate * 60)
                let relativeError = abs(entry.duration - estimateSeconds) / entry.duration
                accuracySamples.append(max(0, 1 - min(1, relativeError)))
            }
        }

        let total = categoryDurations.values.reduce(0, +)
        let accuracy = accuracySamples.isEmpty
            ? nil
            : accuracySamples.reduce(0, +) / Double(accuracySamples.count)
        let predominantHour = startsByHour.max {
            if $0.value == $1.value { return $0.key > $1.key }
            return $0.value < $1.value
        }?.key

        return WeeklySummary(
            totalDuration: total,
            categoryDurations: categoryDurations,
            estimationAccuracy: accuracy,
            predominantStartHour: predominantHour,
            entryCount: included.count
        )
    }
}
