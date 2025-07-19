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
                
                // 音声認識結果の品質検証
                let qualityResult = self.validateRecognitionQuality(text: recognizedText, confidence: confidence)
                
                if !qualityResult.isValid {
                    AppLogger.shared.warning("音声認識結果が品質基準を満たしません: '\(recognizedText)' - \(qualityResult.reason)")
                    // 品質基準を満たさない結果は送信しない
                    return
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
    
    // MARK: - Quality Validation
    
    /// 音声認識結果の品質検証結果
    private struct RecognitionQualityResult {
        let isValid: Bool
        let reason: String
    }
    
    /// 音声認識結果の品質を検証する
    private func validateRecognitionQuality(text: String, confidence: Float) -> RecognitionQualityResult {
        // 1. 基本的なフィルタリング
        guard !text.isEmpty else {
            return RecognitionQualityResult(isValid: false, reason: "空文字")
        }
        
        // 2. 信頼度チェック（短い単語は高い信頼度が必要）
        let minConfidence: Float = text.count <= 3 ? 0.7 : 0.5
        if confidence < minConfidence {
            return RecognitionQualityResult(isValid: false, reason: "信頼度不足: \(String(format: "%.2f", confidence)) < \(minConfidence)")
        }
        
        // 3. 不自然なパターン検出
        if hasUnnaturalPatterns(text) {
            return RecognitionQualityResult(isValid: false, reason: "不自然なパターン検出")
        }
        
        // 4. 非ひらがな文字のチェック
        if hasInvalidCharacters(text) {
            return RecognitionQualityResult(isValid: false, reason: "無効な文字を含む")
        }
        
        return RecognitionQualityResult(isValid: true, reason: "品質基準適合")
    }
    
    /// 不自然なパターンを検出する
    private func hasUnnaturalPatterns(_ text: String) -> Bool {
        // 同じ文字・音の過度な繰り返し
        if hasExcessiveRepetition(text) {
            return true
        }
        
        // 意味のない音の組み合わせ
        if hasNonsensicalCombinations(text) {
            return true
        }
        
        return false
    }
    
    /// 過度な文字繰り返しを検出
    private func hasExcessiveRepetition(_ text: String) -> Bool {
        // 同じ文字が4回以上連続
        let pattern = #"(.)\1{3,}"#
        if text.range(of: pattern, options: .regularExpression) != nil {
            AppLogger.shared.debug("過度な文字繰り返し検出: \(text)")
            return true
        }
        
        // 2-3文字の繰り返しパターン（例：「たいぐたいぐたいぐ」）
        for length in 2...3 {
            if hasRepeatingSubstring(text, length: length, minRepetitions: 3) {
                AppLogger.shared.debug("\(length)文字繰り返しパターン検出: \(text)")
                return true
            }
        }
        
        return false
    }
    
    /// 指定された長さの部分文字列の繰り返しを検出
    private func hasRepeatingSubstring(_ text: String, length: Int, minRepetitions: Int) -> Bool {
        guard text.count >= length * minRepetitions else { return false }
        
        let substring = String(text.prefix(length))
        var repetitions = 1
        var index = text.index(text.startIndex, offsetBy: length)
        
        while index < text.endIndex && text.distance(from: index, to: text.endIndex) >= length {
            let nextSubstring = String(text[index..<text.index(index, offsetBy: length)])
            if nextSubstring == substring {
                repetitions += 1
                if repetitions >= minRepetitions {
                    return true
                }
            } else {
                break
            }
            index = text.index(index, offsetBy: length)
        }
        
        return false
    }
    
    /// 意味のない音の組み合わせを検出
    private func hasNonsensicalCombinations(_ text: String) -> Bool {
        // 「ふぁ」「ふぃ」「ふぇ」「ふぉ」などの外来語音が不自然に組み合わされている
        let foreignSounds = ["ふぁ", "ふぃ", "ふぇ", "ふぉ", "うぃ", "うぇ", "うぉ", "ちゃ", "ちゅ", "ちぇ", "ちょ"]
        let foreignSoundCount = foreignSounds.reduce(0) { count, sound in
            count + text.components(separatedBy: sound).count - 1
        }
        
        // 外来語音が単語長の半分以上を占める場合は不自然とみなす
        if foreignSoundCount > text.count / 2 {
            AppLogger.shared.debug("過度な外来語音検出: \(text)")
            return true
        }
        
        return false
    }
    
    /// 無効な文字を含むかチェック
    private func hasInvalidCharacters(_ text: String) -> Bool {
        let hiraganaRange = CharacterSet(charactersIn: "あ-ん")
        let validCharacters = hiraganaRange.union(CharacterSet(charactersIn: "ゃゅょっぁぃぅぇぉー"))
        
        for scalar in text.unicodeScalars {
            if !validCharacters.contains(scalar) {
                AppLogger.shared.debug("無効な文字検出: '\(String(scalar))' in '\(text)'")
                return true
            }
        }
        
        return false
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