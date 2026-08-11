import Foundation

public enum TimeCategoryKind: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case coreCreation
    case learning
    case support
    case recovery
    case unintentional

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .coreCreation: "核心创造"
        case .learning: "学习输入"
        case .support: "辅助事务"
        case .recovery: "生活恢复"
        case .unintentional: "无意识消耗"
        }
    }

    public var shortTitle: String {
        switch self {
        case .coreCreation: "核心"
        case .learning: "学习"
        case .support: "事务"
        case .recovery: "恢复"
        case .unintentional: "消耗"
        }
    }
}

public enum EnergyLevel: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case low
    case medium
    case high

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .low: "偏低"
        case .medium: "适中"
        case .high: "充足"
        }
    }
}

public struct TimeEntrySnapshot: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let title: String
    public let category: TimeCategoryKind
    public let startedAt: Date
    public let endedAt: Date
    public let estimatedMinutes: Int?
    public let energy: EnergyLevel?

    public init(
        id: UUID = UUID(),
        title: String,
        category: TimeCategoryKind,
        startedAt: Date,
        endedAt: Date,
        estimatedMinutes: Int? = nil,
        energy: EnergyLevel? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.estimatedMinutes = estimatedMinutes
        self.energy = energy
    }

    public var duration: TimeInterval {
        max(0, endedAt.timeIntervalSince(startedAt))
    }
}

public struct ActiveSessionState: Codable, Equatable, Sendable {
    public var id: UUID
    public var title: String
    public var category: TimeCategoryKind
    public var estimatedMinutes: Int?
    public var startedAt: Date
    public var pausedAt: Date?
    public var accumulatedPause: TimeInterval

    public init(
        id: UUID = UUID(),
        title: String,
        category: TimeCategoryKind,
        estimatedMinutes: Int?,
        startedAt: Date = .now,
        pausedAt: Date? = nil,
        accumulatedPause: TimeInterval = 0
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.estimatedMinutes = estimatedMinutes
        self.startedAt = startedAt
        self.pausedAt = pausedAt
        self.accumulatedPause = accumulatedPause
    }

    public func elapsed(at date: Date = .now) -> TimeInterval {
        let effectiveEnd = pausedAt ?? date
        return max(0, effectiveEnd.timeIntervalSince(startedAt) - accumulatedPause)
    }
}

public enum DurationText {
    public static func compact(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(0, Int(seconds.rounded() / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        if hours == 0 { return "\(minutes)分" }
        if minutes == 0 { return "\(hours)小时" }
        return "\(hours)小时\(minutes)分"
    }

    public static func clock(_ seconds: TimeInterval) -> String {
        let value = max(0, Int(seconds))
        let hours = value / 3_600
        let minutes = (value % 3_600) / 60
        let remainingSeconds = value % 60
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, remainingSeconds)
        }
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}
