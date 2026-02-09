import SwiftUI
import SwiftData

struct ThemePreviewView: View {
    @StateObject private var themeManager = ThemeManager()
    @Environment(\.modelContext) private var modelContext

    // 示例数据
    private let sampleIdeas = [
        ("完成项目文档 #工作 #待办", ["工作", "待办"]),
        ("学习 SwiftUI 动画 #学习 #编程", ["学习", "编程"]),
        ("周末去爬山 #生活 #运动", ["生活", "运动"])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // 主题选择器
                    themeSelector

                    // 预览卡片
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        themePreviewCard(theme: theme)
                    }
                }
                .padding()
            }
            .background(themeManager.currentTheme.colors.background)
            .navigationTitle("主题预览")
            .navigationBarTitleDisplayMode(.large)
        }
        .environmentObject(themeManager)
    }

    // 主题选择器
    private var themeSelector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择主题")
                .font(.headline)
                .foregroundColor(themeManager.currentTheme.colors.primaryText)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                themeManager.currentTheme = theme
                            }
                        } label: {
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(theme.colors.accent)
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                            .opacity(themeManager.currentTheme == theme ? 1 : 0)
                                    )

                                Text(theme.rawValue)
                                    .font(.caption)
                                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(themeManager.currentTheme.colors.cardBackground)
        .cornerRadius(16)
        .shadow(color: themeManager.currentTheme.colors.shadowColor, radius: 10, y: 4)
    }

    // 主题预览卡片
    private func themePreviewCard(theme: AppTheme) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // 标题
            HStack {
                Text(theme.rawValue)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(theme.colors.primaryText)

                Spacer()

                if themeManager.currentTheme == theme {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(theme.colors.accent)
                        .font(.title3)
                }
            }

            // 想法示例
            VStack(spacing: 12) {
                ForEach(Array(sampleIdeas.enumerated()), id: \.offset) { index, item in
                    ideaRowPreview(
                        content: item.0,
                        tags: item.1,
                        theme: theme.colors
                    )
                }
            }

            // 按钮示例
            HStack(spacing: 12) {
                Button {
                    withAnimation(.spring()) {
                        themeManager.currentTheme = theme
                    }
                } label: {
                    Text("应用此主题")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(theme.colors.accent)
                        .cornerRadius(12)
                }

                Button {} label: {
                    Image(systemName: "heart")
                        .foregroundColor(theme.colors.accent)
                        .frame(width: 44, height: 44)
                        .background(theme.colors.secondaryBackground)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(theme.colors.cardBackground)
        .cornerRadius(20)
        .shadow(color: theme.colors.shadowColor, radius: 15, y: 5)
    }

    // 想法行预览
    private func ideaRowPreview(content: String, tags: [String], theme: ThemeColors) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // 标签
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Array(tags.enumerated()), id: \.offset) { index, tag in
                        Text("#\(tag)")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(theme.tagColors[index % theme.tagColors.count].opacity(0.15))
                            .foregroundColor(theme.tagColors[index % theme.tagColors.count])
                            .cornerRadius(8)
                    }
                }
            }

            // 内容
            Text(content.replacingOccurrences(of: " #\\w+", with: "", options: .regularExpression))
                .font(.body)
                .foregroundColor(theme.primaryText)

            // 时间
            Text("2 小时前")
                .font(.caption)
                .foregroundColor(theme.secondaryText)
        }
        .padding()
        .background(theme.secondaryBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ThemePreviewView()
        .modelContainer(for: Idea.self, inMemory: true)
}
