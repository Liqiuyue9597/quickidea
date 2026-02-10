import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: IdeaStore
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // 显示模式设置
                VStack(alignment: .leading, spacing: 12) {
                    Text("小组件显示方式")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.colors.primaryText)
                        .padding(.horizontal)

                    VStack(spacing: 8) {
                        ForEach(DisplayMode.allCases, id: \.self) { mode in
                            Button {
                                store.displayMode = mode
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(mode.rawValue)
                                            .foregroundStyle(themeManager.currentTheme.colors.primaryText)
                                            .fontWeight(store.displayMode == mode ? .semibold : .regular)
                                        Text(mode.description)
                                            .font(.caption)
                                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                                    }

                                    Spacer()

                                    if store.displayMode == mode {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(themeManager.currentTheme.colors.accent)
                                            .fontWeight(.semibold)
                                    }
                                }
                                .padding()
                                .glassCard(theme: themeManager.currentTheme.colors)
                            }
                        }
                    }
                    .padding(.horizontal)

                    Text("选择小组件展示想法的方式。更改后需要刷新小组件才能生效。")
                        .font(.caption)
                        .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                        .padding(.horizontal)
                }

                // 关于
                VStack(alignment: .leading, spacing: 12) {
                    Text("关于")
                        .font(.headline)
                        .foregroundColor(themeManager.currentTheme.colors.primaryText)
                        .padding(.horizontal)

                    HStack {
                        Text("版本")
                            .foregroundStyle(themeManager.currentTheme.colors.primaryText)
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                    }
                    .padding()
                    .glassCard(theme: themeManager.currentTheme.colors)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(IdeaStore.shared)
        .environmentObject(ThemeManager())
}
