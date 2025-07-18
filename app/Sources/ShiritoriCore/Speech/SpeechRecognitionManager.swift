import Foundation
import Speech
import AVFoundation

#if os(iOS)
import UIKit
#endif

/// 音声認識を管理するクラス
@Observable
public class SpeechRecognitionManager: NSObject {
    public private(set) var isRecording = false
    public private(set) var isAvailable = false
    public private(set) var useOnDeviceRecognition = true
    public private(set) var shouldReportPartialResults = true
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var onTextReceived: ((String) -> Void)?
    
    // 音声認識精度向上のためのプロパティ
    private var startTime: Date?
    private var lastPartialResult: String = ""
    
    public override init() {
        super.init()
        AppLogger.shared.debug("SpeechRecognitionManager初期化開始")
        
        // 日本語音声認識を初期化
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        speechRecognizer?.delegate = self
        
        // 音声認識の利用可能性を確認
        updateAvailability()
        
        AppLogger.shared.info("SpeechRecognitionManager初期化完了: 利用可能=\(isAvailable), オンデバイス=\(useOnDeviceRecognition)")
    }
    
    /// 音声認識設定を更新
    public func updateSettings(useOnDeviceRecognition: Bool, shouldReportPartialResults: Bool) {
        AppLogger.shared.debug("音声認識設定更新: オンデバイス=\(useOnDeviceRecognition), 中間結果=\(shouldReportPartialResults)")
        
        self.useOnDeviceRecognition = useOnDeviceRecognition
        self.shouldReportPartialResults = shouldReportPartialResults
        
        AppLogger.shared.info("音声認識設定更新完了")
    }
    
    /// 音声認識の許可を要求
    public func requestSpeechPermission() async -> Bool {
        AppLogger.shared.debug("音声認識許可要求開始")
        
        // 音声認識許可の確認
        let speechAuthStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
        
        AppLogger.shared.debug("音声認識許可ステータス: \(speechAuthStatus.rawValue)")
        
        // マイク許可の確認
        let microphoneAuthStatus: Bool
        #if os(iOS)
        microphoneAuthStatus = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
        #else
        // macOSでは常にtrueを返す（テスト用）
        microphoneAuthStatus = true
        #endif
        
        AppLogger.shared.debug("マイク許可ステータス: \(microphoneAuthStatus)")
        
        let hasPermission = speechAuthStatus == .authorized && microphoneAuthStatus
        AppLogger.shared.info("音声認識許可確認完了: 許可あり=\(hasPermission)")
        
        await MainActor.run {
            updateAvailability()
        }
        
        return hasPermission
    }
    
    /// 音声認識を開始
    public func startRecording(onTextReceived: @escaping (String) -> Void) async {
        AppLogger.shared.debug("音声認識開始要求")
        
        // 既に録音中の場合は停止
        if isRecording {
            AppLogger.shared.warning("既に録音中のため、現在の録音を停止します")
            stopRecording()
        }
        
        self.onTextReceived = onTextReceived
        
        // 許可確認
        let hasPermission = await requestSpeechPermission()
        guard hasPermission else {
            AppLogger.shared.error("音声認識開始失敗: 許可がありません")
            return
        }
        
        do {
            try await startRecordingInternal()
            AppLogger.shared.info("音声認識開始成功")
        } catch {
            AppLogger.shared.error("音声認識開始エラー: \(error.localizedDescription)")
        }
    }
    
    /// 音声認識を停止
    public func stopRecording() {
        AppLogger.shared.debug("音声認識停止要求")
        
        let totalDuration = startTime.map { Date().timeIntervalSince($0) } ?? 0
        
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        isRecording = false
        startTime = nil
        
        AppLogger.shared.info("音声認識停止完了: 総録音時間=\(String(format: "%.2f", totalDuration))s, 最終結果='\(lastPartialResult)'")
        lastPartialResult = ""
    }
    
    // MARK: - Private Methods
    
    private func updateAvailability() {
        #if os(iOS)
        isAvailable = speechRecognizer?.isAvailable == true &&
                     SFSpeechRecognizer.authorizationStatus() == .authorized &&
                     AVAudioSession.sharedInstance().recordPermission == .granted
        #else
        // macOSでは音声認識のみチェック
        isAvailable = speechRecognizer?.isAvailable == true &&
                     SFSpeechRecognizer.authorizationStatus() == .authorized
        #endif
        
        AppLogger.shared.debug("音声認識利用可能性更新: \(isAvailable)")
    }
    
    private func startRecordingInternal() async throws {
        AppLogger.shared.debug("音声認識内部処理開始")
        
        #if os(iOS)
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        #endif
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw SpeechRecognitionError.recognitionRequestCreationFailed
        }
        
        recognitionRequest.shouldReportPartialResults = shouldReportPartialResults
        recognitionRequest.requiresOnDeviceRecognition = useOnDeviceRecognition
        
        // しりとり用の短い単語認識に最適化された設定
        if #available(iOS 13.0, *) {
            recognitionRequest.taskHint = .search // 短い単語検索に最適
        }
        
        AppLogger.shared.debug("音声認識設定: オンデバイス=\(useOnDeviceRecognition), 中間結果=\(shouldReportPartialResults), タスクヒント=search")
        
        guard let speechRecognizer = speechRecognizer else {
            throw SpeechRecognitionError.speechRecognizerUnavailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                let confidence = result.bestTranscription.segments.first?.confidence ?? 0.0
                let isFinal = result.isFinal
                
                // 詳細な音声認識ログ
                let elapsedTime = startTime.map { Date().timeIntervalSince($0) } ?? 0
                AppLogger.shared.debug("音声認識結果 [経過時間: \(String(format: "%.2f", elapsedTime))s]: '\(recognizedText)' (信頼度: \(String(format: "%.2f", confidence)), 確定: \(isFinal))")
                
                // 候補の詳細ログ（開発時の分析用）
                if result.transcriptions.count > 1 {
                    let alternatives = result.transcriptions.prefix(3).map { $0.formattedString }
                    AppLogger.shared.debug("音声認識候補: \(alternatives)")
                }
                
                // 短い単語の信頼度チェック
                if recognizedText.count <= 3 && confidence < 0.7 {
                    AppLogger.shared.warning("短い単語の信頼度が低い: '\(recognizedText)' (信頼度: \(String(format: "%.2f", confidence)))")
                }
                
                // 前回の結果と比較
                if recognizedText != lastPartialResult {
                    AppLogger.shared.debug("音声認識結果更新: '\(lastPartialResult)' -> '\(recognizedText)'")
                    lastPartialResult = recognizedText
                }
                
                DispatchQueue.main.async {
                    self.onTextReceived?(recognizedText)
                }
            }
            
            if let error = error {
                AppLogger.shared.error("音声認識エラー: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.stopRecording()
                }
            }
        }
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        AppLogger.shared.debug("オーディオ設定: サンプルレート=\(recordingFormat.sampleRate), チャンネル数=\(recordingFormat.channelCount)")
        
        // しりとり用の短い単語認識に最適化されたバッファサイズ
        let bufferSize: AVAudioFrameCount = 512 // 小さいバッファでレスポンス向上
        
        inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        startTime = Date()
        lastPartialResult = ""
        isRecording = true
        
        AppLogger.shared.info("音声認識開始: 開始時刻=\(startTime!), バッファサイズ=\(bufferSize)")
    }
}

// MARK: - SFSpeechRecognizerDelegate

extension SpeechRecognitionManager: SFSpeechRecognizerDelegate {
    public func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        AppLogger.shared.debug("音声認識利用可能性変更: \(available)")
        DispatchQueue.main.async {
            self.updateAvailability()
        }
    }
}

// MARK: - Error Types

public enum SpeechRecognitionError: Error, LocalizedError {
    case recognitionRequestCreationFailed
    case speechRecognizerUnavailable
    
    public var errorDescription: String? {
        switch self {
        case .recognitionRequestCreationFailed:
            return "音声認識リクエストの作成に失敗しました"
        case .speechRecognizerUnavailable:
            return "音声認識機能が利用できません"
        }
    }
}