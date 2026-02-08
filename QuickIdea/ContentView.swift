import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

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
    }
}

#Preview {
    ContentView()
        .environmentObject(IdeaStore.shared)
}
