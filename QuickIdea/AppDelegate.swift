import SwiftUI
import SwiftData

@main
struct QuickIdeaApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            // 方案 1: 重建数据库（最简单）
            // 删除旧数据库，使用新模型
            let schema = Schema([Idea.self])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                groupContainer: .identifier("group.com.quickidea.app")
            )

            // 如果有旧数据导致错误，尝试删除容器
            do {
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                // 删除旧数据库并重试
                print("⚠️ 检测到旧数据格式，正在清理...")
                try? FileManager.default.removeItem(at: modelConfiguration.url)
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
                print("✅ 数据库已重建")
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(IdeaStore.shared)
        }
        .modelContainer(modelContainer)
    }
}
