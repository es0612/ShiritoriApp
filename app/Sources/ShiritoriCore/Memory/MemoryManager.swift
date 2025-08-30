import SwiftUI
import Foundation
import Observation

#if canImport(UIKit)
import UIKit
#endif

/// メモリ使用量監視と自動最適化マネージャー
@Observable
public class MemoryManager {
    
    /// シングルトンインスタンス
    public static let shared = MemoryManager()
    
    /// メモリ監視の状態
    public var isMonitoring: Bool = false
    
    /// 現在のメモリ使用量（MB）
    public var currentMemoryUsage: Double = 0.0
    
    /// メモリ圧迫レベル
    public var memoryPressureLevel: MemoryPressureLevel = .normal
    
    /// メモリ警告の履歴
    public var memoryWarnings: [MemoryWarning] = []
    
    /// 自動最適化の状態
    public var autoOptimizationEnabled: Bool = true
    
    /// メモリ監視タイマー
    private var monitoringTimer: Timer?
    
    /// 最適化実行中フラグ
    private var isOptimizing: Bool = false
    
    /// メモリ圧迫レベルの定義
    public enum MemoryPressureLevel: Int, CaseIterable {
        case normal = 0      // 正常（使用量 < 60%）
        case moderate = 1    // 中程度（60% ≤ 使用量 < 80%）
        case high = 2        // 高（80% ≤ 使用量 < 95%）
        case critical = 3    // 危険（使用量 ≥ 95%）
        
        var displayName: String {
            switch self {
            case .normal: return "正常"
            case .moderate: return "中程度"
            case .high: return "高"
            case .critical: return "危険"
            }
        }
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .moderate: return .yellow
            case .high: return .orange
            case .critical: return .red
            }
        }
        
        var threshold: Double {
            switch self {
            case .normal: return 0.6
            case .moderate: return 0.8
            case .high: return 0.95
            case .critical: return 1.0
            }
        }
    }
    
    /// メモリ警告情報
    public struct MemoryWarning {
        let timestamp: Date
        let level: MemoryPressureLevel
        let usageAtTime: Double
        let automaticAction: String?
        let context: String
        
        var description: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            
            return "[\(formatter.string(from: timestamp))] \(level.displayName) - \(String(format: "%.1f", usageAtTime))MB"
        }
    }
    
    private init() {
        AppLogger.shared.debug("MemoryManager初期化")
        startMonitoring()
        setupMemoryWarningObserver()
    }
    
    deinit {
        stopMonitoring()
    }
    
    /// メモリ監視の開始
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        AppLogger.shared.info("メモリ監視開始")
        
        monitoringTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.performMemoryCheck()
        }
    }
    
    /// メモリ監視の停止
    public func stopMonitoring() {
        monitoringTimer?.invalidate()
        monitoringTimer = nil
        isMonitoring = false
        AppLogger.shared.debug("メモリ監視停止")
    }
    
    /// システムメモリ警告の監視設定
    private func setupMemoryWarningObserver() {
        #if canImport(UIKit)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSystemMemoryWarning()
        }
        #endif
    }
    
    /// メモリチェックの実行
    private func performMemoryCheck() {
        let memoryInfo = getDetailedMemoryInfo()
        currentMemoryUsage = memoryInfo.usedMemoryMB
        
        let newPressureLevel = calculatePressureLevel(memoryInfo.memoryPressure)
        
        // 圧迫レベルが変化した場合の処理
        if newPressureLevel != memoryPressureLevel {
            let previousLevel = memoryPressureLevel
            memoryPressureLevel = newPressureLevel
            
            AppLogger.shared.info("メモリ圧迫レベル変更: \(previousLevel.displayName) → \(newPressureLevel.displayName)")
            
            handlePressureLevelChange(from: previousLevel, to: newPressureLevel)
        }
        
        // 高い圧迫レベルでの自動最適化
        if newPressureLevel.rawValue >= MemoryPressureLevel.high.rawValue && autoOptimizationEnabled {
            performAutomaticOptimization(level: newPressureLevel)
        }
    }
    
    /// メモリ使用量の詳細情報取得
    private func getDetailedMemoryInfo() -> (usedMemoryMB: Double, availableMemoryMB: Double, memoryPressure: Double) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let usedMemoryBytes = Double(info.resident_size)
            let usedMemoryMB = usedMemoryBytes / (1024 * 1024)
            
            // 利用可能メモリの推定（デバイス依存）
            let physicalMemoryBytes = Double(ProcessInfo.processInfo.physicalMemory)
            let physicalMemoryMB = physicalMemoryBytes / (1024 * 1024)
            
            // メモリ圧迫度の計算
            let memoryPressure = usedMemoryMB / (physicalMemoryMB * 0.8) // システム予約分を除く
            
            return (usedMemoryMB, physicalMemoryMB * 0.8, memoryPressure)
        }
        
        // 取得失敗時のフォールバック値
        return (100.0, 1000.0, 0.1)
    }
    
    /// 圧迫レベルの計算
    private func calculatePressureLevel(_ pressure: Double) -> MemoryPressureLevel {
        for level in MemoryPressureLevel.allCases.reversed() {
            if pressure >= level.threshold {
                return level
            }
        }
        return .normal
    }
    
    /// 圧迫レベル変更時の処理
    private func handlePressureLevelChange(from: MemoryPressureLevel, to: MemoryPressureLevel) {
        let warning = MemoryWarning(
            timestamp: Date(),
            level: to,
            usageAtTime: currentMemoryUsage,
            automaticAction: to.rawValue >= MemoryPressureLevel.high.rawValue ? "自動最適化実行" : nil,
            context: "レベル変更: \(from.displayName) → \(to.displayName)"
        )
        
        addMemoryWarning(warning)
        
        // 通知を送信（UI更新のため）
        NotificationCenter.default.post(
            name: .memoryPressureLevelChanged,
            object: nil,
            userInfo: [
                "previousLevel": from,
                "newLevel": to,
                "currentUsage": currentMemoryUsage
            ]
        )
    }
    
    /// システムメモリ警告の処理
    private func handleSystemMemoryWarning() {
        AppLogger.shared.warning("システムメモリ警告を受信")
        
        let warning = MemoryWarning(
            timestamp: Date(),
            level: .critical,
            usageAtTime: currentMemoryUsage,
            automaticAction: "緊急最適化実行",
            context: "システムメモリ警告"
        )
        
        addMemoryWarning(warning)
        
        // 緊急最適化の実行
        performEmergencyOptimization()
    }
    
    /// 自動最適化の実行
    private func performAutomaticOptimization(level: MemoryPressureLevel) {
        guard !isOptimizing else { return }
        
        isOptimizing = true
        AppLogger.shared.info("自動メモリ最適化開始: レベル\(level.displayName)")
        
        Task {
            defer { isOptimizing = false }
            
            let optimizationResults = await executeOptimizationStrategy(for: level)
            
            await MainActor.run {
                AppLogger.shared.info("自動最適化完了: \(optimizationResults)")
            }
        }
    }
    
    /// 緊急最適化の実行
    private func performEmergencyOptimization() {
        AppLogger.shared.warning("緊急メモリ最適化実行")
        
        // 即座にクリティカルなデータのみ保持
        clearNonEssentialData()
        
        // ゲーム状態の軽量化
        optimizeGameStates()
        
        // 画像キャッシュのクリア
        clearImageCaches()
        
        // ガベージコレクションの促進（Swiftでは自動）
        // 強制的に未使用オブジェクトの参照をクリア
        
        AppLogger.shared.info("緊急最適化完了")
    }
    
    /// 最適化戦略の実行
    private func executeOptimizationStrategy(for level: MemoryPressureLevel) async -> String {
        var actions: [String] = []
        
        switch level {
        case .normal:
            // 通常時は何もしない
            break
            
        case .moderate:
            // 軽度の最適化
            if await clearOldLogEntries() {
                actions.append("古いログ削除")
            }
            
        case .high:
            // 積極的な最適化
            if await clearOldLogEntries() {
                actions.append("古いログ削除")
            }
            if await compressGameSnapshots() {
                actions.append("スナップショット圧縮")
            }
            
        case .critical:
            // 緊急最適化
            clearNonEssentialData()
            optimizeGameStates()
            clearImageCaches()
            actions.append("緊急データクリア")
        }
        
        return actions.isEmpty ? "最適化不要" : actions.joined(separator: ", ")
    }
    
    /// 非必須データのクリア
    private func clearNonEssentialData() {
        // UIState のクリーンアップ
        Task { @MainActor in
            UIState.shared.resetAll()
        }
        
        // メモリ警告履歴の削減
        if memoryWarnings.count > 5 {
            memoryWarnings = Array(memoryWarnings.suffix(5))
        }
    }
    
    /// ゲーム状態の最適化
    private func optimizeGameStates() {
        // GameStateSnapshotManager の軽量化
        // 実際の実装では適切なクリーンアップを行う
        AppLogger.shared.debug("ゲーム状態軽量化実行")
    }
    
    /// 画像キャッシュのクリア
    private func clearImageCaches() {
        // SwiftUIの画像キャッシュクリア
        // 実際の実装では適切なキャッシュクリア処理を行う
        AppLogger.shared.debug("画像キャッシュクリア実行")
    }
    
    /// 古いログエントリの削除
    private func clearOldLogEntries() async -> Bool {
        // AppLogger の古いエントリ削除
        // 実際の実装では適切なログクリア処理を行う
        return true
    }
    
    /// ゲームスナップショットの圧縮
    private func compressGameSnapshots() async -> Bool {
        // 古いスナップショットの削除や圧縮
        // 実際の実装では GameStateSnapshotManager と連携
        return true
    }
    
    /// メモリ警告の追加
    private func addMemoryWarning(_ warning: MemoryWarning) {
        memoryWarnings.append(warning)
        
        // 履歴サイズの制限
        if memoryWarnings.count > 50 {
            memoryWarnings.removeFirst(memoryWarnings.count - 50)
        }
    }
    
    /// 手動最適化の実行
    public func performManualOptimization() {
        AppLogger.shared.info("手動メモリ最適化実行")
        performAutomaticOptimization(level: .high)
    }
    
    /// メモリ状態のリセット
    public func resetMemoryState() {
        memoryWarnings.removeAll()
        memoryPressureLevel = .normal
        currentMemoryUsage = 0.0
        AppLogger.shared.info("メモリ状態リセット完了")
    }
    
    /// デバッグレポートの生成
    public func generateMemoryReport() -> String {
        let memoryInfo = getDetailedMemoryInfo()
        
        let report = """
        
        === MemoryManager Debug Report ===
        Monitoring: \(isMonitoring)
        Current Usage: \(String(format: "%.1f", currentMemoryUsage))MB
        Available: \(String(format: "%.1f", memoryInfo.availableMemoryMB))MB
        Pressure Level: \(memoryPressureLevel.displayName) (\(String(format: "%.1f", memoryInfo.memoryPressure * 100))%)
        Auto Optimization: \(autoOptimizationEnabled)
        Warnings Count: \(memoryWarnings.count)
        
        Recent Warnings:
        \(memoryWarnings.suffix(3).map { $0.description }.joined(separator: "\n"))
        
        """
        
        return report
    }
}

/// メモリ関連の通知名
extension Notification.Name {
    static let memoryPressureLevelChanged = Notification.Name("memoryPressureLevelChanged")
    static let memoryOptimizationCompleted = Notification.Name("memoryOptimizationCompleted")
}
