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
                    IdeaRow(idea: idea, theme: themeManager.currentTheme.colors)
                        .onTapGesture {
                            editingIdea = idea
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                deleteIdea(idea)
                            } label: {
                                Label("删除", systemImage: "trash")
                            }

                            Button {
                                toggleComplete(idea)
                            } label: {
                                Label(
                                    idea.isCompleted ? "取消完成" : "完成",
                                    systemImage: idea.isCompleted ? "arrow.uturn.backward" : "checkmark"
                                )
                            }
                        }
                }
            }
            .padding()
        }
    }

    private func deleteIdea(_ idea: Idea) {
        modelContext.delete(idea)
    }

    private func toggleComplete(_ idea: Idea) {
        idea.isCompleted.toggle()
    }
}

struct IdeaRow: View {
    let idea: Idea
    let theme: ThemeColors

    private var formattedDate: String {
        let calendar = Calendar.current
        // ✅ 使用 updatedAt 显示最后修改时间
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
        VStack(alignment: .leading, spacing: 12) {
            if !idea.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(idea.tags.enumerated()), id: \.offset) { index, tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(theme.accent.opacity(0.08))
                                .foregroundStyle(theme.accent)
                                .clipShape(Capsule())
                        }

                        if idea.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(theme.accent)
                                .font(.caption)
                        }
                    }
                }
            } else if idea.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(theme.accent)
                }
            }

            Text(idea.cleanContent.isEmpty ? idea.content : idea.cleanContent)
                .font(.body)
                .strikethrough(idea.isCompleted)
                .foregroundStyle(idea.isCompleted ? theme.secondaryText : theme.primaryText)

            // ✅ 显示修改时间
            Text(formattedDate)
                .font(.caption)
                .foregroundStyle(theme.secondaryText)
        }
        .padding(16)
        .glassCard(theme: theme)
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
