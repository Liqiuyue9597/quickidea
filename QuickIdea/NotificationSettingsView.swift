import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @ObservedObject var notificationManager: NotificationManager
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss

    @State private var showingTimePicker = false
    @State private var newTime = Date()

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.colors.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // 开关
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: Binding(
                                get: { notificationManager.isEnabled },
                                set: { _ in
                                    Task {
                                        if !notificationManager.isEnabled {
                                            let granted = await notificationManager.requestAuthorization()
                                            if granted {
                                                notificationManager.toggleNotifications(with: modelContext)
                                            }
                                        } else {
                                            notificationManager.toggleNotifications(with: modelContext)
                                        }
                                    }
                                }
                            )) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("开启灵感提醒")
                                        .font(.headline)
                                        .foregroundStyle(themeManager.currentTheme.colors.primaryText)

                                    Text("每天定时推送一条未处理的灵感")
                                        .font(.caption)
                                        .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                                }
                            }
                            .tint(themeManager.currentTheme.colors.accent)
                            .padding()
                            .background(themeManager.currentTheme.colors.secondaryBackground)
                            .cornerRadius(12)
                        }

                        if notificationManager.isEnabled {
                            // 提醒时间列表
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("提醒时间")
                                        .font(.headline)
                                        .foregroundStyle(themeManager.currentTheme.colors.primaryText)

                                    Spacer()

                                    Button {
                                        showingTimePicker = true
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.title3)
                                            .foregroundStyle(themeManager.currentTheme.colors.accent)
                                    }
                                }
                                .padding(.horizontal)

                                ForEach(Array(notificationManager.notificationTimes.enumerated()), id: \.offset) { index, time in
                                    HStack {
                                        Image(systemName: "bell.fill")
                                            .foregroundStyle(themeManager.currentTheme.colors.accent)

                                        Text(timeString(from: time))
                                            .font(.body)
                                            .foregroundStyle(themeManager.currentTheme.colors.primaryText)

                                        Spacer()

                                        Button {
                                            notificationManager.removeNotificationTime(at: index)
                                            notificationManager.scheduleNotifications(with: modelContext)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.subheadline)
                                                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                                        }
                                    }
                                    .padding()
                                    .background(themeManager.currentTheme.colors.secondaryBackground)
                                    .cornerRadius(12)
                                }
                            }

                            // 说明
                            VStack(alignment: .leading, spacing: 8) {
                                Label("每次提醒会随机显示一条未处理的灵感", systemImage: "info.circle")
                                    .font(.caption)
                                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)

                                Label("新增或删除时间后会立即生效", systemImage: "info.circle")
                                    .font(.caption)
                                    .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("通知提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.currentTheme.colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.accent)
                }
            }
            .sheet(isPresented: $showingTimePicker) {
                timePickerSheet
            }
        }
    }

    private var timePickerSheet: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.colors.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Text("选择提醒时间")
                        .font(.headline)
                        .foregroundStyle(themeManager.currentTheme.colors.primaryText)

                    DatePicker("", selection: $newTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }
                .padding()
            }
            .navigationTitle("添加提醒")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.currentTheme.colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showingTimePicker = false
                    }
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        notificationManager.addNotificationTime(newTime)
                        notificationManager.scheduleNotifications(with: modelContext)
                        showingTimePicker = false
                        newTime = Date()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.accent)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
