import Combine
import Foundation

@MainActor
final class TimerController: ObservableObject {
    @Published private(set) var activeSession: ActiveSessionState?

    private let defaults: UserDefaults
    private let storageKey = "active-time-session"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: storageKey),
           let restored = try? JSONDecoder().decode(ActiveSessionState.self, from: data) {
            activeSession = restored
        }
    }

    var isPaused: Bool { activeSession?.pausedAt != nil }

    func start(title: String, category: TimeCategoryKind, estimatedMinutes: Int?) {
        activeSession = ActiveSessionState(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未命名活动" : title,
            category: category,
            estimatedMinutes: estimatedMinutes
        )
        persist()
    }

    func togglePause(at date: Date = .now) {
        guard var session = activeSession else { return }
        if let pausedAt = session.pausedAt {
            session.accumulatedPause += max(0, date.timeIntervalSince(pausedAt))
            session.pausedAt = nil
        } else {
            session.pausedAt = date
        }
        activeSession = session
        persist()
    }

    func elapsed(at date: Date = .now) -> TimeInterval {
        activeSession?.elapsed(at: date) ?? 0
    }

    func finish(at date: Date = .now) -> TimeEntrySnapshot? {
        guard var session = activeSession else { return nil }
        if let pausedAt = session.pausedAt {
            session.accumulatedPause += max(0, date.timeIntervalSince(pausedAt))
            session.pausedAt = nil
        }
        let elapsed = session.elapsed(at: date)
        let end = session.startedAt.addingTimeInterval(elapsed)
        let snapshot = TimeEntrySnapshot(
            id: session.id,
            title: session.title,
            category: session.category,
            startedAt: session.startedAt,
            endedAt: end,
            estimatedMinutes: session.estimatedMinutes
        )
        activeSession = nil
        defaults.removeObject(forKey: storageKey)
        return snapshot
    }

    func cancel() {
        activeSession = nil
        defaults.removeObject(forKey: storageKey)
    }

    private func persist() {
        guard let activeSession,
              let data = try? JSONEncoder().encode(activeSession) else { return }
        defaults.set(data, forKey: storageKey)
    }
}
