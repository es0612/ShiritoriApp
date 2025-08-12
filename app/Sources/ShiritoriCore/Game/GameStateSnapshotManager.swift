import SwiftUI
import SwiftData
import Foundation

/// ゲーム状態スナップショットの管理クラス
@Observable
public class GameStateSnapshotManager {
    
    /// シングルトンインスタンス
    public static let shared = GameStateSnapshotManager()
    
    /// 現在アクティブなスナップショット
    public var activeSnapshot: GameStateSnapshot?
    
    /// 自動保存の間隔（秒）
    public var autoSaveInterval: TimeInterval = 30.0
    
    /// 自動保存タイマー
    private var autoSaveTimer: Timer?
    
    /// 最大保持スナップショット数
    private let maxSnapshots = 20
    
    /// 復元候補スナップショット
    public var restorableSnapshots: [GameStateSnapshot] = []
    
    private init() {
        AppLogger.shared.debug("GameStateSnapshotManager初期化")
    }
    
    deinit {
        stopAutoSave()
    }
    
    /// 自動保存の開始
    public func startAutoSave(gameData: GameSetupData, gameState: GameState) {
        stopAutoSave() // 既存のタイマーを停止
        
        AppLogger.shared.info("自動保存開始: 間隔\(autoSaveInterval)秒")
        
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveInterval, repeats: true) { [weak self] _ in
            self?.performAutoSave(gameData: gameData, gameState: gameState)
        }
    }
    
    /// 自動保存の停止
    public func stopAutoSave() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        AppLogger.shared.debug("自動保存停止")
    }
    
    /// スナップショットの作成
    public func createSnapshot(
        gameData: GameSetupData,
        gameState: GameState,
        type: GameStateSnapshot.SnapshotType = .autoSave,
        modelContext: ModelContext
    ) throws -> GameStateSnapshot {
        
        let gameStateData = GameStateData(from: gameState)
        let snapshot = try GameStateSnapshot(
            gameData: gameData,
            gameState: gameStateData,
            snapshotType: type
        )
        
        // SwiftDataに保存
        modelContext.insert(snapshot)
        
        do {
            try modelContext.save()
            
            // アクティブスナップショットの更新
            if type != .autoSave {
                activeSnapshot = snapshot
            }
            
            AppLogger.shared.info("スナップショット作成成功: \(type.displayName)")
            
            // 古いスナップショットのクリーンアップ
            Task {
                await cleanupOldSnapshots(modelContext: modelContext)
            }
            
            return snapshot
            
        } catch {
            AppLogger.shared.error("スナップショット保存失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 自動保存の実行
    private func performAutoSave(gameData: GameSetupData, gameState: GameState) {
        guard gameState.isGameActive else {
            AppLogger.shared.debug("ゲーム非アクティブのため自動保存をスキップ")
            return
        }
        
        Task { @MainActor in
            do {
                // ModelContextを取得（実際の実装では適切に取得する必要がある）
                // この例では仮想的な実装
                if let modelContext = await getModelContext() {
                    _ = try createSnapshot(
                        gameData: gameData,
                        gameState: gameState,
                        type: .autoSave,
                        modelContext: modelContext
                    )
                }
            } catch {
                AppLogger.shared.warning("自動保存失敗: \(error.localizedDescription)")
            }
        }
    }
    
    /// バックグラウンド移行時のスナップショット作成
    public func createBackgroundSnapshot(
        gameData: GameSetupData,
        gameState: GameState,
        modelContext: ModelContext
    ) throws -> GameStateSnapshot {
        AppLogger.shared.info("バックグラウンド移行前スナップショット作成")
        
        return try createSnapshot(
            gameData: gameData,
            gameState: gameState,
            type: .beforeBackground,
            modelContext: modelContext
        )
    }
    
    /// 復元可能なスナップショットの取得
    public func getRestorableSnapshots(modelContext: ModelContext) throws -> [GameStateSnapshot] {
        let request = FetchDescriptor<GameStateSnapshot>(
            predicate: #Predicate<GameStateSnapshot> { snapshot in
                snapshot.canRestore && snapshot.isValid
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        do {
            let snapshots = try modelContext.fetch(request)
            self.restorableSnapshots = snapshots
            
            AppLogger.shared.info("復元可能スナップショット取得: \(snapshots.count)件")
            
            return snapshots
        } catch {
            AppLogger.shared.error("復元可能スナップショット取得失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 最適なスナップショットの選択
    public func selectBestSnapshot(from snapshots: [GameStateSnapshot]) -> GameStateSnapshot? {
        // 優先度とタイムスタンプで並び替え
        let sortedSnapshots = snapshots
            .filter { $0.canRestore && $0.isValid }
            .sorted { first, second in
                if first.snapshotType.priority != second.snapshotType.priority {
                    return first.snapshotType.priority > second.snapshotType.priority
                }
                return first.lastUpdatedAt > second.lastUpdatedAt
            }
        
        let bestSnapshot = sortedSnapshots.first
        
        if let snapshot = bestSnapshot {
            AppLogger.shared.info("最適スナップショット選択: \(snapshot.snapshotType.displayName), 作成日時: \(snapshot.createdAt)")
        } else {
            AppLogger.shared.warning("復元可能なスナップショットが見つかりません")
        }
        
        return bestSnapshot
    }
    
    /// ゲーム状態の復元
    public func restoreGameState(from snapshot: GameStateSnapshot) throws -> (GameSetupData, GameStateData) {
        AppLogger.shared.info("ゲーム状態復元開始: \(snapshot.snapshotId)")
        
        guard snapshot.canRestore && snapshot.isValid else {
            let error = GameRestoreError.invalidSnapshot("復元不可能なスナップショット")
            AppLogger.shared.error("復元失敗: \(error.localizedDescription)")
            throw error
        }
        
        do {
            let gameData = try snapshot.restoreGameData()
            let gameStateData = try snapshot.restoreGameState()
            
            // 復元されたデータの最終検証
            try validateRestoredData(gameData: gameData, gameStateData: gameStateData)
            
            AppLogger.shared.info("ゲーム状態復元成功: 参加者\(gameData.participants.count)人, 単語\(gameStateData.usedWords.count)個")
            
            return (gameData, gameStateData)
            
        } catch {
            // 復元失敗時はスナップショットを無効化
            snapshot.invalidate(reason: "復元失敗: \(error.localizedDescription)")
            AppLogger.shared.error("ゲーム状態復元失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 復元されたデータの検証
    private func validateRestoredData(gameData: GameSetupData, gameStateData: GameStateData) throws {
        // 基本的な整合性チェック
        guard gameData.participants.count > 0 else {
            throw GameRestoreError.invalidState("参加者が存在しません")
        }
        
        guard gameStateData.currentTurnIndex < gameData.participants.count else {
            throw GameRestoreError.invalidState("無効なターンインデックス")
        }
        
        // 使用単語の妥当性チェック
        if gameStateData.usedWords.count > 1000 {
            throw GameRestoreError.invalidState("異常に多い単語数: \(gameStateData.usedWords.count)")
        }
        
        // タイムスタンプの妥当性チェック
        if let startTime = gameStateData.gameStartTime,
           abs(startTime.timeIntervalSinceNow) > 86400 * 7 { // 7日以上前
            AppLogger.shared.warning("古いスナップショット: \(startTime)")
        }
    }
    
    /// 古いスナップショットのクリーンアップ
    private func cleanupOldSnapshots(modelContext: ModelContext) async {
        do {
            let allSnapshots = try modelContext.fetch(FetchDescriptor<GameStateSnapshot>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            ))
            
            // 最大数を超える古いスナップショットを削除
            if allSnapshots.count > maxSnapshots {
                let snapshotsToDelete = Array(allSnapshots.dropFirst(maxSnapshots))
                
                for snapshot in snapshotsToDelete {
                    modelContext.delete(snapshot)
                }
                
                try modelContext.save()
                AppLogger.shared.info("古いスナップショット削除: \(snapshotsToDelete.count)件")
            }
            
            // 7日より古い無効なスナップショットを削除
            let cutoffDate = Date().addingTimeInterval(-7 * 24 * 60 * 60)
            let oldInvalidSnapshots = allSnapshots.filter { snapshot in
                snapshot.createdAt < cutoffDate && (!snapshot.isValid || !snapshot.canRestore)
            }
            
            for snapshot in oldInvalidSnapshots {
                modelContext.delete(snapshot)
            }
            
            if !oldInvalidSnapshots.isEmpty {
                try modelContext.save()
                AppLogger.shared.info("古い無効スナップショット削除: \(oldInvalidSnapshots.count)件")
            }
            
        } catch {
            AppLogger.shared.error("スナップショットクリーンアップ失敗: \(error.localizedDescription)")
        }
    }
    
    /// すべてのスナップショットの削除
    public func clearAllSnapshots(modelContext: ModelContext) throws {
        let allSnapshots = try modelContext.fetch(FetchDescriptor<GameStateSnapshot>())
        
        for snapshot in allSnapshots {
            modelContext.delete(snapshot)
        }
        
        try modelContext.save()
        
        activeSnapshot = nil
        restorableSnapshots.removeAll()
        
        AppLogger.shared.info("全スナップショット削除完了: \(allSnapshots.count)件")
    }
    
    /// ModelContextの取得（実装に応じて調整が必要）
    private func getModelContext() async -> ModelContext? {
        // 実際の実装では、適切な方法でModelContextを取得する必要がある
        // この例では仮想的な実装
        return nil
    }
    
    /// デバッグレポートの生成
    public func generateDebugReport() -> String {
        let report = """
        
        === GameStateSnapshotManager Debug Report ===
        Auto Save Interval: \(autoSaveInterval)s
        Auto Save Active: \(autoSaveTimer != nil)
        Active Snapshot: \(activeSnapshot?.snapshotId ?? "None")
        Restorable Snapshots: \(restorableSnapshots.count)
        Max Snapshots: \(maxSnapshots)
        
        Recent Snapshots:
        \(restorableSnapshots.prefix(3).map { snapshot in
            "- \(snapshot.snapshotType.displayName): \(snapshot.createdAt) (\(snapshot.progressPercentage.formatted(.number.precision(.fractionLength(1))))%)"
        }.joined(separator: "\n"))
        
        """
        
        return report
    }
}