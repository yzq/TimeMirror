import SwiftData
import SwiftUI

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntryRecord.startedAt, order: .reverse) private var entries: [TimeEntryRecord]
    @Query private var budgets: [TimeBudgetRecord]

    @ObservedObject var timerController: TimerController

    @State private var showingStartSheet = false
    @State private var pendingEntry: TimeEntrySnapshot?

    private var todayEntries: [TimeEntryRecord] {
        entries.filter { Calendar.current.isDateInToday($0.startedAt) }
    }

    private var weeklyCoreDuration: TimeInterval {
        let interval = ReviewCalculator.weekInterval(containing: .now)
        return entries
            .filter { interval.contains($0.startedAt) && $0.category == .coreCreation }
            .reduce(0) { $0 + $1.duration }
    }

    private var weeklyCoreTarget: TimeInterval {
        let interval = ReviewCalculator.weekInterval(containing: .now)
        let minutes = budgets.first {
            $0.category == .coreCreation && Calendar.current.isDate($0.weekStart, inSameDayAs: interval.start)
        }?.plannedMinutes ?? 600
        return TimeInterval(minutes * 60)
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                weeklyProgress

                if timerController.activeSession != nil {
                    activeSessionCard
                } else {
                    Button {
                        showingStartSheet = true
                    } label: {
                        Label("开始记录", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }

                HStack {
                    Text("时间账本").font(.title3.weight(.semibold))
                    Spacer()
                    NavigationLink("查看全部") { LedgerView() }
                        .font(.subheadline)
                }

                if todayEntries.isEmpty {
                    SectionCard {
                        Label("今天还没有记录", systemImage: "clock")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(todayEntries.prefix(6)) { entry in
                            TimelineEntryRow(entry: entry)
                            if entry.id != todayEntries.prefix(6).last?.id { Divider() }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingStartSheet) {
            StartSessionView(timerController: timerController)
                .presentationDetents([.medium])
        }
        .sheet(item: $pendingEntry) { entry in
            FinishSessionView(entry: entry) { energy, note in
                let record = TimeEntryRecord(
                    id: entry.id,
                    title: entry.title,
                    category: entry.category,
                    startedAt: entry.startedAt,
                    endedAt: entry.endedAt,
                    estimatedMinutes: entry.estimatedMinutes,
                    energy: energy,
                    note: note
                )
                modelContext.insert(record)
                try? modelContext.save()
                pendingEntry = nil
            }
            .interactiveDismissDisabled()
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.now, format: .dateTime.month().day().weekday(.wide))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("今天")
                .font(.largeTitle.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var weeklyProgress: some View {
        SectionCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("本周核心时间").font(.headline)
                    Spacer()
                    Text("\(DurationText.compact(weeklyCoreDuration)) / \(DurationText.compact(weeklyCoreTarget))")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(AppTheme.green)
                }
                ProgressView(value: min(weeklyCoreDuration, weeklyCoreTarget), total: max(weeklyCoreTarget, 1))
                Text(progressMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var progressMessage: String {
        guard weeklyCoreTarget > 0 else { return "尚未设置本周核心时间预算。" }
        let ratio = weeklyCoreDuration / weeklyCoreTarget
        switch ratio {
        case ..<0.7: return "保持真实记录，不需要为了数字追赶。"
        case ..<1: return "本周计划正在接近你的预算。"
        default: return "已经达到本周预算，可以留意恢复节奏。"
        }
    }

    private var activeSessionCard: some View {
        SectionCard {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(timerController.activeSession?.category.title ?? "") · 正在进行")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(timerController.activeSession?.title ?? "")
                                .font(.headline)
                        }
                        Spacer()
                        Image(systemName: timerController.isPaused ? "pause.circle.fill" : "sparkles")
                            .foregroundStyle(AppTheme.green)
                    }

                    Text(DurationText.clock(timerController.elapsed(at: context.date)))
                        .font(.system(.largeTitle, design: .rounded).monospacedDigit())

                    HStack {
                        Button(timerController.isPaused ? "继续" : "暂停") {
                            timerController.togglePause()
                        }
                        .buttonStyle(.bordered)
                        .frame(maxWidth: .infinity)

                        Button("完成") {
                            pendingEntry = timerController.finish()
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }
}

private struct StartSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var timerController: TimerController

    @State private var title = ""
    @State private var category: TimeCategoryKind = .coreCreation
    @State private var estimate = 45
    @State private var usesEstimate = true

    var body: some View {
        NavigationStack {
            Form {
                Section("活动") {
                    TextField("正在做什么", text: $title)
                    Picker("类别", selection: $category) {
                        ForEach(TimeCategoryKind.allCases) { item in
                            Label(item.title, systemImage: item.symbol).tag(item)
                        }
                    }
                }

                Section("预估") {
                    Toggle("记录预计用时", isOn: $usesEstimate)
                    if usesEstimate {
                        Stepper("\(estimate) 分钟", value: $estimate, in: 5...240, step: 5)
                    }
                }
            }
            .navigationTitle("开始记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("开始") {
                        timerController.start(
                            title: title,
                            category: category,
                            estimatedMinutes: usesEstimate ? estimate : nil
                        )
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct FinishSessionView: View {
    let entry: TimeEntrySnapshot
    let onSave: (EnergyLevel?, String) -> Void

    @State private var energy: EnergyLevel? = .medium
    @State private var note = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("活动", value: entry.title)
                    LabeledContent("净时间", value: DurationText.compact(entry.duration))
                    LabeledContent("类别", value: entry.category.title)
                }
                Section("结束时的精力") {
                    Picker("精力", selection: $energy) {
                        Text("不记录").tag(EnergyLevel?.none)
                        ForEach(EnergyLevel.allCases) { level in
                            Text(level.title).tag(Optional(level))
                        }
                    }
                    .pickerStyle(.segmented)
                }
                Section("完成了什么（选填）") {
                    TextField("例如：确定三章结构", text: $note, axis: .vertical)
                }
            }
            .navigationTitle("保存记录")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { onSave(energy, note) }
                }
            }
        }
    }
}

struct TimelineEntryRow: View {
    let entry: TimeEntryRecord

    var body: some View {
        HStack(spacing: 12) {
            Text(entry.startedAt, format: .dateTime.hour().minute())
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 46, alignment: .leading)
            RoundedRectangle(cornerRadius: 3)
                .fill(entry.category.color)
                .frame(width: 5, height: 34)
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.title).font(.subheadline.weight(.medium))
                Text(entry.category.title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text(DurationText.compact(entry.duration))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
    }
}
