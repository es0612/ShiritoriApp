import Foundation
import Observation

/// 音声認識の状態を統一的に管理する@Observableクラス
/// 遅延処理を排除し、状態変更ベースでUIを駆動する
@Observable
public class SpeechRecognitionState {
    
    // MARK: - Phase管理
    
    /// 音声認識の段階を表すenum
    public enum Phase {
        case idle                // 待機中
        case recording           // 録音中
        case processing         // 処理中（認識実行中）
        case resultReady        // 結果準備完了（認識結果表示フェーズ）
        case choiceDisplayed    // 選択画面表示中
        case completed          // 完了（単語提出済み）
        case failed             // 失敗
    }
    
    /// 現在の音声認識段階
    public private(set) var currentPhase: Phase = .idle {
        didSet {
            AppLogger.shared.debug("音声認識段階変更: \(oldValue) → \(currentPhase)")
            handlePhaseChange(from: oldValue, to: currentPhase)
        }
    }
    
    // MARK: - 認識結果管理
    
    /// 認識された単語
    public private(set) var recognitionResult: String = ""
    
    /// 中間結果（リアルタイム表示用）
    public private(set) var partialResult: String = ""
    
    /// 認識結果の信頼度
    public private(set) var confidence: Float = 0.0
    
    // MARK: - 失敗管理
    
    /// 連続失敗回数
    public private(set) var consecutiveFailureCount: Int = 0
    
    /// ガイダンスメッセージ
    public private(set) var guidanceMessage: String = ""
    
    /// フォールバック情報表示フラグ
    public private(set) var showGuidanceMessage: Bool = false
    
    /// 自動フォールバックが発生したかどうか
    public private(set) var hasAutoSwitched: Bool = false
    
    // MARK: - UI表示状態
    
    /// 認識結果確認画面の表示状態
    public private(set) var showRecognitionChoice: Bool = false
    
    /// 音声入力モードかどうか
    public var isVoiceMode: Bool = true
    
    // MARK: - 段階遷移メソッド
    
    /// 録音開始
    public func startRecording() {
        guard currentPhase == .idle else {
            AppLogger.shared.warning("無効な状態からの録音開始試行: \(currentPhase)")
            return
        }
        currentPhase = .recording
        clearResults()
    }
    
    /// 処理段階に移行（音声認識エンジンが動作中）
    public func startProcessing() {
        guard currentPhase == .recording else {
            AppLogger.shared.warning("無効な状態からの処理開始試行: \(currentPhase)")
            return
        }
        currentPhase = .processing
    }
    
    /// 中間結果更新
    public func updatePartialResult(_ text: String, confidence: Float) {
        guard currentPhase == .processing else { return }
        partialResult = text
        self.confidence = confidence
        AppLogger.shared.debug("中間結果更新: '\(text)' (信頼度: \(String(format: "%.2f", confidence)))")
    }
    
    /// 認識結果確定・結果準備完了段階に移行
    public func completeRecognition(result: String, confidence: Float) {
        guard currentPhase == .processing else {
            AppLogger.shared.warning("無効な状態からの認識完了試行: \(currentPhase)")
            return
        }
        
        recognitionResult = result
        self.confidence = confidence
        partialResult = ""
        
        AppLogger.shared.info("🎤 音声認識完了: '\(result)' (信頼度: \(String(format: "%.2f", confidence)))")
        
        // 結果準備完了段階に移行（UIで認識結果を表示するフェーズ）
        currentPhase = .resultReady
    }
    
    /// 選択画面表示段階に自動遷移
    public func showChoiceScreen() {
        guard currentPhase == .resultReady else {
            AppLogger.shared.warning("無効な状態からの選択画面表示試行: \(currentPhase)")
            return
        }
        
        showRecognitionChoice = true
        currentPhase = .choiceDisplayed
        AppLogger.shared.info("🎯 選択画面自動表示: showRecognitionChoice=\(showRecognitionChoice)")
    }
    
    /// 失敗処理
    public func recordFailure() {
        consecutiveFailureCount += 1
        currentPhase = .failed
        clearResults()
        
        AppLogger.shared.info("音声認識失敗: \(consecutiveFailureCount)回目")
        updateGuidanceMessage()
    }
    
    /// 成功処理（失敗カウンターリセット）
    public func recordSuccess() {
        consecutiveFailureCount = 0
        hideGuidanceMessage()
        AppLogger.shared.debug("音声認識成功: 失敗カウンターリセット")
    }
    
    /// 単語採用・完了
    public func completeWithResult() {
        guard currentPhase == .choiceDisplayed else {
            AppLogger.shared.warning("無効な状態からの完了試行: \(currentPhase)")
            return
        }
        
        showRecognitionChoice = false
        currentPhase = .completed
        recordSuccess()
        AppLogger.shared.info("単語採用完了: '\(recognitionResult)'")
    }
    
    /// やり直し処理
    public func retryRecognition() {
        guard currentPhase == .choiceDisplayed else {
            AppLogger.shared.warning("無効な状態からのやり直し試行: \(currentPhase)")
            return
        }
        
        showRecognitionChoice = false
        recordFailure() // やり直しは失敗としてカウント
        resetToIdle()
    }
    
    /// アイドル状態にリセット
    public func resetToIdle() {
        currentPhase = .idle
        showRecognitionChoice = false
        clearResults()
        AppLogger.shared.debug("アイドル状態にリセット")
    }
    
    /// 新ターン用の完全リセット
    public func resetForNewTurn() {
        currentPhase = .idle
        consecutiveFailureCount = 0
        hasAutoSwitched = false
        showRecognitionChoice = false
        clearResults()
        hideGuidanceMessage()
        isVoiceMode = true // デフォルトに戻す
        AppLogger.shared.debug("新ターン用リセット完了")
    }
    
    // MARK: - フォールバック処理
    
    /// 自動フォールバックを実行
    public func performAutoFallback() {
        guard !hasAutoSwitched else {
            AppLogger.shared.warning("既に自動フォールバック済み")
            return
        }
        
        hasAutoSwitched = true
        isVoiceMode = false
        guidanceMessage = "キーボードで入力してみよう！"
        showGuidanceMessage = true
        
        AppLogger.shared.info("🔄 自動フォールバック実行: 音声→キーボード")
    }
    
    /// 失敗閾値チェック
    public func hasReachedFailureThreshold(_ threshold: Int = 3) -> Bool {
        return consecutiveFailureCount >= threshold
    }
    
    // MARK: - Private Methods
    
    /// 結果をクリア
    private func clearResults() {
        recognitionResult = ""
        partialResult = ""
        confidence = 0.0
    }
    
    /// 段階変更時の処理
    private func handlePhaseChange(from oldPhase: Phase, to newPhase: Phase) {
        // resultReady → choiceDisplayed への自動遷移
        if newPhase == .resultReady {
            // メインスレッドで次のRunLoopで選択画面表示
            // 遅延ではなく、状態変更の連鎖で実現
            Task { @MainActor in
                // UI更新完了後に選択画面表示
                showChoiceScreen()
            }
        }
    }
    
    /// ガイダンスメッセージ更新
    private func updateGuidanceMessage() {
        switch consecutiveFailureCount {
        case 1:
            guidanceMessage = "もう一度話してみてね"
            showGuidanceMessage = true
        case 2:
            guidanceMessage = "ゆっくり はっきり話してみてね"
            showGuidanceMessage = true
        default:
            hideGuidanceMessage()
        }
    }
    
    /// ガイダンスメッセージを隠す
    private func hideGuidanceMessage() {
        guidanceMessage = ""
        showGuidanceMessage = false
    }
}

// MARK: - Helper Extensions

extension SpeechRecognitionState.Phase {
    /// 録音中かどうか
    public var isRecording: Bool {
        return self == .recording
    }
    
    /// 処理中かどうか（録音中 or 認識処理中）
    public var isActive: Bool {
        return self == .recording || self == .processing
    }
    
    /// 結果表示可能かどうか
    public var canShowResult: Bool {
        return self == .resultReady || self == .choiceDisplayed
    }
}