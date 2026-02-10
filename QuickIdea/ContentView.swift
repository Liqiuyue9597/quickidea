import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @EnvironmentObject var store: IdeaStore
    // 改为按 updatedAt 排序
    @Query(sort: \Idea.updatedAt, order: .reverse) private var ideas: [Idea]

    @State private var selectedTag: String?
    @State private var showSidebar = false
    @State private var showingAddIdea = false

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

    // 已完成的数量
    private var completedCount: Int {
        ideas.filter { $0.isCompleted }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 主内容
                IdeaListView(selectedTag: $selectedTag)

                // 侧栏遮罩
                if showSidebar {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showSidebar = false
                            }
                        }
                }

                // 侧栏
                HStack(spacing: 0) {
                    if showSidebar {
                        sidebarContent
                            .frame(width: 280)
                            .transition(.move(edge: .leading))
                    }
                    Spacer()
                }
            }
            .navigationTitle(selectedTag != nil ? "#\(selectedTag!)" : "我的想法")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(themeManager.currentTheme.colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            showSidebar.toggle()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                            .font(.title3)
                            .foregroundColor(themeManager.currentTheme.colors.primaryText)
                    }
                }
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
        .environmentObject(themeManager)
        .accentColor(themeManager.currentTheme.colors.accent)
    }

    // MARK: - 侧栏内容
    private var sidebarContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 统计区域
            VStack(alignment: .leading, spacing: 12) {
                Text("统计")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    .textCase(.uppercase)

                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(ideas.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.colors.primaryText)
                        Text("全部想法")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(completedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.colors.accent)
                        Text("已完成")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    }
                }
            }
            .padding()

            Divider()
                .background(themeManager.currentTheme.colors.divider)

            // 标签列表
            VStack(alignment: .leading, spacing: 8) {
                Text("标签")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    .textCase(.uppercase)
                    .padding(.horizontal)
                    .padding(.top, 12)

                ScrollView {
                    VStack(spacing: 2) {
                        // 全部
                        sidebarTagRow(title: "全部", count: ideas.count, isSelected: selectedTag == nil) {
                            selectedTag = nil
                            withAnimation(.easeInOut(duration: 0.25)) {
                                showSidebar = false
                            }
                        }

                        // 各标签
                        ForEach(allTags, id: \.self) { tag in
                            sidebarTagRow(title: "#\(tag)", count: tagCount(tag), isSelected: selectedTag == tag) {
                                selectedTag = tag
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showSidebar = false
                                }
                            }
                        }
                    }
                }
            }

            Spacer()

            Divider()
                .background(themeManager.currentTheme.colors.divider)

            // 设置区域
            VStack(alignment: .leading, spacing: 12) {
                Text("设置")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    .textCase(.uppercase)

                // 小组件显示方式
                VStack(alignment: .leading, spacing: 8) {
                    Text("小组件显示方式")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(themeManager.currentTheme.colors.primaryText)

                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Button {
                            store.displayMode = mode
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(mode.rawValue)
                                        .font(.subheadline)
                                        .foregroundStyle(themeManager.currentTheme.colors.primaryText)
                                        .fontWeight(store.displayMode == mode ? .semibold : .regular)
                                    Text(mode.description)
                                        .font(.caption2)
                                        .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                                }

                                Spacer()

                                if store.displayMode == mode {
                                    Image(systemName: "checkmark")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.currentTheme.colors.accent)
                                        .fontWeight(.semibold)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }

                // 版本信息
                HStack {
                    Text("版本")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    Spacer()
                    Text("1.0.0")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(themeManager.currentTheme.colors.secondaryBackground)
        .ignoresSafeArea(edges: .bottom)
    }

    private func sidebarTagRow(title: String, count: Int, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundStyle(isSelected ? themeManager.currentTheme.colors.accent : themeManager.currentTheme.colors.primaryText)

                Spacer()

                Text("\(count)")
                    .font(.caption)
                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(isSelected ? themeManager.currentTheme.colors.accent.opacity(0.08) : Color.clear)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Idea.self, inMemory: true)
        .environmentObject(IdeaStore.shared)
}
