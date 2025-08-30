import SwiftUI
import SwiftData
import Foundation
import Observation

#if canImport(UIKit)
import UIKit
#endif

/// ゲームロジック制御クラス
/// MainGameViewからビジネスロジックを分離して、責務を明確化
@MainActor
@Observable
public class GameController {
    // MARK: - Dependencies
    private let hiraganaConverter = HiraganaConverter()
    private let snapshotManager = GameStateSnapshotManager.shared
    private let dataManager = GameDataManager.shared
    
    // MARK: - Game State
    public private(set) var gameState: GameState
    public private(set) var gameData: GameSetupData
    public private(set) var gameStartTime: Date?
    public private(set) var previousPlayerId: String?
    
    // MARK: - Callbacks
    private let onGameEnd: (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void
    private let onGameAbandoned: (([String], Int, [(playerId: String, reason: String, order: Int)]) -> Void)?
    private let onNavigateToResults: ((GameResultsData) -> Void)?
    private let onQuitToTitle: (() -> Void)?
    private let onQuitToSettings: (() -> Void)?
    
    // MARK: - UI State Management
    private var uiState = UIState.shared
    
    public init(
        gameData: GameSetupData,
        onGameEnd: @escaping (GameParticipant?, [String], Int, [(playerId: String, reason: String, order: Int)]) -> Void,
        onGameAbandoned: (([String], Int, [(playerId: String, reason: String, order: Int)]) -> Void)? = nil,
        onNavigateToResults: ((GameResultsData) -> Void)? = nil,
        onQuitToTitle: (() -> Void)? = nil,
        onQuitToSettings: (() -> Void)? = nil
    ) {
        AppLogger.shared.debug("GameController初期化開始")
        
        self.gameData = gameData
        self.onGameEnd = onGameEnd
        self.onGameAbandoned = onGameAbandoned
        self.onNavigateToResults = onNavigateToResults
        self.onQuitToTitle = onQuitToTitle
        self.onQuitToSettings = onQuitToSettings
        
        AppLogger.shared.debug("GameState初期化前")
        self.gameState = GameState(gameData: gameData)
        AppLogger.shared.debug("GameController初期化完了")
    }
    
    // MARK: - Game Lifecycle
    
    /// ゲーム開始
    public func startGame(modelContext: ModelContext) {
        AppLogger.shared.info("ゲーム開始処理")
        
        // 前回ゲームのUI状態をクリア（Bug #4 対策）
        uiState.resetAll()
        AppLogger.shared.info("UI状態をリセット - 前回ゲームの状態をクリア")
        
        gameStartTime = Date()
        previousPlayerId = gameState.activePlayer.id
        gameState.startGame()
        if let t = gameStartTime {
            AppLogger.shared.debug("ゲーム開始時刻を記録: \(t)")
        } else {
            AppLogger.shared.warning("ゲーム開始時刻が未設定のためログ記録をスキップ")
        }
        
        // スナップショット自動保存の開始
        snapshotManager.startAutoSave(gameData: gameData, gameState: gameState, modelContext: modelContext)
    }
    
    /// 単語提出処理
    public func submitWord(_ word: String, showError: @escaping (String) -> Void) {
        let result = gameState.submitWord(word, by: gameState.activePlayer.id)
        
        switch result {
        case .accepted:
            AppLogger.shared.info("単語受理: '\(word)'")
            
        case .eliminated(let reason):
            showError(reason)
            
        case .duplicateWord(let message):
            showError(message)
            
        case .invalidWord(let message):
            showError(message)
            
        case .wrongTurn:
            showError("あなたの番ではありません")
            
        case .gameNotActive:
            showError("ゲームが終了しています")
        }
    }
    
    /// ゲーム終了処理
    public func handleGameEnd(modelContext: ModelContext) {
        AppLogger.shared.info("ゲーム終了処理: 勝者=\(gameState.winner?.name ?? "なし")")
        
        // スナップショット自動保存の停止
        snapshotManager.stopAutoSave()
        
        // 最終スナップショットの作成
        createFinalSnapshot(modelContext: modelContext)
        
        // ゲーム結果データを作成
        let winner = gameState.winner
        let usedWords = gameState.usedWords
        let gameDuration = calculateGameDuration()
        let eliminationHistory = gameState.eliminationHistory
        // 単語→プレイヤー名の正確な割当を作成（可能なら）
        var assignments: [(word: String, playerName: String)] = []
        if !gameState.usedWordRecords.isEmpty {
            let idToName = Dictionary(uniqueKeysWithValues: gameData.participants.map { ($0.id, $0.name) })
            for record in gameState.usedWordRecords {
                let name = idToName[record.playerId] ?? "不明"
                assignments.append((word: record.word, playerName: name))
            }
        }
        
        // GameSessionを作成してSwiftDataに保存
        dataManager.saveGameSession(
            gameData: gameData,
            winner: winner,
            usedWords: usedWords,
            gameDuration: gameDuration,
            modelContext: modelContext,
            usedWordAssignments: assignments.isEmpty ? nil : assignments
        )
        
        // 結果画面への遷移または従来のコールバック実行
        navigateToResults(winner: winner, usedWords: usedWords, gameDuration: gameDuration, eliminationHistory: eliminationHistory)
    }
    
    /// プレイヤー変更時の処理
    public func handlePlayerChange(newPlayerId: String) {
        // 防御的実装: ゲーム終了後は一切の処理をスキップ
        guard gameState.isGameActive else {
            AppLogger.shared.debug("ゲーム終了状態のためプレイヤー変更処理をスキップ: \(newPlayerId)")
            return
        }
        
        // 前回のプレイヤーIDと異なる場合のみアニメーション実行
        guard let previousId = previousPlayerId, previousId != newPlayerId else {
            previousPlayerId = newPlayerId
            return
        }
        
        AppLogger.shared.info("プレイヤー変更検出: \(previousId) -> \(newPlayerId)")
        previousPlayerId = newPlayerId
        
        // 複数人プレイ時のみ遷移アニメーションを表示
        if gameData.participants.count > 1 {
            uiState.setTransitionPhase("shown", for: "mainGame_playerTransition")
        }
    }
    
    // MARK: - Game State Queries
    
    /// ゲームの有効性
    public var isGameActive: Bool {
        gameState.isGameActive
    }
    
    /// 現在のプレイヤー
    public var activePlayer: GameParticipant {
        gameState.activePlayer
    }
    
    /// 残り時間
    public var timeRemaining: Int {
        gameState.timeRemaining
    }
    
    /// 使用された単語
    public var usedWords: [String] {
        gameState.usedWords
    }
    
    /// 最後の単語
    public var lastWord: String? {
        gameState.lastWord
    }
    
    // MARK: - Pause/Resume Methods
    
    /// ゲーム一時停止
    public func pauseGame() {
        gameState.pauseGame()
        uiState.setTransitionPhase("shown", for: "mainGame_pauseMenu")
    }
    
    /// ゲーム再開
    public func resumeGame() {
        uiState.setTransitionPhase("hidden", for: "mainGame_pauseMenu")
        gameState.resumeGame()
    }
    
    /// ゲーム終了（途中終了）
    public func quitGame() {
        gameState.endGame()
        let usedWords = gameState.usedWords
        let gameDuration = calculateGameDuration()
        let eliminationHistory = gameState.eliminationHistory
        
        if let onGameAbandoned = onGameAbandoned {
            // 新しい放棄コールバックが提供されている場合
            onGameAbandoned(usedWords, gameDuration, eliminationHistory)
        } else {
            // 後方互換性：古いコールバックを使用（引き分けとして処理）
            onGameEnd(nil, usedWords, gameDuration, eliminationHistory)
        }
    }
    
    /// タイトルに戻る
    public func quitToTitle() {
        guard let callback = onQuitToTitle else { return }
        
        AppLogger.shared.info("タイトルに戻る：ゲーム状態をクリーンアップ")
        gameState.endGame()
        snapshotManager.stopAutoSave()
        callback()
    }
    
    /// 設定画面に移動
    public func quitToSettings(modelContext: ModelContext) {
        guard let callback = onQuitToSettings else { return }
        
        AppLogger.shared.info("設定画面に移動：ゲーム状態を保持")
        gameState.pauseGame()
        
        // 設定移行前にスナップショットを作成
        createSettingsTransitionSnapshot(modelContext: modelContext)
        callback()
    }
    
    // MARK: - Background Handling
    
    /// バックグラウンド移行時の処理
    public func handleBackgroundTransition(modelContext: ModelContext) {
        guard gameState.isGameActive else { return }
        
        AppLogger.shared.info("バックグラウンド移行：ゲーム状態を保存")
        
        // ゲームを一時停止
        gameState.pauseGame()
        
        // バックグラウンド移行前のスナップショット作成
        createBackgroundSnapshot(modelContext: modelContext)
    }
    
    // MARK: - Private Helper Methods
    
    /// ゲーム継続時間計算
    private func calculateGameDuration() -> Int {
        guard let startTime = gameStartTime else {
            AppLogger.shared.warning("ゲーム開始時刻が記録されていません - フォールバック計算を使用")
            return gameState.usedWords.count * 10 // フォールバック: 1単語あたり10秒と仮定
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        let durationInSeconds = Int(duration)
        
        AppLogger.shared.info("ゲーム実際の経過時間: \(String(format: "%.2f", duration))秒 (\(durationInSeconds)秒)")
        AppLogger.shared.debug("開始時刻: \(startTime), 終了時刻: \(endTime)")
        
        return durationInSeconds
    }
    
    /// 平均単語時間計算
    private func calculateAverageWordTime() -> Double {
        guard gameState.usedWords.count > 0 else { return 0.0 }
        return Double(calculateGameDuration()) / Double(gameState.usedWords.count)
    }
    
    /// ランキング生成
    private func generateRankings(winner: GameParticipant?, eliminationHistory: [(playerId: String, reason: String, order: Int)]) -> [PlayerRanking] {
        var rankings: [PlayerRanking] = []
        
        for (index, participant) in gameData.participants.enumerated() {
            // 各プレイヤーの貢献単語数を計算（簡易版）
            let wordsCount = max(1, gameState.usedWords.count / gameData.participants.count)
            
            // 脱落情報を検索
            let eliminationInfo = eliminationHistory.first { $0.playerId == participant.id }
            let eliminationOrder = eliminationInfo?.order
            let eliminationReason = eliminationInfo?.reason
            
            // 勝者判定
            let isWinner = winner?.id == participant.id
            
            // ランク計算：勝者が1位、脱落順によって順位を決定
            let rank: Int
            if isWinner {
                rank = 1
            } else if let elimOrder = eliminationOrder {
                // 脱落順に基づいて順位決定（最後に脱落した人が最高順位）
                rank = gameData.participants.count - elimOrder + 1
            } else {
                // 脱落していない場合（引き分けなど）
                rank = index + 1
            }
            
            let ranking = PlayerRanking(
                participant: participant,
                wordsContributed: wordsCount,
                rank: rank,
                eliminationOrder: eliminationOrder,
                eliminationReason: eliminationReason,
                isWinner: isWinner
            )
            
            rankings.append(ranking)
        }
        
        // ランクでソート（1位が最初）
        return rankings.sorted { $0.rank < $1.rank }
    }
    
    /// 結果画面への遷移処理
    private func navigateToResults(winner: GameParticipant?, usedWords: [String], gameDuration: Int, eliminationHistory: [(playerId: String, reason: String, order: Int)]) {
        // 重複処理の解消: onNavigateToResultsを優先し、提供されていない場合のみonGameEndを使用
        if let navigateToResults = onNavigateToResults {
            // 新しいナビゲーション方式: GameResultsDataを使用
            let gameStats = GameStats(
                totalWords: usedWords.count,
                gameDuration: gameDuration,
                averageWordTime: calculateAverageWordTime(),
                longestWord: usedWords.max(by: { $0.count < $1.count }),
                uniqueStartingCharacters: Set(usedWords.compactMap { $0.first }).count
            )
            
            let rankings = generateRankings(winner: winner, eliminationHistory: eliminationHistory)
            
            let resultsData = GameResultsData(
                winner: winner,
                rankings: rankings,
                gameStats: gameStats,
                usedWords: usedWords,
                gameData: gameData
            )
            
            AppLogger.shared.debug("ナビゲーション遷移: 結果画面へ（onNavigateToResults使用）")
            navigateToResults(resultsData)
        } else {
            // レガシー方式: 後方互換性のためのフォールバック
            AppLogger.shared.debug("レガシーコールバック実行: onGameEnd使用（onNavigateToResultsが未提供）")
            onGameEnd(winner, usedWords, gameDuration, eliminationHistory)
        }
    }
    
    // MARK: - Snapshot Creation Methods
    
    /// 最終スナップショット作成
    private func createFinalSnapshot(modelContext: ModelContext) {
        do {
            _ = try snapshotManager.createSnapshot(
                gameData: gameData,
                gameState: gameState,
                type: .beforeTermination,
                modelContext: modelContext
            )
        } catch {
            AppLogger.shared.warning("最終スナップショット作成失敗: \(error.localizedDescription)")
        }
    }
    
    /// 設定移行前スナップショット作成
    private func createSettingsTransitionSnapshot(modelContext: ModelContext) {
        do {
            _ = try snapshotManager.createSnapshot(
                gameData: gameData,
                gameState: gameState,
                type: .userRequested,
                modelContext: modelContext
            )
        } catch {
            AppLogger.shared.warning("設定移行前スナップショット作成失敗: \(error.localizedDescription)")
        }
    }
    
    /// バックグラウンド移行前スナップショット作成
    private func createBackgroundSnapshot(modelContext: ModelContext) {
        do {
            _ = try snapshotManager.createBackgroundSnapshot(
                gameData: gameData,
                gameState: gameState,
                modelContext: modelContext
            )
            AppLogger.shared.info("バックグラウンド移行前スナップショット作成成功")
        } catch {
            AppLogger.shared.error("バックグラウンド移行前スナップショット作成失敗: \(error.localizedDescription)")
        }
    }
}
