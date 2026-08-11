import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    let onComplete: () -> Void

    @State private var step = 0
    @State private var selectedDirection = "完成一项长期研究或作品"

    private let directionOptions = [
        "完成一项长期研究或作品",
        "建立可持续的专业成长",
        "平衡工作、关系与恢复"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(systemName: "hourglass")
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(AppTheme.green)
                .frame(width: 56, height: 56)
                .background(AppTheme.softGreen, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .padding(.top, 32)

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { index in
                    Capsule()
                        .fill(index == step ? AppTheme.green : Color.secondary.opacity(0.18))
                        .frame(width: index == step ? 24 : 7, height: 7)
                        .animation(.easeInOut(duration: 0.2), value: step)
                }
            }
            .padding(.top, 34)

            Group {
                switch step {
                case 0: directionStep
                case 1: observationStep
                default: principleStep
                }
            }
            .padding(.top, 18)

            Spacer(minLength: 28)

            Button(step == 2 ? "开始建立时间基线" : "继续") {
                if step < 2 {
                    withAnimation(.easeInOut) { step += 1 }
                } else {
                    completeOnboarding()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .background(Color(uiColor: .systemGroupedBackground))
    }

    private var directionStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            heading("你希望把时间\n投向哪里？", detail: "先选一个长期方向。它不是待办事项，而是你希望持续投入的生活主题。")
            VStack(spacing: 10) {
                ForEach(directionOptions, id: \.self) { option in
                    Button {
                        selectedDirection = option
                    } label: {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(AppTheme.green)
                                .frame(width: 10, height: 10)
                            Text(option)
                            Spacer()
                            if selectedDirection == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AppTheme.green)
                            }
                        }
                        .padding(14)
                        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(selectedDirection == option ? AppTheme.green : Color.secondary.opacity(0.16), lineWidth: selectedDirection == option ? 2 : 1)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var observationStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            heading("先观察七天，\n暂时不设目标", detail: "时镜会记录你的真实节奏。七天后，再根据数据建立第一份时间预算。")
            VStack(spacing: 10) {
                categoryLine(.coreCreation, detail: "研究、写作与重要作品")
                categoryLine(.learning, detail: "阅读、课程与思考")
                categoryLine(.recovery, detail: "休息、运动与陪伴")
            }
        }
    }

    private var principleStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            heading("记录事实，\n不评价自己", detail: "娱乐和休息不是浪费。只有你自己可以判断一段时间是否值得。")
            SectionCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("第一周规则").font(.headline)
                        Spacer()
                        Text("观察期")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(AppTheme.green)
                    }
                    ProgressView(value: 1, total: 7)
                    Text("只记录，不比较，不追求连续打卡。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func heading(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.largeTitle.weight(.semibold))
            Text(detail)
                .foregroundStyle(.secondary)
                .lineSpacing(4)
        }
    }

    private func categoryLine(_ category: TimeCategoryKind, detail: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: category.symbol)
                .foregroundStyle(category.color)
                .frame(width: 34, height: 34)
                .background(category.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text(category.title).font(.headline)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func completeOnboarding() {
        let direction = DirectionRecord(
            title: selectedDirection,
            detail: "把稳定、真实的长期投入放在短期忙碌之前。"
        )
        modelContext.insert(direction)

        let weekStart = ReviewCalculator.weekInterval(containing: .now).start
        modelContext.insert(TimeBudgetRecord(weekStart: weekStart, category: .coreCreation, plannedMinutes: 10 * 60))
        modelContext.insert(TimeBudgetRecord(weekStart: weekStart, category: .learning, plannedMinutes: 5 * 60))
        modelContext.insert(TimeBudgetRecord(weekStart: weekStart, category: .support, plannedMinutes: 4 * 60))
        modelContext.insert(TimeBudgetRecord(weekStart: weekStart, category: .recovery, plannedMinutes: 5 * 60))

        try? modelContext.save()
        onComplete()
    }
}
