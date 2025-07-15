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
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var onTextReceived: ((String) -> Void)?
    
    public override init() {
        super.init()
        AppLogger.shared.debug("SpeechRecognitionManager初期化開始")
        
        // 日本語音声認識を初期化
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
        speechRecognizer?.delegate = self
        
        // 音声認識の利用可能性を確認
        updateAvailability()
        
        AppLogger.shared.info("SpeechRecognitionManager初期化完了: 利用可能=\(isAvailable)")
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
        
        recognitionRequest?.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        
        isRecording = false
        
        AppLogger.shared.info("音声認識停止完了")
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
        
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false
        
        guard let speechRecognizer = speechRecognizer else {
            throw SpeechRecognitionError.speechRecognizerUnavailable
        }
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                let recognizedText = result.bestTranscription.formattedString
                AppLogger.shared.debug("音声認識結果: '\(recognizedText)'")
                
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
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isRecording = true
        
        AppLogger.shared.debug("音声認識内部処理完了")
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