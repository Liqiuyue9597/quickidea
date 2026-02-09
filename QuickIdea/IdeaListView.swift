import SwiftUI
import SwiftData

struct IdeaListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Idea.createdAt, order: .reverse) private var ideas: [Idea]
    @State private var showingAddIdea = false
    @State private var selectedTag: String?
    @StateObject private var themeManager = ThemeManager()

    // 获取所有使用过的标签
    private var allTags: [String] {
        var tags = Set<String>()
        ideas.forEach { idea in
            idea.tags.forEach { tags.insert($0) }
        }
        return Array(tags).sorted()
    }

    // 获取每个标签的使用次数
    private func tagCount(_ tag: String) -> Int {
        ideas.filter { $0.tags.contains(tag) }.count
    }

    var filteredIdeas: [Idea] {
        if let tag = selectedTag {
            return ideas.filter { $0.tags.contains(tag) }
        }
        return ideas
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                themeManager.currentTheme.colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    tagFilter

                    if filteredIdeas.isEmpty {
                        emptyState
                    } else {
                        ideaList
                    }
                }
            }
            .navigationTitle(selectedTag != nil ? "#\(selectedTag!)" : "我的想法")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(themeManager.currentTheme.colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddIdea = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(themeManager.currentTheme.colors.accent)
                    }
                }
            }
            .sheet(isPresented: $showingAddIdea) {
                AddIdeaView()
                    .environmentObject(themeManager)
            }
        }
    }

    private var tagFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "全部",
                    count: ideas.count,
                    isSelected: selectedTag == nil,
                    theme: themeManager.currentTheme.colors
                ) {
                    selectedTag = nil
                }

                ForEach(allTags, id: \.self) { tag in
                    FilterChip(
                        title: "#\(tag)",
                        count: tagCount(tag),
                        isSelected: selectedTag == tag,
                        theme: themeManager.currentTheme.colors
                    ) {
                        selectedTag = tag
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(themeManager.currentTheme.colors.background)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标签行
            if !idea.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(Array(idea.tags.enumerated()), id: \.offset) { index, tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(theme.tagColors[index % theme.tagColors.count].opacity(0.2))
                                .foregroundStyle(theme.tagColors[index % theme.tagColors.count])
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule()
                                        .stroke(theme.tagColors[index % theme.tagColors.count].opacity(0.3), lineWidth: 1)
                                )
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

            // 内容（移除标签的纯文本）
            Text(idea.cleanContent.isEmpty ? idea.content : idea.cleanContent)
                .font(.body)
                .strikethrough(idea.isCompleted)
                .foregroundStyle(idea.isCompleted ? theme.secondaryText : theme.primaryText)

            // 时间
            (Text(idea.createdAt, style: .relative) + Text(" 前"))
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
                        .foregroundStyle(isSelected ? theme.primaryText.opacity(0.8) : theme.secondaryText)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? theme.accent.opacity(0.3) : theme.secondaryBackground)
            .foregroundStyle(isSelected ? theme.primaryText : theme.secondaryText)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? theme.accent : theme.borderColor, lineWidth: 1)
            )
        }
    }
}

#Preview {
    IdeaListView()
        .modelContainer(for: Idea.self, inMemory: true)
}

