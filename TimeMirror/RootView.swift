import SwiftUI

struct RootView: View {
    @AppStorage("has-completed-onboarding") private var hasCompletedOnboarding = false
    @StateObject private var timerController = TimerController()

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                MainTabView(timerController: timerController)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
        .tint(AppTheme.green)
    }
}

private struct MainTabView: View {
    @ObservedObject var timerController: TimerController

    var body: some View {
        TabView {
            NavigationStack {
                TodayView(timerController: timerController)
            }
            .tabItem { Label("今天", systemImage: "circle.circle") }

            NavigationStack {
                LedgerView()
            }
            .tabItem { Label("账本", systemImage: "book.pages") }

            NavigationStack {
                ReviewView()
            }
            .tabItem { Label("复盘", systemImage: "chart.xyaxis.line") }

            NavigationStack {
                DirectionsView()
            }
            .tabItem { Label("方向", systemImage: "safari") }
        }
    }
}
