import Foundation
import Speech
import AVFoundation
import Observation

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
    
    // 失敗トラッキング機能
    public private(set) var consecutiveFailureCount = 0
    private var failureThreshold = 3
    
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
    
    // MARK: - 失敗トラッキング機能
    
    /// 連続失敗カウンターを増加
    public func incrementFailureCount() {
        consecutiveFailureCount += 1
        AppLogger.shared.debug("音声認識失敗カウンター増加: \(consecutiveFailureCount)/\(failureThreshold)")
    }
    
    /// 連続失敗カウンターをリセット
    public func resetFailureCount() {
        consecutiveFailureCount = 0
        AppLogger.shared.debug("音声認識失敗カウンターリセット")
    }
    
    /// 失敗閾値に達したかチェック
    public func hasReachedFailureThreshold() -> Bool {
        return consecutiveFailureCount >= failureThreshold
    }
    
    /// 音声認識成功を記録（失敗カウンターをリセット）
    public func recordRecognitionSuccess() {
        resetFailureCount()
        AppLogger.shared.debug("音声認識成功を記録")
    }
    
    /// 失敗閾値を設定
    public func setFailureThreshold(_ threshold: Int) {
        failureThreshold = max(1, threshold) // 最小1回
        AppLogger.shared.debug("音声認識失敗閾値設定: \(failureThreshold)")
    }
    
    /// 新ターン用の包括的リセット（プレイヤー変更時に使用）
    public func resetForNewTurn() {
        AppLogger.shared.debug("SpeechRecognitionManager: 新ターン用リセット開始")
        
        // 進行中の録音を停止
        if isRecording {
            AppLogger.shared.info("プレイヤー変更時に進行中の録音を停止")
            stopRecording()
        }
        
        // 失敗カウンターをリセット
        resetFailureCount()
        
        // 部分結果とタイミング情報をクリア
        lastPartialResult = ""
        startTime = nil
        
        // コールバック参照をクリア（メモリリーク防止）
        onTextReceived = nil
        
        AppLogger.shared.debug("SpeechRecognitionManager: 新ターン用リセット完了")
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
                    
                    // 失敗カウンターを増加（確定結果の場合のみ）
                    if isFinal {
                        self.incrementFailureCount()
                    }
                    
                    // 品質基準を満たさない結果は送信しない
                    return
                } else if isFinal {
                    // 品質基準を満たす確定結果の場合、成功を記録
                    self.recordRecognitionSuccess()
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
        
        let startTimeString = startTime.map { String(describing: $0) } ?? "nil"
        AppLogger.shared.info("音声認識開始: 開始時刻=\(startTimeString), バッファサイズ=\(bufferSize)")
    }
    
    // MARK: - Quality Validation
    
    /// 音声認識結果の品質検証結果
    private struct RecognitionQualityResult {
        let isValid: Bool
        let reason: String
    }
    
    /// 音声認識結果の品質を検証する
    private func validateRecognitionQuality(text: String, confidence: Float) -> RecognitionQualityResult {
        AppLogger.shared.debug("🔍 音声認識品質検証開始: text='\(text)', confidence=\(String(format: "%.3f", confidence))")
        
        // 1. 基本的なフィルタリング
        guard !text.isEmpty else {
            AppLogger.shared.debug("❌ 品質検証失敗: 空文字")
            return RecognitionQualityResult(isValid: false, reason: "空文字")
        }
        
        // 2. 信頼度チェック（緩和された基準）
        // 短い単語でも0.5以上あれば許可（以前は0.7）
        let minConfidence: Float = text.count <= 2 ? 0.6 : 0.4  // より緩い基準
        if confidence < minConfidence {
            AppLogger.shared.debug("❌ 品質検証失敗: 信頼度不足 \(String(format: "%.3f", confidence)) < \(minConfidence)")
            return RecognitionQualityResult(isValid: false, reason: "信頼度不足: \(String(format: "%.2f", confidence)) < \(minConfidence)")
        }
        
        // 3. 不自然なパターン検出（緩和）
        if hasUnnaturalPatterns(text) {
            AppLogger.shared.debug("❌ 品質検証失敗: 不自然なパターン検出")
            return RecognitionQualityResult(isValid: false, reason: "不自然なパターン検出")
        }
        
        // 4. 非ひらがな文字のチェック（修正）
        if hasInvalidCharacters(text) {
            AppLogger.shared.debug("❌ 品質検証失敗: 無効な文字を含む")
            return RecognitionQualityResult(isValid: false, reason: "無効な文字を含む")
        }
        
        AppLogger.shared.debug("✅ 品質検証成功: '\(text)'")
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
        // ひらがな・カタカナ・長音符・小書き文字の正確な定義
        let hiraganaRange = CharacterSet(charactersIn: "\u{3041}...\u{3096}")  // ひらがな範囲
        let katakanaRange = CharacterSet(charactersIn: "\u{30A1}...\u{30F6}")  // カタカナ範囲
        let additionalChars = CharacterSet(charactersIn: "ー・、。")  // 長音符・中点・句読点
        
        let validCharacters = hiraganaRange
            .union(katakanaRange)
            .union(additionalChars)
        
        for scalar in text.unicodeScalars {
            if !validCharacters.contains(scalar) {
                // 英数字や明らかに無効な文字をチェック
                let char = String(scalar)
                if char.range(of: "[a-zA-Z0-9]", options: .regularExpression) != nil {
                    AppLogger.shared.debug("無効な文字検出（英数字）: '\(char)' in '\(text)'")
                    return true
                }
                
                // 制御文字やその他の無効文字
                if scalar.value < 32 || (scalar.value >= 127 && scalar.value < 160) {
                    AppLogger.shared.debug("無効な文字検出（制御文字）: '\(char)' in '\(text)'")
                    return true
                }
                
                AppLogger.shared.debug("文字チェック: '\(char)' (U+\(String(scalar.value, radix: 16).uppercased())) - 許可")
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
