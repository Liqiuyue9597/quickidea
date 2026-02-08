import Foundation
import SwiftData

// 版本 1 (旧模型) - 用于迁移
@Model
final class IdeaV1 {
    var id: UUID
    var content: String
    var category: String
    var createdAt: Date
    var isCompleted: Bool

    init(content: String, category: String = "想法") {
        self.id = UUID()
        self.content = content
        self.category = category
        self.createdAt = Date()
        self.isCompleted = false
    }
}

// 版本 2 (当前模型)
@Model
final class Idea {
    var id: UUID
    var content: String
    var tags: [String]
    var createdAt: Date
    var isCompleted: Bool

    init(content: String, tags: [String] = []) {
        self.id = UUID()
        self.content = content
        self.tags = tags
        self.createdAt = Date()
        self.isCompleted = false
    }

    // 从旧模型迁移
    init(from oldIdea: IdeaV1) {
        self.id = oldIdea.id
        self.content = oldIdea.content
        // 将旧的 category 转换为标签数组
        self.tags = [oldIdea.category]
        self.createdAt = oldIdea.createdAt
        self.isCompleted = oldIdea.isCompleted
    }

    // 从内容中提取标签（# 开头的词）
    static func extractTags(from content: String) -> [String] {
        let pattern = "#([\\p{L}\\p{N}_]+)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return []
        }

        let nsString = content as NSString
        let matches = regex.matches(in: content, range: NSRange(location: 0, length: nsString.length))

        return matches.compactMap { match in
            guard match.numberOfRanges > 1 else { return nil }
            let tagRange = match.range(at: 1)
            return nsString.substring(with: tagRange)
        }
    }

    // 获取去除标签后的纯文本
    var cleanContent: String {
        let pattern = "#[\\p{L}\\p{N}_]+"
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return content
        }
        return regex.stringByReplacingMatches(
            in: content,
            range: NSRange(location: 0, length: content.utf16.count),
            withTemplate: ""
        ).trimmingCharacters(in: .whitespaces)
    }
}

// 标签辅助类
@MainActor
class TagManager: ObservableObject {
    static let shared = TagManager()

    @Published var recentTags: [String] = []

    private let maxRecentTags = 20
    private let recentTagsKey = "recentTags"

    private init() {
        loadRecentTags()
    }

    func addTag(_ tag: String) {
        var tags = recentTags
        tags.removeAll { $0 == tag }
        tags.insert(tag, at: 0)
        recentTags = Array(tags.prefix(maxRecentTags))
        saveRecentTags()
    }

    func addTags(_ tags: [String]) {
        tags.forEach { addTag($0) }
    }

    private func loadRecentTags() {
        if let saved = UserDefaults.shared.array(forKey: recentTagsKey) as? [String] {
            recentTags = saved
        }
    }

    private func saveRecentTags() {
        UserDefaults.shared.set(recentTags, forKey: recentTagsKey)
    }

    // 预设的常用标签
    static let suggestedTags = ["想法", "待办", "创意", "学习", "工作", "生活", "笔记", "灵感"]
}

enum DisplayMode: String, CaseIterable {
    case latest = "最新一条"
    case random = "随机一条"
    case multiple = "显示多条"

    var description: String {
        switch self {
        case .latest: return "只显示最新记录的想法"
        case .random: return "每次随机显示一条想法"
        case .multiple: return "显示最近 2-3 条想法"
        }
    }
}

@MainActor
class IdeaStore: ObservableObject {
    static let shared = IdeaStore()

    @Published var displayMode: DisplayMode {
        didSet {
            UserDefaults.shared.set(displayMode.rawValue, forKey: "displayMode")
        }
    }

    private init() {
        let savedMode = UserDefaults.shared.string(forKey: "displayMode") ?? DisplayMode.latest.rawValue
        self.displayMode = DisplayMode(rawValue: savedMode) ?? .latest
    }
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: "group.com.quickidea.app")!
    }
}

