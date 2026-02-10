import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var notificationManager = NotificationManager.shared
    @EnvironmentObject var store: IdeaStore
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Idea.updatedAt, order: .reverse) private var ideas: [Idea]

    @State private var selectedTag: String?
    @State private var showSidebar = false
    @State private var quickInputText = ""
    @State private var showingSpeechSheet = false
    @State private var showingNotificationSettings = false
    @FocusState private var isInputFocused: Bool

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

    // 未处理灵感数量
    private var pendingCount: Int {
        ideas.filter { $0.status == .pending }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 快速输入区域
                    quickInputBar

                    // 主内容列表
                    IdeaListView(selectedTag: $selectedTag)
                }

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
            .navigationTitle(selectedTag != nil ? "#\(selectedTag!)" : "我的灵感")
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
            }
        }
        .environmentObject(themeManager)
        .accentColor(themeManager.currentTheme.colors.accent)
        .sheet(isPresented: $showingNotificationSettings) {
            NotificationSettingsView(notificationManager: notificationManager)
                .environmentObject(themeManager)
        }
        .onAppear {
            // 初始化通知
            notificationManager.scheduleNotifications(with: modelContext)
        }
    }

    // MARK: - 快速输入栏
    private var quickInputBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // 灵感图标
                Image(systemName: "lightbulb.fill")
                    .font(.title2)
                    .foregroundStyle(themeManager.currentTheme.colors.accent)

                // 输入框
                TextField("记录新灵感...", text: $quickInputText)
                    .focused($isInputFocused)
                    .font(.body)
                    .foregroundColor(themeManager.currentTheme.colors.primaryText)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                    .background(themeManager.currentTheme.colors.secondaryBackground)
                    .cornerRadius(12)
                    .onSubmit {
                        saveQuickIdea()
                    }

                // 快捷按钮
                HStack(spacing: 8) {
                    Button {
                        showingSpeechSheet = true
                    } label: {
                        Image(systemName: "mic.fill")
                            .font(.title3)
                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    }

                    Button {
                        // 图片添加功能（后续实现）
                    } label: {
                        Image(systemName: "photo")
                            .font(.title3)
                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            // 快捷标签
            if !TagManager.suggestedTags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(TagManager.suggestedTags, id: \.self) { tag in
                            Button {
                                insertQuickTag(tag)
                            } label: {
                                Text("#\(tag)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(themeManager.currentTheme.colors.accent.opacity(0.08))
                                    .foregroundStyle(themeManager.currentTheme.colors.accent)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 12)
        .background(themeManager.currentTheme.colors.background)
        .sheet(isPresented: $showingSpeechSheet) {
            SpeechInputView(speechRecognizer: speechRecognizer) { transcribedText in
                quickInputText = transcribedText
                showingSpeechSheet = false
                isInputFocused = true
            }
            .environmentObject(themeManager)
        }
    }

    private func insertQuickTag(_ tag: String) {
        if quickInputText.isEmpty {
            quickInputText = "#\(tag) "
        } else if quickInputText.hasSuffix(" ") {
            quickInputText += "#\(tag) "
        } else {
            quickInputText += " #\(tag) "
        }
        isInputFocused = true
    }

    private func saveQuickIdea() {
        let trimmed = quickInputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let tags = Idea.extractTags(from: trimmed)
        let idea = Idea(content: trimmed, tags: tags)
        modelContext.insert(idea)

        TagManager.shared.addTags(tags)
        quickInputText = ""

        // 刷新 Widget
        WidgetRefreshManager.shared.reloadAllWidgets()
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

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(ideas.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.colors.primaryText)
                        Text("全部灵感")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(pendingCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(themeManager.currentTheme.colors.accent)
                        Text("未处理")
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

                // 通知提醒设置
                Button {
                    showingNotificationSettings = true
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showSidebar = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                            .foregroundStyle(themeManager.currentTheme.colors.accent)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("通知提醒")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(themeManager.currentTheme.colors.primaryText)

                            Text(notificationManager.isEnabled ? "已开启" : "未开启")
                                .font(.caption2)
                                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    }
                    .padding(.vertical, 8)
                }

                Divider()
                    .background(themeManager.currentTheme.colors.divider)
                    .padding(.vertical, 4)

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
