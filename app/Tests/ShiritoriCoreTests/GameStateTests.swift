import Testing
import Foundation
@testable import ShiritoriCore

/// GameStateクラスの単体テストクラス
@Suite("GameState Tests")
struct GameStateTests {
    
    // MARK: - Helper Methods
    
    /// テスト用のGameSetupDataを作成
    private func createTestGameData(participants: [GameParticipant]? = nil) -> GameSetupData {
        let defaultParticipants = participants ?? [
            GameParticipant(id: "player1", name: "テストプレイヤー1", type: .human),
            GameParticipant(id: "player2", name: "テストプレイヤー2", type: .human)
        ]
        let turnOrder = defaultParticipants.map { $0.id }
        return GameSetupData(
            participants: defaultParticipants,
            rules: GameRulesConfig(
                timeLimit: 30,
                maxPlayers: 4,
                winCondition: .lastPlayerStanding
            ),
            turnOrder: turnOrder
        )
    }
    
    /// GameStateを初期化してゲームを開始
    private func createActiveGameState(participants: [GameParticipant]? = nil) -> GameState {
        let gameData = createTestGameData(participants: participants)
        let gameState = GameState(gameData: gameData)
        gameState.startGame()
        return gameState
    }
    
    // MARK: - Basic Functionality Tests
    
    @Test("GameState初期化テスト")
    func testGameStateInitialization() throws {
        let gameData = createTestGameData()
        let gameState = GameState(gameData: gameData)
        
        #expect(gameState.isGameActive == true)
        #expect(gameState.currentTurnIndex == 0)
        #expect(gameState.usedWords.isEmpty)
        #expect(gameState.eliminatedPlayers.isEmpty)
        #expect(gameState.winner == nil)
    }
    
    @Test("現在のプレイヤー取得テスト")
    func testCurrentParticipant() throws {
        let gameState = createActiveGameState()
        
        guard let currentPlayer = gameState.currentParticipant else {
            throw TestError.unexpectedNil("currentParticipant should not be nil")
        }
        
        #expect(currentPlayer.id == "player1")
        #expect(gameState.currentTurnIndex == 0)
    }
    
    // MARK: - Word Submission Tests
    
    @Test("正常な単語提出テスト")
    func testValidWordSubmission() throws {
        let gameState = createActiveGameState()
        
        let result = gameState.submitWord("あいす", by: "player1")
        
        switch result {
        case .accepted:
            #expect(gameState.usedWords.count == 1)
            #expect(gameState.usedWords.first == "あいす")
            #expect(gameState.currentTurnIndex == 1)
        default:
            throw TestError.unexpectedResult("Expected .accepted, got \(result)")
        }
    }
    
    // MARK: - Critical Bug Fix Tests (「ん」終了時の競合状態)
    
    @Test("「ん」で終わる単語提出でゲーム終了時にターン切り替えが実行されない")
    func testGameEndWithNCharacterDoesNotTriggerTurnChange() throws {
        AppLogger.shared.info("🧪 テスト開始: 「ん」終了時の競合状態テスト")
        
        // 2人プレイヤーのゲーム状態を作成
        let participants = [
            GameParticipant(id: "player1", name: "プレイヤー1", type: .human),
            GameParticipant(id: "player2", name: "プレイヤー2", type: .human)
        ]
        let gameState = createActiveGameState(participants: participants)
        
        // 初期状態の詳細確認
        let initialTurnIndex = gameState.currentTurnIndex
        let initialActiveState = gameState.isGameActive
        let initialCurrentPlayer = gameState.currentParticipant
        let initialEliminatedCount = gameState.eliminatedPlayers.count
        
        AppLogger.shared.info("📊 初期状態詳細:")
        AppLogger.shared.info("  - turnIndex: \(initialTurnIndex)")
        AppLogger.shared.info("  - isActive: \(initialActiveState)")
        AppLogger.shared.info("  - currentPlayer: \(initialCurrentPlayer?.name ?? "nil")")
        AppLogger.shared.info("  - eliminatedCount: \(initialEliminatedCount)")
        
        #expect(initialActiveState == true)
        #expect(initialTurnIndex == 0)
        #expect(gameState.winner == nil)
        #expect(initialEliminatedCount == 0)
        
        // 正常な単語を1つ提出してしりとりを開始
        AppLogger.shared.info("🔤 最初の単語 'あいす' を player1 が提出")
        let firstWordResult = gameState.submitWord("あいす", by: "player1")
        switch firstWordResult {
        case .accepted:
            AppLogger.shared.info("✅ 最初の単語 'あいす' が正常に受理されました")
        default:
            throw TestError.unexpectedResult("First word should be accepted, got \(firstWordResult)")
        }
        
        let afterFirstWordTurnIndex = gameState.currentTurnIndex
        let afterFirstWordCurrentPlayer = gameState.currentParticipant
        AppLogger.shared.info("📊 最初の単語後の状態:")
        AppLogger.shared.info("  - turnIndex: \(afterFirstWordTurnIndex)")
        AppLogger.shared.info("  - currentPlayer: \(afterFirstWordCurrentPlayer?.name ?? "nil")")
        AppLogger.shared.info("  - usedWords: \(gameState.usedWords)")
        
        #expect(afterFirstWordTurnIndex == 1)
        #expect(gameState.isGameActive == true)
        #expect(afterFirstWordCurrentPlayer?.id == "player2")
        
        // 重要: 「ん」で終わる単語を提出してゲーム終了を誘発
        AppLogger.shared.info("💥 重要テスト: 「ん」で終わる単語 'すいぞくかん' を player2 が提出")
        AppLogger.shared.info("期待される動作: player2 が脱落し、player1 が勝者となってゲーム終了")
        
        // submitWord呼び出し前の状態を記録
        let beforeSubmitTurnIndex = gameState.currentTurnIndex
        let beforeSubmitActiveState = gameState.isGameActive
        
        let nWordResult = gameState.submitWord("すいぞくかん", by: "player2")
        
        // submitWord呼び出し後の即座の状態を記録
        let afterSubmitTurnIndex = gameState.currentTurnIndex
        let afterSubmitActiveState = gameState.isGameActive
        let afterSubmitWinner = gameState.winner
        let afterSubmitEliminatedCount = gameState.eliminatedPlayers.count
        
        AppLogger.shared.info("📊 'すいぞくかん' 提出直後の状態:")
        AppLogger.shared.info("  - submitWord result: \(nWordResult)")
        AppLogger.shared.info("  - turnIndex: \(beforeSubmitTurnIndex) → \(afterSubmitTurnIndex)")
        AppLogger.shared.info("  - isActive: \(beforeSubmitActiveState) → \(afterSubmitActiveState)")
        AppLogger.shared.info("  - winner: \(afterSubmitWinner?.name ?? "なし")")
        AppLogger.shared.info("  - eliminatedCount: \(afterSubmitEliminatedCount)")
        AppLogger.shared.info("  - eliminatedPlayers: \(gameState.eliminatedPlayers)")
        
        // 結果の詳細確認
        switch nWordResult {
        case .eliminated(let reason):
            AppLogger.shared.info("✅ 期待通りの脱落結果: \(reason)")
            
            // 🔥 重要なテスト: ゲーム終了時の状態確認
            #expect(afterSubmitActiveState == false, "ゲームは終了状態でなければならない")
            #expect(afterSubmitWinner != nil, "勝者が決定されていなければならない")
            #expect(afterSubmitWinner?.id == "player1", "プレイヤー1が勝者でなければならない")
            #expect(afterSubmitEliminatedCount == 1, "1人が脱落していなければならない")
            #expect(gameState.eliminatedPlayers.contains("player2"), "player2が脱落していなければならない")
            
            // 🚨 バグ検出テスト: ゲーム終了時にターンインデックスが変更されているかチェック
            if afterSubmitTurnIndex != afterFirstWordTurnIndex {
                AppLogger.shared.error("🔥 バグ検出: ゲーム終了時にターンインデックスが \(afterFirstWordTurnIndex) から \(afterSubmitTurnIndex) に変更されました")
                AppLogger.shared.error("これは eliminateCurrentPlayer 内で moveToNextTurn() が不適切に呼ばれたことを示します")
                
                // 実際にはこれがバグの症状を示している
                throw TestError.unexpectedResult("ゲーム終了時にターンインデックスが変更されました。これは修正が必要な不具合です。")
            } else {
                AppLogger.shared.info("✅ 正常: ゲーム終了時にターンインデックスは変更されませんでした")
            }
            
        default:
            throw TestError.unexpectedResult("Expected .eliminated for word ending with 'ん', got \(nWordResult)")
        }
        
        AppLogger.shared.info("🎯 テスト完了: 「ん」終了時の競合状態テスト")
    }
    
    @Test("脱落処理後のゲーム終了判定テスト")
    func testEliminateCurrentPlayerTriggersCorrectGameEnd() throws {
        AppLogger.shared.info("🧪 テスト開始: 脱落処理とゲーム終了判定")
        
        let participants = [
            GameParticipant(id: "survivor", name: "最後の生存者", type: .human),
            GameParticipant(id: "eliminated", name: "脱落予定者", type: .human)
        ]
        let gameState = createActiveGameState(participants: participants)
        
        // まず正常な単語で1回目のターン
        let firstResult = gameState.submitWord("りんご", by: "survivor")
        switch firstResult {
        case .accepted:
            break
        default:
            throw TestError.unexpectedResult("Expected .accepted, got \(firstResult)")
        }
        
        let beforeEliminationTurnIndex = gameState.currentTurnIndex
        AppLogger.shared.debug("脱落前のターンインデックス: \(beforeEliminationTurnIndex)")
        
        // 「ん」で終わる単語で脱落させる
        let eliminationResult = gameState.submitWord("ごりらじん", by: "eliminated")
        
        switch eliminationResult {
        case .eliminated:
            // ゲーム終了後の状態確認
            #expect(gameState.isGameActive == false, "ゲームは終了状態でなければならない")
            #expect(gameState.winner?.id == "survivor", "正しい勝者が決定されていなければならない")
            #expect(gameState.eliminatedPlayers.contains("eliminated"), "脱落者が正しく記録されていなければならない")
            
            let afterEliminationTurnIndex = gameState.currentTurnIndex
            AppLogger.shared.debug("脱落後のターンインデックス: \(afterEliminationTurnIndex)")
            
            // 重要: ゲーム終了時はターンが進まない
            #expect(afterEliminationTurnIndex == beforeEliminationTurnIndex, "ゲーム終了時にターンは進まない")
            
        default:
            throw TestError.unexpectedResult("Expected elimination, got \(eliminationResult)")
        }
        
        AppLogger.shared.info("✅ テスト完了: 脱落処理とゲーム終了判定")
    }
    
    @Test("ゲーム終了後の操作無効化テスト")
    func testGameNotActiveAfterEnd() throws {
        let gameState = createActiveGameState()
        
        // ゲームを意図的に終了
        gameState.endGame()
        
        #expect(gameState.isGameActive == false)
        
        // 終了後の単語提出は無効になること
        let result = gameState.submitWord("テスト", by: "player1")
        switch result {
        case .gameNotActive:
            break // 期待される結果
        default:
            throw TestError.unexpectedResult("Expected .gameNotActive, got \(result)")
        }
    }
}

// MARK: - Test Error Types

enum TestError: Error {
    case unexpectedNil(String)
    case unexpectedResult(String)
}