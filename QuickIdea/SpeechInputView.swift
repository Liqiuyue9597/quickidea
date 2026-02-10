import SwiftUI

struct SpeechInputView: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    let onComplete: (String) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                themeManager.currentTheme.colors.background
                    .ignoresSafeArea()

                VStack(spacing: 32) {
                    Spacer()

                    // 录音动画
                    ZStack {
                        // 外圈动画
                        if speechRecognizer.isRecording {
                            Circle()
                                .stroke(themeManager.currentTheme.colors.accent.opacity(0.3), lineWidth: 4)
                                .frame(width: 160, height: 160)
                                .scaleEffect(speechRecognizer.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: speechRecognizer.isRecording)

                            Circle()
                                .stroke(themeManager.currentTheme.colors.accent.opacity(0.2), lineWidth: 4)
                                .frame(width: 200, height: 200)
                                .scaleEffect(speechRecognizer.isRecording ? 1.4 : 1.0)
                                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: speechRecognizer.isRecording)
                        }

                        // 麦克风按钮
                        Button {
                            if speechRecognizer.isRecording {
                                speechRecognizer.stopRecording()
                            } else {
                                speechRecognizer.startRecording()
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(speechRecognizer.isRecording ? themeManager.currentTheme.colors.accent : themeManager.currentTheme.colors.secondaryBackground)
                                    .frame(width: 120, height: 120)
                                    .shadow(color: themeManager.currentTheme.colors.shadowColor, radius: 8, y: 4)

                                Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                                    .font(.system(size: 48))
                                    .foregroundStyle(speechRecognizer.isRecording ? .white : themeManager.currentTheme.colors.accent)
                            }
                        }
                    }

                    // 状态提示
                    VStack(spacing: 8) {
                        if let error = speechRecognizer.errorMessage {
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else if speechRecognizer.isRecording {
                            Text("正在录音...")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(themeManager.currentTheme.colors.primaryText)

                            Text("点击麦克风停止")
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                        } else {
                            Text("点击麦克风开始录音")
                                .font(.title3)
                                .fontWeight(.medium)
                                .foregroundStyle(themeManager.currentTheme.colors.primaryText)

                            Text("支持中文普通话")
                                .font(.caption)
                                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                        }
                    }

                    Spacer()

                    // 识别结果
                    if !speechRecognizer.transcript.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("识别结果")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(themeManager.currentTheme.colors.secondaryText)
                                .textCase(.uppercase)

                            ScrollView {
                                Text(speechRecognizer.transcript)
                                    .font(.body)
                                    .foregroundStyle(themeManager.currentTheme.colors.primaryText)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 150)
                            .padding()
                            .background(themeManager.currentTheme.colors.secondaryBackground)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("语音输入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(themeManager.currentTheme.colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopRecording()
                        }
                        dismiss()
                    }
                    .foregroundColor(themeManager.currentTheme.colors.secondaryText)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") {
                        if speechRecognizer.isRecording {
                            speechRecognizer.stopRecording()
                        }
                        onComplete(speechRecognizer.transcript)
                    }
                    .disabled(speechRecognizer.transcript.isEmpty)
                    .fontWeight(.semibold)
                    .foregroundColor(themeManager.currentTheme.colors.accent)
                }
            }
            .onDisappear {
                if speechRecognizer.isRecording {
                    speechRecognizer.stopRecording()
                }
            }
        }
    }
}
