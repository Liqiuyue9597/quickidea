import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: IdeaStore

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(DisplayMode.allCases, id: \.self) { mode in
                        Button {
                            store.displayMode = mode
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(mode.rawValue)
                                        .foregroundStyle(.primary)
                                        .fontWeight(store.displayMode == mode ? .semibold : .regular)
                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if store.displayMode == mode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                } header: {
                    Text("小组件显示方式")
                } footer: {
                    Text("选择小组件展示想法的方式。更改后需要刷新小组件才能生效。")
                }

                Section {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("关于")
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(IdeaStore.shared)
}
