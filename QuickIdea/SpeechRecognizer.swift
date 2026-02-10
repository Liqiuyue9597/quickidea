import Foundation
import Speech
import AVFoundation

@MainActor
class SpeechRecognizer: ObservableObject {
    @Published var transcript = ""
    @Published var isRecording = false
    @Published var isAuthorized = false
    @Published var errorMessage: String?

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

    init() {
        checkAuthorization()
    }

    func checkAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                switch authStatus {
                case .authorized:
                    self?.isAuthorized = true
                case .denied:
                    self?.errorMessage = "语音识别权限被拒绝"
                case .restricted:
                    self?.errorMessage = "语音识别功能受限"
                case .notDetermined:
                    self?.errorMessage = "语音识别权限未确定"
                @unknown default:
                    self?.errorMessage = "未知错误"
                }
            }
        }
    }

    func startRecording() {
        guard isAuthorized else {
            errorMessage = "请在设置中开启语音识别权限"
            return
        }

        // 停止之前的任务
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }

        // 配置音频会话
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "音频会话配置失败: \(error.localizedDescription)"
            return
        }

        // 创建识别请求
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        guard let recognitionRequest = recognitionRequest else {
            errorMessage = "无法创建识别请求"
            return
        }

        recognitionRequest.shouldReportPartialResults = true

        // 配置音频引擎
        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            errorMessage = "无法创建音频引擎"
            return
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()

        do {
            try audioEngine.start()
        } catch {
            errorMessage = "音频引擎启动失败: \(error.localizedDescription)"
            return
        }

        // 开始识别
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil || result?.isFinal == true {
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }

        isRecording = true
        transcript = ""
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil

        isRecording = false

        // 停止音频会话
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("停止音频会话失败: \(error)")
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
}
