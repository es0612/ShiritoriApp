import Foundation
import SwiftUI
import Observation

/// アプリ全体のUI状態を統一的に管理する@Observableクラス
/// アニメーション、モーダル表示、遷移状態を集約管理し、遅延処理を排除する
@MainActor
@Observable
public class UIState {
    
    // MARK: - アニメーション状態管理
    
    /// アニメーション段階を表す汎用enum
    public enum AnimationPhase {
        case hidden
        case appearing
        case showing
        case highlighted
        case disappearing
    }
    
    /// 各種アニメーション状態を管理
    public private(set) var animationStates: [String: AnimationPhase] = [:]
    
    /// アニメーション数値状態（スケール、オフセットなど）
    public private(set) var animationValues: [String: Double] = [:]
    
    /// アニメーション中フラグ
    public private(set) var activeAnimations: Set<String> = []
    
    // MARK: - モーダル・シート表示状態
    
    /// モーダル表示状態を管理
    public private(set) var modalStates: [String: Bool] = [:]
    
    /// シート表示状態を管理
    public private(set) var sheetStates: [String: Bool] = [:]
    
    /// アラート表示状態を管理
    public private(set) var alertStates: [String: Bool] = [:]
    
    // MARK: - 遷移・フロー管理
    
    /// 各種遷移段階を管理
    public private(set) var transitionPhases: [String: String] = [:]
    
    /// 処理中フラグを管理
    public private(set) var processingFlags: [String: Bool] = [:]
    
    // MARK: - タイミング管理
    
    /// 自動遷移トリガー（遅延の代替）
    public private(set) var autoTransitionTriggers: [String: Date] = [:]
    
    /// 自動遷移間隔設定
    public private(set) var autoTransitionIntervals: [String: TimeInterval] = [:]
    
    // MARK: - シングルトン
    public static let shared = UIState()
    private init() {}
    
    // MARK: - アニメーション制御
    
    /// アニメーション段階を設定
    public func setAnimationPhase(_ phase: AnimationPhase, for key: String) {
        let oldPhase = animationStates[key]
        animationStates[key] = phase
        
        AppLogger.shared.debug("アニメーション段階変更 [\(key)]: \(oldPhase?.description ?? "nil") → \(phase.description)")
        
        // 段階変更に応じた追加処理
        handleAnimationPhaseChange(key: key, from: oldPhase, to: phase)
    }
    
    /// アニメーション数値を設定
    public func setAnimationValue(_ value: Double, for key: String) {
        animationValues[key] = value
    }
    
    /// アニメーション開始
    public func startAnimation(_ key: String) {
        activeAnimations.insert(key)
        AppLogger.shared.debug("アニメーション開始: \(key)")
    }
    
    /// アニメーション終了
    public func endAnimation(_ key: String) {
        activeAnimations.remove(key)
        AppLogger.shared.debug("アニメーション終了: \(key)")
    }
    
    /// アニメーション中かチェック
    public func isAnimating(_ key: String) -> Bool {
        return activeAnimations.contains(key)
    }
    
    // MARK: - モーダル制御
    
    /// モーダルを表示
    public func showModal(_ key: String) {
        modalStates[key] = true
        AppLogger.shared.debug("モーダル表示: \(key)")
    }
    
    /// モーダルを非表示
    public func hideModal(_ key: String) {
        modalStates[key] = false
        AppLogger.shared.debug("モーダル非表示: \(key)")
    }
    
    /// モーダル表示状態を取得
    public func isModalShown(_ key: String) -> Bool {
        return modalStates[key] ?? false
    }
    
    /// シートを表示
    public func showSheet(_ key: String) {
        sheetStates[key] = true
        AppLogger.shared.debug("シート表示: \(key)")
    }
    
    /// シートを非表示
    public func hideSheet(_ key: String) {
        sheetStates[key] = false
        AppLogger.shared.debug("シート非表示: \(key)")
    }
    
    /// シート表示状態を取得
    public func isSheetShown(_ key: String) -> Bool {
        return sheetStates[key] ?? false
    }
    
    /// アラートを表示
    public func showAlert(_ key: String) {
        alertStates[key] = true
        AppLogger.shared.debug("アラート表示: \(key)")
    }
    
    /// アラートを非表示
    public func hideAlert(_ key: String) {
        alertStates[key] = false
        AppLogger.shared.debug("アラート非表示: \(key)")
    }
    
    /// アラート表示状態を取得
    public func isAlertShown(_ key: String) -> Bool {
        return alertStates[key] ?? false
    }
    
    // MARK: - 遷移制御
    
    /// 遷移段階を設定
    public func setTransitionPhase(_ phase: String, for key: String) {
        let oldPhase = transitionPhases[key]
        transitionPhases[key] = phase
        AppLogger.shared.debug("遷移段階変更 [\(key)]: \(oldPhase ?? "nil") → \(phase)")
    }
    
    /// 遷移段階を取得
    public func getTransitionPhase(_ key: String) -> String? {
        return transitionPhases[key]
    }
    
    /// 処理中フラグを設定
    public func setProcessing(_ isProcessing: Bool, for key: String) {
        processingFlags[key] = isProcessing
        AppLogger.shared.debug("処理中フラグ [\(key)]: \(isProcessing)")
    }
    
    /// 処理中かチェック
    public func isProcessing(_ key: String) -> Bool {
        return processingFlags[key] ?? false
    }
    
    // MARK: - 自動遷移制御（遅延処理の代替）
    
    /// 自動遷移を設定（指定時間後に状態変更を実行）
    public func scheduleAutoTransition(for key: String, after interval: TimeInterval, action: @escaping () -> Void) {
        autoTransitionTriggers[key] = Date()
        autoTransitionIntervals[key] = interval
        
        AppLogger.shared.debug("自動遷移スケジュール [\(key)]: \(interval)秒後")
        
        // Task による状態ベース遷移（DispatchQueue.main.asyncAfter の代替）
        Task { @MainActor in
            // 指定時間待機
            try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            
            // トリガーが変更されていない場合のみ実行（キャンセル対応）
            if let scheduledTime = autoTransitionTriggers[key],
               Date().timeIntervalSince(scheduledTime) >= interval - 0.1 {
                action()
                autoTransitionTriggers.removeValue(forKey: key)
                autoTransitionIntervals.removeValue(forKey: key)
                AppLogger.shared.debug("自動遷移実行 [\(key)]")
            } else {
                AppLogger.shared.debug("自動遷移キャンセル [\(key)]")
            }
        }
    }
    
    /// 自動遷移をキャンセル
    public func cancelAutoTransition(for key: String) {
        autoTransitionTriggers.removeValue(forKey: key)
        autoTransitionIntervals.removeValue(forKey: key)
        AppLogger.shared.debug("自動遷移キャンセル: \(key)")
    }
    
    /// 状態をクリア
    public func clearState(for key: String) {
        animationStates.removeValue(forKey: key)
        animationValues.removeValue(forKey: key)
        activeAnimations.remove(key)
        modalStates.removeValue(forKey: key)
        sheetStates.removeValue(forKey: key)
        alertStates.removeValue(forKey: key)
        transitionPhases.removeValue(forKey: key)
        processingFlags.removeValue(forKey: key)
        cancelAutoTransition(for: key)
        AppLogger.shared.debug("状態クリア: \(key)")
    }
    
    /// 全状態をリセット
    public func resetAll() {
        animationStates.removeAll()
        animationValues.removeAll()
        activeAnimations.removeAll()
        modalStates.removeAll()
        sheetStates.removeAll()
        alertStates.removeAll()
        transitionPhases.removeAll()
        processingFlags.removeAll()
        autoTransitionTriggers.removeAll()
        autoTransitionIntervals.removeAll()
        AppLogger.shared.info("UI状態全リセット")
    }
    
    // MARK: - Private Methods
    
    /// アニメーション段階変更時の処理
    private func handleAnimationPhaseChange(key: String, from oldPhase: AnimationPhase?, to newPhase: AnimationPhase) {
        switch newPhase {
        case .appearing:
            startAnimation(key)
        case .disappearing, .hidden:
            endAnimation(key)
        default:
            break
        }
    }
}

// MARK: - Helper Extensions

extension UIState.AnimationPhase {
    var description: String {
        switch self {
        case .hidden: return "hidden"
        case .appearing: return "appearing"
        case .showing: return "showing"
        case .highlighted: return "highlighted"
        case .disappearing: return "disappearing"
        }
    }
}

// MARK: - Commonly Used Keys

extension UIState {
    /// よく使用される状態キーを定数として定義
    public enum Keys {
        // アニメーション
        public static let confetti = "confetti"
        public static let playerTransition = "playerTransition"
        public static let titleAnimation = "titleAnimation"
        public static let pulseAnimation = "pulseAnimation"
        
        // モーダル・シート
        public static let pauseMenu = "pauseMenu"
        public static let addPlayerSheet = "addPlayerSheet"
        public static let rulesEditor = "rulesEditor"
        public static let settingsModal = "settingsModal"
        
        // 処理状態
        public static let gameStarting = "gameStarting"
        public static let computerThinking = "computerThinking"
        public static let wordValidation = "wordValidation"
        
        // 遷移
        public static let gameToResults = "gameToResults"
        public static let tutorialFlow = "tutorialFlow"
    }
}
