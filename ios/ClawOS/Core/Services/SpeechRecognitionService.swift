import Speech
import AVFoundation

@Observable
final class SpeechRecognitionService {
    private(set) var transcribedText: String = ""
    private(set) var isRecording: Bool = false
    private(set) var audioLevel: Float = 0
    var error: SpeechError?

    private var audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var hasInstalledTap = false
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "zh-CN"))

    enum SpeechError: LocalizedError {
        case microphoneDenied
        case recognitionDenied
        case recognizerUnavailable
        case recordingFailed(String)

        var errorDescription: String? {
            switch self {
            case .microphoneDenied:
                "麦克风权限未开启，请在系统设置中允许 ClawOS 访问麦克风"
            case .recognitionDenied:
                "语音识别权限未开启，请在系统设置中允许 ClawOS 使用语音识别"
            case .recognizerUnavailable:
                "语音识别服务暂不可用，请稍后重试"
            case .recordingFailed(let detail):
                "录音失败：\(detail)"
            }
        }
    }

    // MARK: - Permissions

    static func requestPermissionsIfNeeded() async -> (mic: Bool, speech: Bool) {
        let mic = await microphonePermissionIfNeeded()
        guard mic else {
            return (mic: false, speech: false)
        }

        let speech = await speechPermissionIfNeeded()
        return (mic: mic, speech: speech)
    }

    private static func microphonePermissionIfNeeded() async -> Bool {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            return true
        case .denied:
            return false
        case .undetermined:
            return await withCheckedContinuation { continuation in
                AVAudioApplication.requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        @unknown default:
            return false
        }
    }

    private static func speechPermissionIfNeeded() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            return true
        case .denied, .restricted:
            return false
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
        @unknown default:
            return false
        }
    }

    func prepareFastStartIfAuthorized() async {
        guard Self.hasGrantedPermissions else { return }
        do {
            try configureAudioSession(activate: false)
        } catch {
            return
        }

        _ = speechRecognizer?.isAvailable
    }

    private static var hasGrantedPermissions: Bool {
        AVAudioSession.sharedInstance().recordPermission == .granted
            && SFSpeechRecognizer.authorizationStatus() == .authorized
    }

    // MARK: - Recording

    func startRecording() throws {
        guard let speechRecognizer, speechRecognizer.isAvailable else {
            throw SpeechError.recognizerUnavailable
        }

        stopRecordingInternal(deactivateSession: false)
        // Recreate the engine each session to avoid stale tap/sample-rate state
        // after rapid stop/start on real devices.
        audioEngine = AVAudioEngine()

        try configureAudioSession(activate: true)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.taskHint = .dictation
        request.addsPunctuation = false
        recognitionRequest = request

        transcribedText = ""
        error = nil

        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, taskError in
            guard let self else { return }
            let transcript = result?.bestTranscription.formattedString
            let shouldStop = taskError != nil || (result?.isFinal ?? false)

            Task { @MainActor [weak self] in
                guard let self else { return }

                if let transcript, transcript != self.transcribedText {
                    self.transcribedText = transcript
                }

                if shouldStop {
                    self.stopRecordingInternal()
                }
            }
        }

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.inputFormat(forBus: 0)
        guard recordingFormat.channelCount > 0, recordingFormat.sampleRate > 0 else {
            throw SpeechError.recordingFailed("输入音频格式不可用")
        }

        if hasInstalledTap {
            inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
            self?.updateAudioLevel(buffer: buffer)
        }
        hasInstalledTap = true

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            stopRecordingInternal()
            throw error
        }
        isRecording = true
    }

    @discardableResult
    func stopRecording() -> String {
        let finalText = transcribedText
        stopRecordingInternal()
        return finalText
    }

    private func stopRecordingInternal(deactivateSession: Bool = true) {
        recognitionRequest?.endAudio()
        recognitionTask?.finish()
        recognitionRequest = nil
        recognitionTask = nil

        if hasInstalledTap {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInstalledTap = false
        }

        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.reset()
        audioEngine = AVAudioEngine()
        isRecording = false
        audioLevel = 0

        if deactivateSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    private func configureAudioSession(activate: Bool) throws {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(
            .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker, .allowBluetooth]
        )
        try? audioSession.setPreferredIOBufferDuration(0.005)

        if activate {
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }
    }

    private func updateAudioLevel(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frames = Int(buffer.frameLength)
        var sum: Float = 0
        for i in 0..<frames {
            sum += channelData[i] * channelData[i]
        }
        let rms = sqrtf(sum / Float(max(frames, 1)))
        let db = 20 * log10f(max(rms, 1e-6))
        let normalized = max(0, min(1, (db + 50) / 50))

        Task { @MainActor in
            self.audioLevel = normalized
        }
    }
}
