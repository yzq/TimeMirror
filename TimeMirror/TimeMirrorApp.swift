import SwiftData
import SwiftUI

@main
struct TimeMirrorApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema([
            TimeEntryRecord.self,
            DirectionRecord.self,
            TimeBudgetRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("无法创建本地数据库：\(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
