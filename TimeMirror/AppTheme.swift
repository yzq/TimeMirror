import SwiftUI

enum AppTheme {
    static let green = Color(red: 0.18, green: 0.42, blue: 0.31)
    static let softGreen = Color(red: 0.88, green: 0.94, blue: 0.90)
    static let blue = Color(red: 0.33, green: 0.45, blue: 0.61)
    static let amber = Color(red: 0.71, green: 0.42, blue: 0.15)
    static let purple = Color(red: 0.47, green: 0.39, blue: 0.56)
}

extension TimeCategoryKind {
    var color: Color {
        switch self {
        case .coreCreation: AppTheme.green
        case .learning: AppTheme.blue
        case .support: AppTheme.purple
        case .recovery: AppTheme.amber
        case .unintentional: .secondary
        }
    }

    var symbol: String {
        switch self {
        case .coreCreation: "sparkles"
        case .learning: "book.closed"
        case .support: "tray.full"
        case .recovery: "leaf"
        case .unintentional: "ellipsis.circle"
        }
    }
}
