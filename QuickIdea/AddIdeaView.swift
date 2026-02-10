import SwiftUI
import SwiftData

struct AddIdeaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tagManager = TagManager.shared
    @EnvironmentObject var themeManager: ThemeManager

    var editingIdea: Idea? = nil

    @State private var content = ""
    @FocusState private var isFocused: Bool

    // 实时提取的标签
    private var detectedTags: [String] {
        Idea.extractTags(from: content)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // 背景
                themeManager.currentTheme.colors.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // 标签建议区域
                    if !tagManager.recentTags.isEmpty || !TagManager.suggestedTags.isEmpty {
                        tagSuggestions
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                    }

                    // 输入区域
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $content)
                            .focused($isFocused)
                            .frame(maxHeight: .infinity)
                            .padding(16)
                            .scrollContentBackground(.hidden)
                            .foregroundColor(themeManager.currentTheme.colors.primaryText)

                        if content.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "number")
                                    .font(.system(size: 40))
                                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                                Text("输入想法,用 #标签 来分类")
                                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                                    .multilineTextAlignment(.center)
                                Text("例如: 今天要完成项目文档 #工作 #待办")
                                    .font(.caption)
                                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText.opacity(0.7))
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.top, 80)
                            .frame(maxWidth: .infinity)
                            .allowsHitTesting(false)
                        }
                    }

                    // 当前已输入的标签
                    if !detectedTags.isEmpty {
                        currentTagsView
                            .padding()
                    }
                }
            }
            .navigationTitle(editingIdea != nil ? "编辑想法" : "记录想法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.currentTheme.colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveIdea()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.accent)
                }
            }
            .onAppear {
                if let idea = editingIdea {
                    content = idea.content
                }
                isFocused = true
            }
        }
    }

    private var tagSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速添加标签")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 常用标签
                    ForEach(TagManager.suggestedTags, id: \.self) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: detectedTags.contains(tag),
                            theme: themeManager.currentTheme.colors
                        ) {
                            insertTag(tag)
                        }
                    }

                    // 最近使用的标签
                    ForEach(tagManager.recentTags.filter { !TagManager.suggestedTags.contains($0) }.prefix(5), id: \.self) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: detectedTags.contains(tag),
                            isRecent: true,
                            theme: themeManager.currentTheme.colors
                        ) {
                            insertTag(tag)
                        }
                    }
                }
            }
        }
    }

    private var currentTagsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已添加的标签")
                .font(.caption)
                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(detectedTags.enumerated()), id: \.offset) { index, tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(themeManager.currentTheme.colors.accent.opacity(0.08))
                        .foregroundStyle(themeManager.currentTheme.colors.accent)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func insertTag(_ tag: String) {
        if detectedTags.contains(tag) {
            return
        }

        if content.isEmpty {
            content = "#\(tag) "
        } else if content.hasSuffix(" ") {
            content += "#\(tag) "
        } else {
            content += " #\(tag) "
        }
    }

    private func removeTag(_ tag: String) {
        content = content.replacingOccurrences(of: "#\(tag)", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    private func saveIdea() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        let tags = Idea.extractTags(from: trimmedContent)

        if let existing = editingIdea {
            // ✅ 编辑模式：更新内容、标签和修改时间
            existing.content = trimmedContent
            existing.tags = tags
            existing.updatedAt = Date()  // 关键：更新修改时间
        } else {
            // 新建模式
            let idea = Idea(content: trimmedContent, tags: tags)
            modelContext.insert(idea)
        }

        tagManager.addTags(tags)
        dismiss()
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    var isRecent: Bool = false
    let theme: ThemeColors
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if isRecent {
                    Image(systemName: "clock")
                        .font(.caption2)
                }
                Text("#\(tag)")
                    .font(.subheadline)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? theme.accent.opacity(0.08) : theme.secondaryBackground)
            .foregroundStyle(isSelected ? theme.accent : theme.secondaryText)
            .clipShape(Capsule())
        }
        .disabled(isSelected)
    }
}

#Preview {
    AddIdeaView()
        .modelContainer(for: Idea.self, inMemory: true)
        .environmentObject(ThemeManager())
}

