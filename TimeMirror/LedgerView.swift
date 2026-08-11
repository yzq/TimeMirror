import SwiftData
import SwiftUI

struct LedgerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TimeEntryRecord.startedAt, order: .reverse) private var entries: [TimeEntryRecord]

    @State private var selectedDate = Date.now.startOfDay
    @State private var showingManualEntry = false

    private var selectedEntries: [TimeEntryRecord] {
        entries.filter { Calendar.current.isDate($0.startedAt, inSameDayAs: selectedDate) }
    }

    private var selectedTotal: TimeInterval {
        selectedEntries.reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                weekStrip

                HStack(alignment: .firstTextBaseline) {
                    Text("已记录").font(.headline)
                    Spacer()
                    Text(DurationText.compact(selectedTotal))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(AppTheme.green)
                }

                if selectedEntries.isEmpty {
                    EmptyStateView(
                        symbol: "clock.badge.questionmark",
                        title: "这一天还没有记录",
                        message: "可以补记一段已经完成的活动。"
                    )
                    .frame(minHeight: 280)
                } else {
                    VStack(spacing: 0) {
                        ForEach(selectedEntries) { entry in
                            TimelineEntryRow(entry: entry)
                                .contextMenu {
                                    Button("删除", role: .destructive) {
                                        modelContext.delete(entry)
                                        try? modelContext.save()
                                    }
                                }
                            if entry.id != selectedEntries.last?.id { Divider() }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("时间账本")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingManualEntry = true
                } label: {
                    Label("补记", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualEntryView(defaultDate: selectedDate) { record in
                modelContext.insert(record)
                try? modelContext.save()
                showingManualEntry = false
            }
        }
    }

    private var weekStrip: some View {
        let interval = ReviewCalculator.weekInterval(containing: selectedDate)
        return HStack(spacing: 6) {
            ForEach(0..<7, id: \.self) { offset in
                let date = Calendar.current.date(byAdding: .day, value: offset, to: interval.start) ?? interval.start
                Button {
                    selectedDate = date
                } label: {
                    VStack(spacing: 7) {
                        Text(date, format: .dateTime.weekday(.narrow))
                            .font(.caption2)
                        Text(date, format: .dateTime.day())
                            .font(.subheadline.weight(.medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .foregroundStyle(Calendar.current.isDate(date, inSameDayAs: selectedDate) ? Color.white : Color.primary)
                    .background(
                        Calendar.current.isDate(date, inSameDayAs: selectedDate) ? AppTheme.green : Color.clear,
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(date.formatted(date: .complete, time: .omitted))
            }
        }
    }
}

private struct ManualEntryView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (TimeEntryRecord) -> Void

    @State private var title = ""
    @State private var category: TimeCategoryKind = .coreCreation
    @State private var startedAt: Date
    @State private var endedAt: Date
    @State private var estimatedMinutes = 45
    @State private var usesEstimate = false

    init(defaultDate: Date, onSave: @escaping (TimeEntryRecord) -> Void) {
        self.onSave = onSave
        let calendar = Calendar.current
        let start = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: defaultDate) ?? defaultDate
        _startedAt = State(initialValue: start)
        _endedAt = State(initialValue: start.addingTimeInterval(45 * 60))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("活动") {
                    TextField("活动名称", text: $title)
                    Picker("类别", selection: $category) {
                        ForEach(TimeCategoryKind.allCases) { item in
                            Text(item.title).tag(item)
                        }
                    }
                }
                Section("时间") {
                    DatePicker("开始", selection: $startedAt)
                    DatePicker("结束", selection: $endedAt, in: startedAt...)
                }
                Section("预估") {
                    Toggle("记录预计用时", isOn: $usesEstimate)
                    if usesEstimate {
                        Stepper("\(estimatedMinutes) 分钟", value: $estimatedMinutes, in: 5...240, step: 5)
                    }
                }
            }
            .navigationTitle("补记时间")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(TimeEntryRecord(
                            title: title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "未命名活动" : title,
                            category: category,
                            startedAt: startedAt,
                            endedAt: endedAt,
                            estimatedMinutes: usesEstimate ? estimatedMinutes : nil
                        ))
                    }
                }
            }
        }
    }
}
