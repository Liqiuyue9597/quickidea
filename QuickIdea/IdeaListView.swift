import SwiftUI
import SwiftData

struct IdeaListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Idea.createdAt, order: .reverse) private var ideas: [Idea]
    @State private var showingAddIdea = false
    @State private var selectedTag: String?

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
            VStack(spacing: 0) {
                tagFilter

                if filteredIdeas.isEmpty {
                    emptyState
                } else {
                    ideaList
                }
            }
            .navigationTitle(selectedTag != nil ? "#\(selectedTag!)" : "我的想法")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddIdea = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddIdea) {
                AddIdeaView()
            }
        }
    }

    private var tagFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "全部",
                    count: ideas.count,
                    isSelected: selectedTag == nil
                ) {
                    selectedTag = nil
                }

                ForEach(allTags, id: \.self) { tag in
                    FilterChip(
                        title: "#\(tag)",
                        count: tagCount(tag),
                        isSelected: selectedTag == tag
                    ) {
                        selectedTag = tag
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedTag == nil ? "lightbulb" : "tag")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            if selectedTag == nil {
                Text("还没有想法")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("点击右上角 + 记录你的第一个想法")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("没有 #\(selectedTag!) 标签的想法")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("点击「全部」查看所有想法")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var ideaList: some View {
        List {
            ForEach(filteredIdeas) { idea in
                IdeaRow(idea: idea)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteIdea(idea)
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            toggleComplete(idea)
                        } label: {
                            Label(
                                idea.isCompleted ? "取消完成" : "完成",
                                systemImage: idea.isCompleted ? "arrow.uturn.backward" : "checkmark"
                            )
                        }
                        .tint(idea.isCompleted ? .orange : .green)
                    }
            }
        }
        .listStyle(.insetGrouped)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标签行
            if !idea.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(idea.tags, id: \.self) { tag in
                            Text("#\(tag)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }

                        if idea.isCompleted {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        }
                    }
                }
            } else if idea.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }
            }

            // 内容（移除标签的纯文本）
            Text(idea.cleanContent.isEmpty ? idea.content : idea.cleanContent)
                .font(.body)
                .strikethrough(idea.isCompleted)
                .foregroundStyle(idea.isCompleted ? .secondary : .primary)

            // 时间
            Text(idea.createdAt, style: .relative) + Text(" 前")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct FilterChip: View {
    let title: String
    var count: Int? = nil
    let isSelected: Bool
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
                        .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray5))
            .foregroundStyle(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

#Preview {
    IdeaListView()
        .modelContainer(for: Idea.self, inMemory: true)
}

