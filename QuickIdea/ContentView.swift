import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var themeManager = ThemeManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            IdeaListView()
                .tabItem {
                    Label("想法", systemImage: "lightbulb.fill")
                }
                .tag(0)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(1)
        }
        .environmentObject(themeManager)
        .preferredColorScheme(.dark)
        .accentColor(themeManager.currentTheme.colors.accent)
    }
}

#Preview {
    ContentView()
        .environmentObject(IdeaStore.shared)
}
