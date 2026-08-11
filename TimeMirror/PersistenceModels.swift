import Foundation
import SwiftData

@Model
final class TimeEntryRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var categoryRaw: String
    var startedAt: Date
    var endedAt: Date
    var estimatedMinutes: Int?
    var energyRaw: String?
    var note: String

    init(
        id: UUID = UUID(),
        title: String,
        category: TimeCategoryKind,
        startedAt: Date,
        endedAt: Date,
        estimatedMinutes: Int? = nil,
        energy: EnergyLevel? = nil,
        note: String = ""
    ) {
        self.id = id
        self.title = title
        self.categoryRaw = category.rawValue
        self.startedAt = startedAt
        self.endedAt = max(startedAt, endedAt)
        self.estimatedMinutes = estimatedMinutes
        self.energyRaw = energy?.rawValue
        self.note = note
    }

    var category: TimeCategoryKind {
        get { TimeCategoryKind(rawValue: categoryRaw) ?? .support }
        set { categoryRaw = newValue.rawValue }
    }

    var energy: EnergyLevel? {
        get { energyRaw.flatMap(EnergyLevel.init(rawValue:)) }
        set { energyRaw = newValue?.rawValue }
    }

    var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }

    var snapshot: TimeEntrySnapshot {
        TimeEntrySnapshot(
            id: id,
            title: title,
            category: category,
            startedAt: startedAt,
            endedAt: endedAt,
            estimatedMinutes: estimatedMinutes,
            energy: energy
        )
    }
}

@Model
final class DirectionRecord {
    @Attribute(.unique) var id: UUID
    var title: String
    var detail: String
    var createdAt: Date
    var isPrimary: Bool

    init(
        id: UUID = UUID(),
        title: String,
        detail: String,
        createdAt: Date = .now,
        isPrimary: Bool = true
    ) {
        self.id = id
        self.title = title
        self.detail = detail
        self.createdAt = createdAt
        self.isPrimary = isPrimary
    }
}

@Model
final class TimeBudgetRecord {
    @Attribute(.unique) var id: UUID
    var weekStart: Date
    var categoryRaw: String
    var plannedMinutes: Int

    init(
        id: UUID = UUID(),
        weekStart: Date,
        category: TimeCategoryKind,
        plannedMinutes: Int
    ) {
        self.id = id
        self.weekStart = weekStart
        self.categoryRaw = category.rawValue
        self.plannedMinutes = max(0, plannedMinutes)
    }

    var category: TimeCategoryKind {
        get { TimeCategoryKind(rawValue: categoryRaw) ?? .support }
        set { categoryRaw = newValue.rawValue }
    }
}
