import SwiftUI
import SwiftData
import Foundation
import Observation

/// ゲームデータ永続化管理クラス
/// SwiftDataを使用したGameSessionの保存・復元処理を担当
@Observable
public class GameDataManager {
    
    /// シングルトンインスタンス
    public static let shared = GameDataManager()
    
    private init() {
        AppLogger.shared.debug("GameDataManager初期化完了")
    }
    
    // MARK: - GameSession Save Methods
    
    /// ゲーム終了時にGameSessionを作成してSwiftDataに保存
    public func saveGameSession(
        gameData: GameSetupData,
        winner: GameParticipant?,
        usedWords: [String],
        gameDuration: Int,
        modelContext: ModelContext,
        usedWordAssignments: [(word: String, playerName: String)]? = nil
    ) {
        AppLogger.shared.info("GameSession保存開始: 勝者=\(winner?.name ?? "なし"), 単語数=\(usedWords.count)")
        
        // GameSessionオブジェクトを作成
        let gameSession = GameSession(playerNames: gameData.participants.map { $0.name })
        
        if let assignments = usedWordAssignments, !assignments.isEmpty {
            for (idx, item) in assignments.enumerated() {
                gameSession.addWord(item.word, by: item.playerName)
                AppLogger.shared.debug("単語追加(確定割当): '\(item.word)' by \(item.playerName) (順番: \(idx + 1))")
            }
        } else {
            // 互換性: 旧ロジックでの割当（参加者数で循環）
            for (index, word) in usedWords.enumerated() {
                let playerIndex = index % gameData.participants.count
                let playerName = gameData.participants[playerIndex].name
                gameSession.addWord(word, by: playerName)
                AppLogger.shared.debug("単語追加: '\(word)' by \(playerName) (順番: \(index + 1))")
            }
        }
        
        // 勝敗結果に応じてGameSessionを完了状態に設定
        if let winner = winner {
            gameSession.completeGame(winner: winner.name, gameDurationSeconds: TimeInterval(gameDuration))
            AppLogger.shared.info("GameSession完了設定: 勝者=\(winner.name)")
        } else {
            gameSession.completeDraw(gameDurationSeconds: TimeInterval(gameDuration))
            AppLogger.shared.info("GameSession完了設定: 引き分け")
        }
        
        // SwiftDataに保存
        do {
            modelContext.insert(gameSession)
            try modelContext.save()
            let participantsList = gameSession.participantNames.joined(separator: ", ")
            AppLogger.shared.info("GameSession保存成功: ID=\(gameSession.uniqueGameId), 参加者=\(participantsList), 単語数=\(gameSession.usedWords.count)")
        } catch {
            AppLogger.shared.error("GameSession保存失敗: \(error.localizedDescription)")
            // エラーをthrowせず、ログに記録するのみ（ゲーム進行を妨げない）
        }
    }
    
    // MARK: - GameSession Query Methods
    
    /// 最近のゲームセッションを取得
    public func fetchRecentGameSessions(limit: Int = 10, modelContext: ModelContext) -> [GameSession] {
        do {
            let descriptor = FetchDescriptor<GameSession>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let allSessions = try modelContext.fetch(descriptor)
            return Array(allSessions.prefix(limit))
        } catch {
            AppLogger.shared.error("最近のGameSession取得失敗: \(error.localizedDescription)")
            return []
        }
    }
    
    /// プレイヤー別の統計情報を取得
    public func fetchPlayerStatistics(playerName: String, modelContext: ModelContext) -> PlayerStatistics {
        do {
            let descriptor = FetchDescriptor<GameSession>()
            let allSessions = try modelContext.fetch(descriptor)
            
            let playerSessions = allSessions.filter { session in
                session.participantNames.contains(playerName)
            }
            
            let totalGames = playerSessions.count
            let wins = playerSessions.filter { $0.winnerName == playerName }.count
            let draws = playerSessions.filter { $0.completionType == .draw }.count
            let losses = totalGames - wins - draws
            let winRate = totalGames > 0 ? Double(wins) / Double(totalGames) : 0.0
            
            let totalWords = playerSessions.reduce(0) { sum, session in
                // GameSessionのusedWordsから該当プレイヤーの単語数を計算
                let playerWords = session.usedWords.enumerated().filter { (index, _) in
                    let participantIndex = index % session.participantNames.count
                    return participantIndex < session.participantNames.count && session.participantNames[participantIndex] == playerName
                }
                return sum + playerWords.count
            }
            
            AppLogger.shared.debug("プレイヤー統計取得: \(playerName) - 総ゲーム数: \(totalGames), 勝利数: \(wins)")
            
            return PlayerStatistics(
                playerName: playerName,
                totalGames: totalGames,
                wins: wins,
                draws: draws,
                losses: losses,
                winRate: winRate,
                totalWordsUsed: totalWords
            )
        } catch {
            AppLogger.shared.error("プレイヤー統計取得失敗: \(error.localizedDescription)")
            return PlayerStatistics(
                playerName: playerName,
                totalGames: 0,
                wins: 0,
                draws: 0,
                losses: 0,
                winRate: 0.0,
                totalWordsUsed: 0
            )
        }
    }
    
    /// ゲームセッションの削除
    public func deleteGameSession(_ gameSession: GameSession, modelContext: ModelContext) {
        do {
            modelContext.delete(gameSession)
            try modelContext.save()
            AppLogger.shared.info("GameSession削除成功: ID=\(gameSession.uniqueGameId)")
        } catch {
            AppLogger.shared.error("GameSession削除失敗: \(error.localizedDescription)")
        }
    }
    
    /// 古いゲームセッションの自動削除（データサイズ管理）
    public func cleanupOldGameSessions(keepRecentCount: Int = 100, modelContext: ModelContext) {
        do {
            let descriptor = FetchDescriptor<GameSession>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            let allSessions = try modelContext.fetch(descriptor)
            
            if allSessions.count > keepRecentCount {
                let sessionsToDelete = Array(allSessions.dropFirst(keepRecentCount))
                for session in sessionsToDelete {
                    modelContext.delete(session)
                }
                try modelContext.save()
                AppLogger.shared.info("古いGameSession削除完了: \(sessionsToDelete.count)件")
            }
        } catch {
            AppLogger.shared.error("古いGameSession削除失敗: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Data Validation
    
    /// ゲームデータの整合性チェック
    public func validateGameData(gameData: GameSetupData) -> ValidationResult {
        var errors: [String] = []
        
        // 参加者数チェック
        if gameData.participants.isEmpty {
            errors.append("参加者が設定されていません")
        }
        
        if gameData.participants.count > 6 {
            errors.append("参加者数が多すぎます（最大6人）")
        }
        
        // 参加者名の重複チェック
        let participantNames = gameData.participants.map { $0.name }
        if Set(participantNames).count != participantNames.count {
            errors.append("参加者名が重複しています")
        }
        
        // ルール設定の妥当性チェック
        if gameData.rules.timeLimit < 5 || gameData.rules.timeLimit > 300 {
            errors.append("制限時間が無効です（5秒〜300秒の範囲で設定してください）")
        }
        
        return ValidationResult(
            isValid: errors.isEmpty,
            errors: errors
        )
    }
    
    /// SwiftDataの接続状態チェック
    public func checkDatabaseConnection(modelContext: ModelContext) -> Bool {
        do {
            // 簡単なクエリでデータベース接続を確認
            let descriptor = FetchDescriptor<GameSession>()
            _ = try modelContext.fetch(descriptor)
            AppLogger.shared.debug("SwiftData接続確認成功")
            return true
        } catch {
            AppLogger.shared.error("SwiftData接続確認失敗: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Supporting Types

/// プレイヤー統計情報
public struct PlayerStatistics {
    public let playerName: String
    public let totalGames: Int
    public let wins: Int
    public let draws: Int
    public let losses: Int
    public let winRate: Double
    public let totalWordsUsed: Int
    
    public init(playerName: String, totalGames: Int, wins: Int, draws: Int, losses: Int, winRate: Double, totalWordsUsed: Int) {
        self.playerName = playerName
        self.totalGames = totalGames
        self.wins = wins
        self.draws = draws
        self.losses = losses
        self.winRate = winRate
        self.totalWordsUsed = totalWordsUsed
    }
}

/// バリデーション結果
public struct ValidationResult {
    public let isValid: Bool
    public let errors: [String]
    
    public init(isValid: Bool, errors: [String]) {
        self.isValid = isValid
        self.errors = errors
    }
}
