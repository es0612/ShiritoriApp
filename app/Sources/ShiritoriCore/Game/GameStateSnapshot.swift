import SwiftUI
import SwiftData
import Foundation

/// ゲーム状態の保存・復元用スナップショット
@Model
public class GameStateSnapshot {
    
    /// 一意識別子
    @Attribute(.unique) public var snapshotId: String
    
    /// 作成日時
    public var createdAt: Date
    
    /// 最終更新日時
    public var lastUpdatedAt: Date
    
    /// ゲームデータ（JSON形式）
    @Attribute(.externalStorage) public var gameDataJson: Data
    
    /// ゲーム状態（JSON形式）
    @Attribute(.externalStorage) public var gameStateJson: Data
    
    /// 使用単語リスト
    public var usedWords: [String]
    
    /// 現在のターンインデックス
    public var currentTurnIndex: Int
    
    /// ゲーム開始時刻
    public var gameStartTime: Date
    
    /// 経過時間（秒）
    public var elapsedTime: Int
    
    /// ゲーム進行状況（パーセンテージ）
    public var progressPercentage: Double
    
    /// スナップショットの種類
    public var snapshotType: SnapshotType
    
    /// スナップショットの有効性
    public var isValid: Bool
    
    /// 復元可能性フラグ
    public var canRestore: Bool
    
    /// エラー情報（復元時）
    public var restoreError: String?
    
    /// メタデータ
    public var metadata: [String: String]
    
    public enum SnapshotType: String, CaseIterable, Codable {
        case autoSave = "auto_save"        // 自動保存
        case beforeBackground = "before_background" // バックグラウンド移行前
        case beforeTermination = "before_termination" // 終了前
        case userRequested = "user_requested" // ユーザー要求
        case errorRecovery = "error_recovery" // エラー復旧
        
        var displayName: String {
            switch self {
            case .autoSave: return "自動保存"
            case .beforeBackground: return "バックグラウンド前保存"
            case .beforeTermination: return "終了前保存"
            case .userRequested: return "手動保存"
            case .errorRecovery: return "エラー復旧保存"
            }
        }
        
        var priority: Int {
            switch self {
            case .beforeTermination: return 5
            case .beforeBackground: return 4
            case .userRequested: return 3
            case .errorRecovery: return 2
            case .autoSave: return 1
            }
        }
    }
    
    public init(
        gameData: GameSetupData,
        gameState: GameStateData,
        snapshotType: SnapshotType = .autoSave
    ) throws {
        self.snapshotId = UUID().uuidString
        self.createdAt = Date()
        self.lastUpdatedAt = Date()
        self.snapshotType = snapshotType
        
        // GameSetupDataをJSONエンコード
        self.gameDataJson = try JSONEncoder().encode(gameData)
        
        // GameStateDataをJSONエンコード
        self.gameStateJson = try JSONEncoder().encode(gameState)
        
        // 基本情報の設定
        self.usedWords = gameState.usedWords
        self.currentTurnIndex = gameState.currentTurnIndex
        self.gameStartTime = gameState.gameStartTime ?? Date()
        self.elapsedTime = gameState.elapsedTime
        
        // 有効性の初期判定
        self.isValid = true
        self.restoreError = nil
        
        // メタデータの設定
        self.metadata = [
            "participantCount": "\(gameData.participants.count)",
            "gameRules": gameData.rules.winCondition.rawValue,
            "platform": "iOS",
            "version": "1.0"
        ]
        
        // 計算値を直接設定
        self.progressPercentage = Self.calculateProgress(gameState: gameState)
        self.canRestore = Self.validateRestorability(gameData: gameData, gameState: gameState)
        
        AppLogger.shared.info("ゲーム状態スナップショット作成: \(snapshotType.displayName), ID: \(snapshotId)")
    }
    
    /// ゲーム進行状況の計算
    private static func calculateProgress(gameState: GameStateData) -> Double {
        let wordCount = Double(gameState.usedWords.count)
        let estimatedTotalWords = Double(gameState.participants.count * 10) // 推定総単語数
        return min(wordCount / estimatedTotalWords, 1.0) * 100.0
    }
    
    /// 復元可能性の検証
    private static func validateRestorability(gameData: GameSetupData, gameState: GameStateData) -> Bool {
        // 基本的な整合性チェック
        guard !gameData.participants.isEmpty,
              gameState.currentTurnIndex < gameData.participants.count,
              gameState.usedWords.count >= 0 else {
            return false
        }
        
        // ゲーム状態の論理的な整合性
        if gameState.isGameActive && gameState.usedWords.isEmpty && gameState.elapsedTime > 300 {
            // 5分以上経過しているのに単語がない場合は異常
            return false
        }
        
        return true
    }
    
    /// ゲームデータの復元
    public func restoreGameData() throws -> GameSetupData {
        do {
            let gameData = try JSONDecoder().decode(GameSetupData.self, from: gameDataJson)
            AppLogger.shared.debug("GameSetupData復元成功: 参加者\(gameData.participants.count)人")
            return gameData
        } catch {
            self.restoreError = "GameSetupData復元エラー: \(error.localizedDescription)"
            self.canRestore = false
            AppLogger.shared.error("GameSetupData復元失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// ゲーム状態の復元
    public func restoreGameState() throws -> GameStateData {
        do {
            let gameState = try JSONDecoder().decode(GameStateData.self, from: gameStateJson)
            
            // 復元後の整合性チェック
            if !validateRestoredState(gameState) {
                let error = GameRestoreError.invalidState("復元されたゲーム状態が無効です")
                self.restoreError = error.localizedDescription
                self.canRestore = false
                throw error
            }
            
            AppLogger.shared.info("GameState復元成功: ターン\(gameState.currentTurnIndex), 単語\(gameState.usedWords.count)個")
            return gameState
        } catch {
            self.restoreError = "GameState復元エラー: \(error.localizedDescription)"
            self.canRestore = false
            AppLogger.shared.error("GameState復元失敗: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// 復元された状態の検証
    private func validateRestoredState(_ gameState: GameStateData) -> Bool {
        // タイムスタンプの検証（未来の時刻でないか）
        if let startTime = gameState.gameStartTime, startTime > Date() {
            AppLogger.shared.warning("ゲーム開始時刻が未来: \(startTime)")
            return false
        }
        
        // 論理的整合性の検証
        if gameState.currentTurnIndex < 0 || gameState.elapsedTime < 0 {
            AppLogger.shared.warning("無効な数値: ターン\(gameState.currentTurnIndex), 経過時間\(gameState.elapsedTime)")
            return false
        }
        
        return true
    }
    
    /// スナップショットの無効化
    public func invalidate(reason: String) {
        self.isValid = false
        self.canRestore = false
        self.restoreError = reason
        self.lastUpdatedAt = Date()
        AppLogger.shared.info("スナップショット無効化: \(reason)")
    }
    
    /// スナップショットの更新
    public func updateSnapshot(gameState: GameStateData) throws {
        // 更新前の整合性チェック
        guard isValid else {
            throw GameRestoreError.invalidSnapshot("無効なスナップショットは更新できません")
        }
        
        // 新しい状態をエンコード
        self.gameStateJson = try JSONEncoder().encode(gameState)
        
        // 基本情報の更新
        self.usedWords = gameState.usedWords
        self.currentTurnIndex = gameState.currentTurnIndex
        self.elapsedTime = gameState.elapsedTime
        self.progressPercentage = Self.calculateProgress(gameState: gameState)
        self.lastUpdatedAt = Date()
        
        AppLogger.shared.debug("スナップショット更新完了: ID \(snapshotId)")
    }
    
    /// デバッグ情報の生成
    public func generateDebugInfo() -> String {
        return """
        
        === GameStateSnapshot Debug Info ===
        ID: \(snapshotId)
        Type: \(snapshotType.displayName)
        Created: \(createdAt)
        Updated: \(lastUpdatedAt)
        Valid: \(isValid)
        Can Restore: \(canRestore)
        Words: \(usedWords.count)
        Turn: \(currentTurnIndex)
        Progress: \(String(format: "%.1f", progressPercentage))%
        Elapsed: \(elapsedTime)s
        Error: \(restoreError ?? "None")
        Metadata: \(metadata)
        
        """
    }
}

/// ゲーム状態データの構造体（Codable対応）
public struct GameStateData: Codable {
    public let participants: [GameParticipant]
    public let usedWords: [String]
    public let currentTurnIndex: Int
    public let isGameActive: Bool
    public let gameStartTime: Date?
    public let elapsedTime: Int
    public let eliminatedPlayers: Set<String>
    public let winner: GameParticipant?
    public let eliminationHistory: [EliminationRecord]
    
    public init(from gameState: GameState) {
        self.participants = gameState.gameData.participants
        self.usedWords = gameState.usedWords
        self.currentTurnIndex = gameState.currentTurnIndex
        self.isGameActive = gameState.isGameActive
        self.gameStartTime = gameState.gameStartTime
        if let start = gameState.gameStartTime {
            self.elapsedTime = max(0, Int(Date().timeIntervalSince(start)))
        } else {
            self.elapsedTime = 0
        }
        self.eliminatedPlayers = gameState.eliminatedPlayers
        self.winner = gameState.winner
        self.eliminationHistory = gameState.eliminationHistory.map { EliminationRecord(playerId: $0.playerId, reason: $0.reason, order: $0.order) }
    }
}

/// ゲーム復元エラー
public enum GameRestoreError: Error, LocalizedError {
    case invalidSnapshot(String)
    case invalidState(String)
    case dataCorruption(String)
    case versionMismatch(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidSnapshot(let message):
            return "無効なスナップショット: \(message)"
        case .invalidState(let message):
            return "無効なゲーム状態: \(message)"
        case .dataCorruption(let message):
            return "データ破損: \(message)"
        case .versionMismatch(let message):
            return "バージョン不一致: \(message)"
        }
    }
}

/// 脱落記録（Codable対応）
public struct EliminationRecord: Codable {
    public let playerId: String
    public let reason: String
    public let order: Int
    
    public init(playerId: String, reason: String, order: Int) {
        self.playerId = playerId
        self.reason = reason
        self.order = order
    }
}
