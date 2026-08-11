import XCTest
#if canImport(TimeMirrorCore)
@testable import TimeMirrorCore
#else
@testable import TimeMirror
#endif

final class ReviewCalculatorTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testSummaryFiltersToRequestedWeekAndAggregatesCategories() throws {
        let reference = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 8, day: 11)))
        let coreStart = try XCTUnwrap(calendar.date(bySettingHour: 9, minute: 0, second: 0, of: reference))
        let learningStart = try XCTUnwrap(calendar.date(bySettingHour: 14, minute: 0, second: 0, of: reference))
        let previousWeek = try XCTUnwrap(calendar.date(byAdding: .day, value: -8, to: reference))

        let entries = [
            TimeEntrySnapshot(title: "写作", category: .coreCreation, startedAt: coreStart, endedAt: coreStart.addingTimeInterval(3_600), estimatedMinutes: 60),
            TimeEntrySnapshot(title: "阅读", category: .learning, startedAt: learningStart, endedAt: learningStart.addingTimeInterval(1_800)),
            TimeEntrySnapshot(title: "旧记录", category: .coreCreation, startedAt: previousWeek, endedAt: previousWeek.addingTimeInterval(9_000))
        ]

        let result = ReviewCalculator.summary(entries: entries, containing: reference, calendar: calendar)

        XCTAssertEqual(result.entryCount, 2)
        XCTAssertEqual(result.totalDuration, 5_400, accuracy: 0.01)
        XCTAssertEqual(result.coreDuration, 3_600, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(result.categoryDurations[.learning]), 1_800, accuracy: 0.01)
        XCTAssertEqual(try XCTUnwrap(result.estimationAccuracy), 1, accuracy: 0.001)
    }

    func testDurationTextProducesCompactChineseLabels() {
        XCTAssertEqual(DurationText.compact(45 * 60), "45分")
        XCTAssertEqual(DurationText.compact(90 * 60), "1小时30分")
        XCTAssertEqual(DurationText.clock(65), "01:05")
    }
}
