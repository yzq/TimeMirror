import SwiftData
import SwiftUI

struct ReviewView: View {
    @Query(sort: \TimeEntryRecord.startedAt, order: .reverse) private var entries: [TimeEntryRecord]

    @State private var referenceDate = Date.now

    private var summary: WeeklySummary {
        ReviewCalculator.summary(entries: entries.map(\.snapshot), containing: referenceDate)
    }

    private var weekInterval: DateInterval {
        ReviewCalculator.weekInterval(containing: referenceDate)
    }

    private struct CategoryValue: Identifiable {
        let category: TimeCategoryKind
        let hours: Double

        var id: TimeCategoryKind { category }
    }

    private var categoryValues: [CategoryValue] {
        TimeCategoryKind.allCases.compactMap { category in
            let duration = summary.categoryDurations[category, default: 0]
            guard duration > 0 else { return nil }
            return CategoryValue(category: category, hours: duration / 3_600)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                weekNavigation
                metrics

                if summary.entryCount == 0 {
                    EmptyStateView(
                        symbol: "chart.xyaxis.line",
                        title: "还没有足够的数据",
                        message: "完成几次时间记录后，这里会呈现时间分配和个人节奏。"
                    )
                    .frame(minHeight: 300)
                } else {
                    allocationChart
                    observations
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("周复盘")
    }

    private var weekNavigation: some View {
        HStack {
            Button {
                referenceDate = Calendar.current.date(byAdding: .weekOfYear, value: -1, to: referenceDate) ?? referenceDate
            } label: {
                Image(systemName: "chevron.left")
            }
            Spacer()
            Text("\(weekInterval.start.formatted(.dateTime.month().day()))—\(weekInterval.end.addingTimeInterval(-1).formatted(.dateTime.month().day()))")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button {
                referenceDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: referenceDate) ?? referenceDate
            } label: {
                Image(systemName: "chevron.right")
            }
            .disabled(weekInterval.start >= ReviewCalculator.weekInterval(containing: .now).start)
        }
    }

    private var metrics: some View {
        HStack(spacing: 10) {
            metric(title: "已记录", value: DurationText.compact(summary.totalDuration))
            metric(title: "核心创造", value: DurationText.compact(summary.coreDuration))
            metric(
                title: "估时准确率",
                value: summary.estimationAccuracy.map { "\(Int(($0 * 100).rounded()))%" } ?? "—"
            )
        }
    }

    private func metric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(value)
                .font(.headline)
                .minimumScaleFactor(0.75)
                .lineLimit(1)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
    }

    private var allocationChart: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("时间分配").font(.headline)
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        ForEach(categoryValues) { item in
                            Rectangle()
                                .fill(item.category.color)
                                .frame(width: proxy.size.width * item.hours / max(summary.totalDuration / 3_600, 0.01))
                        }
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 14)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("本周时间分类分布")
                .accessibilityValue(allocationAccessibilityValue)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], alignment: .leading, spacing: 9) {
                    ForEach(categoryValues) { item in
                        HStack(spacing: 7) {
                            CategoryDot(category: item.category)
                            Text("\(item.category.shortTitle) \(item.hours, format: .number.precision(.fractionLength(1)))小时")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var allocationAccessibilityValue: String {
        categoryValues
            .map { "\($0.category.title) \($0.hours.formatted(.number.precision(.fractionLength(1)))) 小时" }
            .joined(separator: "，")
    }

    private var observations: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("本周观察")
                .font(.title3.weight(.semibold))
                .padding(.bottom, 8)

            insight(
                symbol: "sunrise",
                title: "主要开始时段",
                detail: summary.predominantStartHour.map { "记录最常从 \(String(format: "%02d:00", $0)) 左右开始。" } ?? "继续记录后会逐渐看见稳定时段。"
            )
            Divider()
            insight(
                symbol: "scale.3d",
                title: "估时校准",
                detail: summary.estimationAccuracy.map { $0 >= 0.8 ? "本周估时已经比较接近实际。" : "实际用时与预计仍有差距，下周可适当留出余量。" } ?? "为活动填写预计时间后，可以计算校准结果。"
            )
            Divider()
            insight(
                symbol: "leaf",
                title: "恢复也属于生活",
                detail: summary.categoryDurations[.recovery, default: 0] > 0 ? "本周已经记录了有意识的恢复时间。" : "本周尚未记录恢复活动，它不应被默认视为浪费。"
            )
        }
    }

    private func insight(symbol: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(AppTheme.green)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.medium))
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.vertical, 13)
    }
}
