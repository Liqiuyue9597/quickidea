import SwiftUI
import SwiftData

struct AddIdeaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tagManager = TagManager.shared

    @State private var content = ""
    @FocusState private var isFocused: Bool

    // 实时提取的标签
    private var detectedTags: [String] {
        Idea.extractTags(from: content)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 标签建议区域
                if !tagManager.recentTags.isEmpty || !TagManager.suggestedTags.isEmpty {
                    tagSuggestions
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(.systemGroupedBackground))
                }

                // 输入区域
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $content)
                        .focused($isFocused)
                        .frame(maxHeight: .infinity)
                        .padding(12)
                        .background(Color(.systemBackground))
                        .scrollContentBackground(.hidden)

                    if content.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "number")
                                .font(.system(size: 40))
                                .foregroundStyle(.secondary)
                            Text("输入想法，用 #标签 来分类")
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Text("例如: 今天要完成项目文档 #工作 #待办")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
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
                        .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("记录想法")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveIdea()
                    }
                    .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private var tagSuggestions: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("快速添加标签")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // 常用标签
                    ForEach(TagManager.suggestedTags, id: \.self) { tag in
                        TagChip(tag: tag, isSelected: detectedTags.contains(tag)) {
                            insertTag(tag)
                        }
                    }

                    // 最近使用的标签
                    ForEach(tagManager.recentTags.filter { !TagManager.suggestedTags.contains($0) }.prefix(5), id: \.self) { tag in
                        TagChip(tag: tag, isSelected: detectedTags.contains(tag), isRecent: true) {
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
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(detectedTags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text("#\(tag)")
                                .font(.subheadline)
                                .fontWeight(.medium)

                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.15))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func insertTag(_ tag: String) {
        // 如果已经包含这个标签，不重复添加
        if detectedTags.contains(tag) {
            return
        }

        // 在内容末尾添加标签
        if content.isEmpty {
            content = "#\(tag) "
        } else if content.hasSuffix(" ") {
            content += "#\(tag) "
        } else {
            content += " #\(tag) "
        }
    }

    private func removeTag(_ tag: String) {
        // 移除标签
        content = content.replacingOccurrences(of: "#\(tag)", with: "")
            .replacingOccurrences(of: "  ", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    private func saveIdea() {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else { return }

        // 提取标签
        let tags = Idea.extractTags(from: trimmedContent)

        // 创建想法
        let idea = Idea(content: trimmedContent, tags: tags)
        modelContext.insert(idea)

        // 保存到最近使用的标签
        tagManager.addTags(tags)

        dismiss()
    }
}

struct TagChip: View {
    let tag: String
    let isSelected: Bool
    var isRecent: Bool = false
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
            .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemGray5))
            .foregroundStyle(isSelected ? .blue : .primary)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
            )
        }
        .disabled(isSelected)
    }
}

#Preview {
    AddIdeaView()
        .modelContainer(for: Idea.self, inMemory: true)
}

