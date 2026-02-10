import WidgetKit
import SwiftUI
import SwiftData

// Copy Idea model for the widget
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

    var displayText: String {
        cleanContent.isEmpty ? content : cleanContent
    }
}

enum DisplayMode: String, CaseIterable {
    case latest = "最新一条"
    case random = "随机一条"
    case multiple = "显示多条"
}

extension UserDefaults {
    static var shared: UserDefaults {
        UserDefaults(suiteName: "group.com.quickidea.app")!
    }
}


struct Provider: TimelineProvider {
    let modelContainer: ModelContainer

    init() {
        do {
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
                try? FileManager.default.removeItem(at: modelConfiguration.url)
                modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            }
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    func placeholder(in context: Context) -> IdeaEntry {
        IdeaEntry(date: Date(), ideas: [
            Idea(content: "记录你的想法 #想法", tags: ["想法"])
        ], displayMode: .latest)
    }

    func getSnapshot(in context: Context, completion: @escaping (IdeaEntry) -> ()) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let entry = createEntry()
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    private func createEntry() -> IdeaEntry {
        let displayMode = getDisplayMode()
        let ideas = fetchIdeas()
        return IdeaEntry(date: Date(), ideas: ideas, displayMode: displayMode)
    }

    private func fetchIdeas() -> [Idea] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<Idea>(
            predicate: #Predicate { !$0.isCompleted },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        do {
            let allIdeas = try context.fetch(descriptor)
            let displayMode = getDisplayMode()

            switch displayMode {
            case .latest:
                return Array(allIdeas.prefix(1))
            case .random:
                if let randomIdea = allIdeas.randomElement() {
                    return [randomIdea]
                }
                return []
            case .multiple:
                return Array(allIdeas.prefix(3))
            }
        } catch {
            return []
        }
    }

    private func getDisplayMode() -> DisplayMode {
        let savedMode = UserDefaults.shared.string(forKey: "displayMode") ?? DisplayMode.latest.rawValue
        return DisplayMode(rawValue: savedMode) ?? .latest
    }
}

struct IdeaEntry: TimelineEntry {
    let date: Date
    let ideas: [Idea]
    let displayMode: DisplayMode
}

struct QuickIdeaWidgetEntryView: View {
    @Environment(\.widgetFamily) var widgetFamily
    var entry: Provider.Entry

    // Refined Flomo 主题色
    private let accentColor = Color(red: 0x30/255, green: 0xcf/255, blue: 0x79/255) // #30cf79
    private let widgetBackground = Color(red: 0xf2/255, green: 0xf2/255, blue: 0xf2/255) // #f2f2f2

    var body: some View {
        Group {
            if entry.ideas.isEmpty {
                emptyView
            } else {
                switch widgetFamily {
                case .accessoryCircular:
                    circularView
                case .accessoryRectangular:
                    rectangularView
                case .accessoryInline:
                    inlineView
                case .systemSmall:
                    smallWidgetView
                case .systemMedium:
                    mediumWidgetView
                default:
                    smallWidgetView
                }
            }
        }
        .containerBackground(for: .widget) {
            widgetBackground
        }
    }

    private var emptyView: some View {
        VStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.title2)
            Text("还没有想法")
                .font(.caption)
        }
        .foregroundStyle(.secondary)
    }

    private var circularView: some View {
        ZStack {
            AccessoryWidgetBackground()
            if let idea = entry.ideas.first, !idea.tags.isEmpty {
                Text("#")
                    .font(.title2)
                    .fontWeight(.bold)
            } else {
                Image(systemName: "lightbulb.fill")
                    .font(.title3)
            }
        }
    }

    private var rectangularView: some View {
        HStack(spacing: 8) {
            if let idea = entry.ideas.first {
                Image(systemName: "number")
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text(idea.displayText)
                        .font(.caption)
                        .lineLimit(2)
                        .fontWeight(.medium)

                    if let firstTag = idea.tags.first {
                        Text("#\(firstTag)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var inlineView: some View {
        if let idea = entry.ideas.first {
            if let firstTag = idea.tags.first {
                Text("#\(firstTag) \(idea.displayText)")
                    .lineLimit(1)
            } else {
                Text(idea.displayText)
                    .lineLimit(1)
            }
        } else {
            Text("还没有想法")
        }
    }

    private var smallWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(accentColor)
                Text("我的想法")
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
            }

            if let idea = entry.ideas.first {
                VStack(alignment: .leading, spacing: 8) {
                    // 显示标签
                    if !idea.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(idea.tags.prefix(2), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(accentColor.opacity(0.08))
                                    .foregroundStyle(accentColor)
                                    .clipShape(Capsule())
                            }
                        }
                    }

                    // 显示内容
                    Text(idea.displayText)
                        .font(.subheadline)
                        .lineLimit(idea.tags.isEmpty ? 5 : 4)
                }

                Spacer()

                Text(entry.displayMode.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var mediumWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundStyle(accentColor)
                Text("我的想法")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text(entry.displayMode.rawValue)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if entry.ideas.count == 1, let idea = entry.ideas.first {
                singleIdeaView(idea: idea)
            } else {
                multipleIdeasView
            }
        }
        .padding()
    }

    private func singleIdeaView(idea: Idea) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标签
            if !idea.tags.isEmpty {
                HStack(spacing: 6) {
                    ForEach(idea.tags.prefix(3), id: \.self) { tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(accentColor.opacity(0.08))
                            .foregroundStyle(accentColor)
                            .clipShape(Capsule())
                    }
                }
            }

            // 内容
            Text(idea.displayText)
                .font(.body)
                .lineLimit(idea.tags.isEmpty ? 6 : 5)

            Spacer()

            // 时间
            Text(shortDateString(idea.createdAt))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func shortDateString(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }
    }

    private var multipleIdeasView: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(Array(entry.ideas.enumerated()), id: \.element.id) { index, idea in
                HStack(alignment: .top, spacing: 10) {
                    // 标签图标或序号
                    if !idea.tags.isEmpty {
                        Text("#")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(accentColor)
                    } else {
                        Text("\(index + 1)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(width: 20, height: 20)
                            .background(accentColor.opacity(0.08))
                            .clipShape(Circle())
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(idea.displayText)
                            .font(.subheadline)
                            .lineLimit(2)

                        if let firstTag = idea.tags.first {
                            Text("#\(firstTag)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }

                if index < entry.ideas.count - 1 {
                    Divider()
                }
            }

            Spacer()
        }
    }
}

@main
struct QuickIdeaWidget: Widget {
    let kind: String = "QuickIdeaWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            QuickIdeaWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("我的想法")
        .description("快速查看你记录的想法")
        .supportedFamilies([
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
            .systemSmall,
            .systemMedium
        ])
    }
}
