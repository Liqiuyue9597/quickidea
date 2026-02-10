import SwiftUI
import SwiftData

struct IdeaListView: View {
    @Environment(\.modelContext) private var modelContext
    // ✅ 按 updatedAt 排序
    @Query(sort: \Idea.updatedAt, order: .reverse) private var ideas: [Idea]
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var selectedTag: String?
    @State private var editingIdea: Idea?

    var filteredIdeas: [Idea] {
        if let tag = selectedTag {
            return ideas.filter { $0.tags.contains(tag) }
        }
        return ideas
    }

    var body: some View {
        ZStack {
            themeManager.currentTheme.colors.background
                .ignoresSafeArea()

            if filteredIdeas.isEmpty {
                emptyState
            } else {
                ideaList
            }
        }
        .sheet(item: $editingIdea) { idea in
            AddIdeaView(editingIdea: idea)
                .environmentObject(themeManager)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTag == nil ? "lightbulb" : "tag")
                .font(.system(size: 60))
                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)

            if selectedTag == nil {
                Text("还没有想法")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.primaryText)

                Text("点击右上角 + 记录你的第一个想法")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    .multilineTextAlignment(.center)
            } else {
                Text("没有 #\(selectedTag!) 标签的想法")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.primaryText)

                Text("点击「全部」查看所有想法")
                    .font(.subheadline)
                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ideaList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(filteredIdeas) { idea in
                    IdeaRow(idea: idea, theme: themeManager.currentTheme.colors) { newStatus in
                        changeStatus(idea, to: newStatus)
                    }
                    .onTapGesture {
                        editingIdea = idea
                    }
                    .contextMenu {
                        // 状态切换菜单
                        Menu {
                            ForEach(IdeaStatus.allCases, id: \.self) { status in
                                if status != idea.status {
                                    Button {
                                        changeStatus(idea, to: status)
                                    } label: {
                                        Label(status.rawValue, systemImage: status.icon)
                                    }
                                }
                            }
                        } label: {
                            Label("更改状态", systemImage: "arrow.left.arrow.right")
                        }

                        Divider()

                        Button(role: .destructive) {
                            deleteIdea(idea)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                }
            }
            .padding(.top, 8)
        }
    }

    private func changeStatus(_ idea: Idea, to status: IdeaStatus) {
        withAnimation {
            idea.status = status
        }
        // 刷新 Widget（状态改变可能影响"未处理"数量）
        WidgetRefreshManager.shared.reloadAllWidgets()
    }

    private func deleteIdea(_ idea: Idea) {
        modelContext.delete(idea)
        // 刷新 Widget
        WidgetRefreshManager.shared.reloadAllWidgets()
    }
}

struct IdeaRow: View {
    let idea: Idea
    let theme: ThemeColors
    @State private var offset: CGFloat = 0
    let onStatusChange: (IdeaStatus) -> Void

    private var formattedDate: String {
        let calendar = Calendar.current
        let displayDate = idea.updatedAt

        if calendar.isDateInToday(displayDate) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: displayDate)
        } else if calendar.isDateInYesterday(displayDate) {
            return "昨天"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "M月d日"
            return formatter.string(from: displayDate)
        }
    }

    var body: some View {
        ZStack {
            // 背景手势提示
            HStack {
                // 左滑：标记进行中
                if offset < 0 {
                    Spacer()
                    VStack(spacing: 4) {
                        Image(systemName: IdeaStatus.inProgress.icon)
                            .font(.title3)
                        Text("进行中")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: -offset * 0.5)
                    .padding(.trailing, 16)
                }

                // 右滑：标记完成
                if offset > 0 {
                    VStack(spacing: 4) {
                        Image(systemName: IdeaStatus.completed.icon)
                            .font(.title3)
                        Text("完成")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundStyle(.white)
                    .frame(width: offset * 0.5)
                    .padding(.leading, 16)
                    Spacer()
                }
            }
            .frame(maxWidth: .infinity)
            .background(
                offset > 0
                    ? Color(hex: IdeaStatus.completed.color)
                    : Color(hex: IdeaStatus.inProgress.color)
            )
            .cornerRadius(12)

            // 主卡片内容
            cardContent
                .background(theme.cardBackground)
                .cornerRadius(12)
                .shadow(color: theme.shadowColor, radius: 2, y: 1)
                .offset(x: offset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            // 限制滑动范围
                            if abs(value.translation.width) < 120 {
                                offset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            withAnimation(.spring(response: 0.3)) {
                                if value.translation.width > 80 {
                                    // 右滑超过阈值：标记完成
                                    onStatusChange(.completed)
                                    offset = 0
                                } else if value.translation.width < -80 {
                                    // 左滑超过阈值：标记进行中
                                    onStatusChange(.inProgress)
                                    offset = 0
                                } else {
                                    // 未达到阈值：回弹
                                    offset = 0
                                }
                            }
                        }
                )
        }
        .padding(.horizontal)
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标签和状态
            HStack(spacing: 8) {
                if !idea.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(Array(idea.tags.enumerated()), id: \.offset) { index, tag in
                                Text("#\(tag)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color(hex: idea.status.color).opacity(0.08))
                                    .foregroundStyle(Color(hex: idea.status.color))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                Spacer()

                // 状态图标
                HStack(spacing: 4) {
                    Image(systemName: idea.status.icon)
                        .font(.caption)
                    Text(idea.status.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(Color(hex: idea.status.color))
            }

            // 内容
            Text(idea.cleanContent.isEmpty ? idea.content : idea.cleanContent)
                .font(.body)
                .strikethrough(idea.status == .completed || idea.status == .archived)
                .foregroundStyle(
                    idea.status == .completed || idea.status == .archived
                        ? theme.secondaryText
                        : theme.primaryText
                )
                .lineLimit(3)

            // 图片预览
            if !idea.imageData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(idea.imageData.prefix(3).enumerated()), id: \.offset) { index, data in
                            if let image = UIImage(data: data) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 60, height: 60)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }

                        if idea.imageData.count > 3 {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(theme.secondaryBackground)
                                    .frame(width: 60, height: 60)

                                Text("+\(idea.imageData.count - 3)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(theme.secondaryText)
                            }
                        }
                    }
                }
            }

            // 时间
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
        }
        .padding(16)
    }
}

struct FilterChip: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
    let theme: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)

                if let count = count {
                    Text("\(count)")
                        .font(.caption2)
                        .foregroundStyle(isSelected ? theme.accent.opacity(0.8) : theme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? theme.accent.opacity(0.08) : theme.secondaryBackground)
            .foregroundStyle(isSelected ? theme.accent : theme.secondaryText)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    IdeaListView(selectedTag: .constant(nil))
        .modelContainer(for: Idea.self, inMemory: true)
        .environmentObject(ThemeManager())
}
