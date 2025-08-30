import SwiftUI
import Foundation
import Observation

/// ナビゲーション状態の中央管理とエラーハンドリング
@Observable
public class NavigationManager {
    
    /// シングルトンインスタンス
    public static let shared = NavigationManager()
    
    /// 現在のナビゲーション状態
    public var currentState: NavigationState = .title
    
    /// ナビゲーションエラーの履歴
    public var errorHistory: [NavigationError] = []
    
    /// 自動復旧の試行回数制限
    private var recoveryAttempts: Int = 0
    private let maxRecoveryAttempts = 3
    
    private init() {
        AppLogger.shared.debug("NavigationManager初期化")
    }
    
    /// ナビゲーション状態の定義
    public enum NavigationState {
        case title
        case gameSetup
        case inGame
        case results
        case settings
        case error(NavigationError)
    }
    
    /// ナビゲーションエラーの種類
    public enum NavigationError: Error, CustomStringConvertible {
        case pathCorruption(details: String)
        case memoryPressure(details: String)
        case stateInconsistency(expected: String, actual: String)
        case backgroundRecovery(details: String)
        case unknownDestination(path: String)
        
        public var description: String {
            switch self {
            case .pathCorruption(let details):
                return "NavigationPath corrupted: \(details)"
            case .memoryPressure(let details):
                return "Memory pressure detected: \(details)"
            case .stateInconsistency(let expected, let actual):
                return "State inconsistency - expected: \(expected), actual: \(actual)"
            case .backgroundRecovery(let details):
                return "Background recovery needed: \(details)"
            case .unknownDestination(let path):
                return "Unknown navigation destination: \(path)"
            }
        }
        
        public var severity: ErrorSeverity {
            switch self {
            case .pathCorruption, .stateInconsistency:
                return .critical
            case .memoryPressure, .backgroundRecovery:
                return .warning
            case .unknownDestination:
                return .info
            }
        }
    }
    
    public enum ErrorSeverity {
        case info, warning, critical
    }
    
    /// 安全なタイトル画面復帰処理
    public func safeReturnToTitle(reason: String, navigationPath: inout NavigationPath) {
        AppLogger.shared.info("安全なタイトル復帰開始: \(reason)")
        navigationPath = NavigationPath()
        currentState = .title
        recoveryAttempts = 0
        AppLogger.shared.info("安全なタイトル復帰完了")
    }
    
    /// エラー状況の記録と処理
    public func handleError(_ error: NavigationError, navigationPath: inout NavigationPath) {
        AppLogger.shared.error("NavigationError: \(error.description)")
        errorHistory.append(error)
        
        // 履歴サイズを制限
        if errorHistory.count > 50 {
            errorHistory.removeFirst(errorHistory.count - 50)
        }
        
        // エラーの重要度に応じた処理
        switch error.severity {
        case .critical:
            performEmergencyRecovery(navigationPath: &navigationPath)
        case .warning:
            attemptAutomaticRecovery(error: error, navigationPath: &navigationPath)
        case .info:
            AppLogger.shared.debug("Info-level navigation error logged: \(error.description)")
        }
    }
    
    /// 緊急復旧処理
    private func performEmergencyRecovery(navigationPath: inout NavigationPath) {
        AppLogger.shared.warning("緊急復旧処理を開始")
        safeReturnToTitle(reason: "Emergency recovery", navigationPath: &navigationPath)
        UIState.shared.resetAll()
        AppLogger.shared.info("緊急復旧処理完了")
    }
    
    /// 自動復旧の試行
    private func attemptAutomaticRecovery(error: NavigationError, navigationPath: inout NavigationPath) {
        guard recoveryAttempts < maxRecoveryAttempts else {
            AppLogger.shared.warning("自動復旧試行回数上限に達しました - 緊急復旧に切り替え")
            performEmergencyRecovery(navigationPath: &navigationPath)
            return
        }
        
        recoveryAttempts += 1
        AppLogger.shared.info("自動復旧試行 \(recoveryAttempts)/\(maxRecoveryAttempts): \(error.description)")
        
        safeReturnToTitle(reason: "Automatic recovery", navigationPath: &navigationPath)
    }
    
    /// バックグラウンド復帰時の処理
    public func handleBackgroundReturn(navigationPath: inout NavigationPath) {
        AppLogger.shared.info("バックグラウンド復帰処理開始")
        let error = NavigationError.backgroundRecovery(details: "App returned from background")
        handleError(error, navigationPath: &navigationPath)
    }
    
    /// デバッグ情報の生成
    public func generateDebugReport() -> String {
        return """
        
        === NavigationManager Debug Report ===
        Current State: \(currentState)
        Recovery Attempts: \(recoveryAttempts)/\(maxRecoveryAttempts)
        Error History Count: \(errorHistory.count)
        
        """
    }
}
