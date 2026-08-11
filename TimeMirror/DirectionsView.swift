import SwiftData
import SwiftUI

struct DirectionsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \DirectionRecord.createdAt) private var directions: [DirectionRecord]
    @Query(sort: \TimeEntryRecord.startedAt, order: .reverse) private var entries: [TimeEntryRecord]
    @Query private var budgets: [TimeBudgetRecord]

    @State private var showingEditor = false

    private var currentWeek: DateInterval {
        ReviewCalculator.weekInterval(containing: .now)
    }

    private var primaryDirection: DirectionRecord? {
        directions.first(where: \.isPrimary) ?? directions.first
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 20) {
                if let primaryDirection {
                    SectionCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("方向 01")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(AppTheme.green)
                            Text(primaryDirection.title)
                                .font(.title3.weight(.semibold))
                            Text(primaryDirection.detail)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    EmptyStateView(
                        symbol: "safari",
                        title: "还没有长期方向",
                        message: "建立一个方向，帮助自己判断时间是否投向真正重要的事情。"
                    )
                    .frame(minHeight: 220)
                }

                HStack {
                    Text("活动分类").font(.title3.weight(.semibold))
                    Spacer()
                    Text("本周").font(.caption).foregroundStyle(.secondary)
                }

                VStack(spacing: 0) {
                    ForEach(TimeCategoryKind.allCases) { category in
                        HStack(spacing: 11) {
                            CategoryDot(category: category)
                            Label(category.title, systemImage: category.symbol)
                                .labelStyle(.titleOnly)
                                .font(.subheadline)
                            Spacer()
                            Text(DurationText.compact(duration(for: category)))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 13)
                        if category != TimeCategoryKind.allCases.last { Divider() }
                    }
                }

                Text("本周时间预算")
                    .font(.title3.weight(.semibold))

                SectionCard {
                    VStack(spacing: 0) {
                        ForEach([TimeCategoryKind.coreCreation, .learning, .support, .recovery]) { category in
                            Stepper(value: budgetBinding(for: category), in: 0...2_400, step: 30) {
                                HStack {
                                    Text(category.title).font(.subheadline)
                                    Spacer()
                                    Text(DurationText.compact(TimeInterval(budgetMinutes(for: category) * 60)))
                                        .font(.caption.monospacedDigit())
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 8)
                            if category != .recovery { Divider() }
                        }
                    }
                }

                SectionCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("下周建议").font(.headline)
                        Text(suggestion)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("我的方向")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditor = true
                } label: {
                    Label("编辑方向", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showingEditor) {
            DirectionEditorView(direction: primaryDirection) { title, detail in
                if let primaryDirection {
                    primaryDirection.title = title
                    primaryDirection.detail = detail
                } else {
                    modelContext.insert(DirectionRecord(title: title, detail: detail))
                }
                try? modelContext.save()
                showingEditor = false
            }
        }
    }

    private func duration(for category: TimeCategoryKind) -> TimeInterval {
        entries
            .filter { currentWeek.contains($0.startedAt) && $0.category == category }
            .reduce(0) { $0 + $1.duration }
    }

    private func budgetMinutes(for category: TimeCategoryKind) -> Int {
        budgets.first {
            $0.category == category && Calendar.current.isDate($0.weekStart, inSameDayAs: currentWeek.start)
        }?.plannedMinutes ?? defaultBudgetMinutes(for: category)
    }

    private func defaultBudgetMinutes(for category: TimeCategoryKind) -> Int {
        switch category {
        case .coreCreation: 600
        case .learning: 300
        case .support: 240
        case .recovery: 300
        case .unintentional: 0
        }
    }

    private func budgetBinding(for category: TimeCategoryKind) -> Binding<Int> {
        Binding {
            budgetMinutes(for: category)
        } set: { newValue in
            if let budget = budgets.first(where: {
                $0.category == category && Calendar.current.isDate($0.weekStart, inSameDayAs: currentWeek.start)
            }) {
                budget.plannedMinutes = newValue
            } else {
                modelContext.insert(TimeBudgetRecord(
                    weekStart: currentWeek.start,
                    category: category,
                    plannedMinutes: newValue
                ))
            }
            try? modelContext.save()
        }
    }

    private var suggestion: String {
        let snapshots = entries.map(\.snapshot)
        let pastFourWeeksCore = (1...4).map { offset -> TimeInterval in
            let date = Calendar.current.date(byAdding: .weekOfYear, value: -offset, to: Date.now) ?? .now
            return ReviewCalculator.summary(entries: snapshots, containing: date).coreDuration
        }
        let nonzero = pastFourWeeksCore.filter { $0 > 0 }
        guard !nonzero.isEmpty else {
            return "先完成一周真实记录，再根据历史容量建立时间预算。"
        }
        let average = nonzero.reduce(0, +) / Double(nonzero.count)
        let low = max(0, average * 0.9)
        let high = average * 1.1
        return "核心创造可安排 \(DurationText.compact(low))—\(DurationText.compact(high))，并保留至少 30% 未分配时间。"
    }
}

private struct DirectionEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (String, String) -> Void
    @State private var title: String
    @State private var detail: String

    init(direction: DirectionRecord?, onSave: @escaping (String, String) -> Void) {
        self.onSave = onSave
        _title = State(initialValue: direction?.title ?? "")
        _detail = State(initialValue: direction?.detail ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("长期方向") {
                    TextField("例如：完成长期研究与写作", text: $title)
                    TextField("这个方向为什么重要", text: $detail, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    Text("方向不是具体任务，而是帮助你判断时间是否值得投入的长期主题。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("编辑方向")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(
                            title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "尚未命名的方向" : title,
                            detail
                        )
                    }
                }
            }
        }
    }
}
