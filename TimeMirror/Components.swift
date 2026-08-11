import SwiftUI

struct SectionCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct CategoryDot: View {
    let category: TimeCategoryKind

    var body: some View {
        Circle()
            .fill(category.color)
            .frame(width: 9, height: 9)
            .accessibilityHidden(true)
    }
}

struct EmptyStateView: View {
    let symbol: String
    let title: String
    let message: String

    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(message))
    }
}

extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
}
