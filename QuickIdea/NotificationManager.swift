import Foundation
import UserNotifications
import SwiftData

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isEnabled = false
    @Published var notificationTimes: [Date] = []

    private let defaults = UserDefaults.shared

    private init() {
        loadSettings()
        checkAuthorizationStatus()
    }

    // MARK: - 权限管理

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isEnabled = granted
                saveSettings()
            }
            return granted
        } catch {
            print("请求通知权限失败: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        Task {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            await MainActor.run {
                self.isEnabled = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - 设置管理

    private func loadSettings() {
        isEnabled = defaults.bool(forKey: "notificationsEnabled")

        if let timesData = defaults.data(forKey: "notificationTimes"),
           let times = try? JSONDecoder().decode([Date].self, from: timesData) {
            notificationTimes = times
        } else {
            // 默认时间：早上 9:00, 下午 3:00, 晚上 8:00
            let calendar = Calendar.current
            let now = Date()
            notificationTimes = [
                calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now,
                calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now) ?? now
            ]
        }
    }

    private func saveSettings() {
        defaults.set(isEnabled, forKey: "notificationsEnabled")

        if let timesData = try? JSONEncoder().encode(notificationTimes) {
            defaults.set(timesData, forKey: "notificationTimes")
        }
    }

    // MARK: - 通知调度

    func scheduleNotifications(with modelContext: ModelContext) {
        guard isEnabled else { return }

        // 取消所有已有通知
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        // 为每个时间点安排通知
        for time in notificationTimes {
            scheduleNotification(at: time, with: modelContext)
        }
    }

    private func scheduleNotification(at time: Date, with modelContext: ModelContext) {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        let content = UNMutableNotificationContent()
        content.title = "💡 灵感提醒"
        content.sound = .default

        // 获取随机未处理灵感
        if let randomIdea = fetchRandomPendingIdea(from: modelContext) {
            let displayText = randomIdea.cleanContent.isEmpty ? randomIdea.content : randomIdea.cleanContent
            content.body = displayText
            content.badge = NSNumber(value: countPendingIdeas(from: modelContext))
        } else {
            content.body = "你还有灵感没有处理，快去看看吧！"
        }

        // 创建每日重复触发器
        var dateComponents = DateComponents()
        dateComponents.hour = components.hour
        dateComponents.minute = components.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let identifier = "quickidea-\(components.hour ?? 0)-\(components.minute ?? 0)"

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("添加通知失败: \(error)")
            }
        }
    }

    // MARK: - 数据查询

    private func fetchRandomPendingIdea(from context: ModelContext) -> Idea? {
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.statusRaw == "未处理" },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )

        do {
            let ideas = try context.fetch(descriptor)
            return ideas.randomElement()
        } catch {
            print("获取灵感失败: \(error)")
            return nil
        }
    }

    private func countPendingIdeas(from context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { $0.statusRaw == "未处理" }
        )

        do {
            return try context.fetchCount(descriptor)
        } catch {
            return 0
        }
    }

    // MARK: - 公共接口

    func addNotificationTime(_ time: Date) {
        notificationTimes.append(time)
        saveSettings()
    }

    func removeNotificationTime(at index: Int) {
        notificationTimes.remove(at: index)
        saveSettings()
    }

    func toggleNotifications(with modelContext: ModelContext) {
        isEnabled.toggle()
        saveSettings()

        if isEnabled {
            scheduleNotifications(with: modelContext)
        } else {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        }
    }
}
