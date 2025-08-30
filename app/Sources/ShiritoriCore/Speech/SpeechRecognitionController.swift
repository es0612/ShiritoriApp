import SwiftUI
import Foundation
import Observation

/// 音声認識制御クラス
/// WordInputViewから音声認識ロジックを分離して、責務を明確化
@MainActor
@Observable
public class SpeechRecognitionController {
    
    // MARK: - Dependencies
    private let speechManager = SpeechRecognitionManager()
    private let settingsManager = SettingsManager.shared
    private let hiraganaConverter = HiraganaConverter()
    
    // MARK: - State Management
    public private(set) var speechState = SpeechRecognitionState()
    
    // MARK: - Current Player Context
    public private(set) var currentPlayerId: String = ""
    
    public init() {
        AppLogger.shared.debug("SpeechRecognitionController初期化完了")
    }
    
    // MARK: - Lifecycle Management
    
    /// 新しいターンの開始時にリセット
    public func resetForNewTurn(playerId: String) {
        AppLogger.shared.debug("SpeechRecognitionController: 新しいターンのためのリセット - プレイヤー: \(playerId)")
        
        // 進行中の音声認識を安全に停止
        if speechState.currentPhase.isActive {
            AppLogger.shared.info("進行中の音声認識を停止: \(speechState.currentPhase)")
            speechManager.stopRecording()
        }
        
        // 状態を完全リセット
        speechState.resetForNewTurn()
        speechManager.resetForNewTurn()
        currentPlayerId = playerId
        
        // 初期入力モードを設定
        initializeInputMode()
    }
    
    /// 入力モードの初期化
    public func initializeInputMode() {
        let defaultMode = settingsManager.defaultInputMode
        speechState.isVoiceMode = defaultMode
        
        AppLogger.shared.info("入力モードを初期化: \(defaultMode ? "音声入力" : "キーボード入力")")
    }
    
    // MARK: - Voice Recognition Control
    
    /// 音声録音開始
    public func startVoiceRecording() -> Bool {
        guard speechState.currentPhase == .idle else {
            AppLogger.shared.warning("録音開始失敗: 既に他の段階にあります (\(speechState.currentPhase))")
            return false
        }
        
        AppLogger.shared.info("🎤 音声録音開始")
        speechState.startRecording()
        
        Task {
            await speechManager.startRecording { [weak self] recognizedText in
                Task { @MainActor in
                    self?.handlePartialRecognition(recognizedText)
                }
            }
        }
        
        return true
    }
    
    /// 音声録音停止
    public func stopVoiceRecording() -> String? {
        guard speechState.currentPhase.isActive else {
            AppLogger.shared.warning("録音停止失敗: アクティブな録音がありません")
            return nil
        }
        
        AppLogger.shared.info("🎤 音声録音停止")
        speechManager.stopRecording()
        
        // 最終結果の取得と処理
        let finalResult = speechState.partialResult.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !finalResult.isEmpty {
            // 認識成功 → 結果準備完了段階に遷移
            speechState.completeRecognition(result: finalResult, confidence: 0.8)
            return finalResult
        } else {
            // 認識失敗
            speechState.recordFailure()
            handleVoiceRecognitionFailure()
            return nil
        }
    }
    
    /// 認識結果を採用
    public func useRecognitionResult() -> String {
        AppLogger.shared.info("音声認識結果を採用: '\(speechState.recognitionResult)'")
        
        let result = speechState.recognitionResult
        speechState.completeWithResult()
        
        return result
    }
    
    /// 音声認識をやり直し
    public func retryVoiceRecognition() {
        AppLogger.shared.info("音声認識をやり直し - 失敗として記録")
        speechState.retryRecognition()
        handleVoiceRecognitionFailure()
    }
    
    // MARK: - Input Mode Management
    
    /// 音声入力モードに切り替え
    public func switchToVoiceMode() {
        speechState.isVoiceMode = true
        AppLogger.shared.debug("音声入力モードに切替")
    }
    
    /// キーボード入力モードに切り替え
    public func switchToKeyboardMode() {
        speechState.isVoiceMode = false
        AppLogger.shared.debug("テキスト入力モードに切替")
    }
    
    // MARK: - State Queries
    
    /// 現在の入力モード
    public var isVoiceMode: Bool {
        speechState.isVoiceMode
    }
    
    /// 認識結果選択画面の表示状態
    public var showRecognitionChoice: Bool {
        speechState.showRecognitionChoice
    }
    
    /// 認識結果
    public var recognitionResult: String {
        speechState.recognitionResult
    }
    
    /// 現在の段階
    public var currentPhase: SpeechRecognitionState.Phase {
        speechState.currentPhase
    }
    
    /// 部分認識結果
    public var partialResult: String {
        speechState.partialResult
    }
    
    /// 連続失敗回数
    public var consecutiveFailureCount: Int {
        speechState.consecutiveFailureCount
    }
    
    /// ガイダンスメッセージ表示状態
    public var showGuidanceMessage: Bool {
        speechState.showGuidanceMessage
    }
    
    /// ガイダンスメッセージ
    public var guidanceMessage: String {
        speechState.guidanceMessage
    }
    
    /// 自動切り替え済みフラグ
    public var hasAutoSwitched: Bool {
        speechState.hasAutoSwitched
    }
    
    // MARK: - Private Helper Methods
    
    /// 部分認識結果の処理
    private func handlePartialRecognition(_ recognizedText: String) {
        let hiraganaText = hiraganaConverter.convertToHiragana(recognizedText)
        
        // 中間結果更新（処理中段階）
        if speechState.currentPhase == .recording {
            speechState.startProcessing()
        }
        
        // リアルタイム中間結果
        speechState.updatePartialResult(hiraganaText, confidence: 0.8)
    }
    
    /// 音声認識失敗時の処理
    private func handleVoiceRecognitionFailure() {
        let failureCount = speechState.consecutiveFailureCount
        
        AppLogger.shared.info("音声認識失敗処理: \(failureCount)回目")
        
        // 設定に基づいて失敗閾値を更新
        speechManager.setFailureThreshold(settingsManager.speechFailureThreshold)
        
        // 自動フォールバック機能が有効で、閾値に達した場合
        if settingsManager.autoFallbackEnabled &&
           speechState.hasReachedFailureThreshold(settingsManager.speechFailureThreshold) &&
           !speechState.hasAutoSwitched {
            speechState.performAutoFallback()
        }
    }
    
    // MARK: - Guidance System
    
    /// ガイダンスメッセージのアイコンを取得
    public func getGuidanceIcon() -> String {
        let failureCount = speechState.consecutiveFailureCount
        switch failureCount {
        case 1:
            return "exclamationmark.circle"
        case 2:
            return "exclamationmark.triangle"
        case 3:
            return "keyboard"
        default:
            return "info.circle"
        }
    }
    
    /// ガイダンスメッセージの色を取得
    public func getGuidanceColor() -> Color {
        let failureCount = speechState.consecutiveFailureCount
        switch failureCount {
        case 1:
            return .blue
        case 2:
            return .orange
        case 3:
            return .red
        default:
            return .gray
        }
    }
    
    /// ガイダンスメッセージのタイトルを取得
    public func getGuidanceTitle() -> String {
        let failureCount = speechState.consecutiveFailureCount
        switch failureCount {
        case 1:
            return "ちょっと待って！"
        case 2:
            return "がんばって！"
        case 3:
            return "キーボードを使おう！"
        default:
            return "ヒント"
        }
    }
    
    // MARK: - Error Recovery
    
    /// エラー状態からの復旧
    public func recoverFromError() {
        AppLogger.shared.info("音声認識エラーからの復旧")
        speechState.resetToIdle()
        speechManager.resetForNewTurn()
    }
    
    /// 強制的な状態リセット（デバッグ用）
    public func forceReset() {
        AppLogger.shared.warning("音声認識コントローラーの強制リセット")
        speechManager.stopRecording()
        speechState.resetForNewTurn()
        speechManager.resetForNewTurn()
    }
    
    // MARK: - Debug Information
    
    /// デバッグ情報の生成
    public func generateDebugInfo() -> String {
        return """
        
        === SpeechRecognitionController Debug Info ===
        Current Player: \(currentPlayerId)
        Voice Mode: \(speechState.isVoiceMode)
        Current Phase: \(speechState.currentPhase)
        Partial Result: "\(speechState.partialResult)"
        Recognition Result: "\(speechState.recognitionResult)"
        Consecutive Failures: \(speechState.consecutiveFailureCount)
        Show Choice: \(speechState.showRecognitionChoice)
        Show Guidance: \(speechState.showGuidanceMessage)
        Auto Switched: \(speechState.hasAutoSwitched)
        
        """
    }
}
