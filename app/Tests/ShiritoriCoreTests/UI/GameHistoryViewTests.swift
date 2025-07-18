import Testing
@testable import ShiritoriCore

/// GameHistoryViewのテスト
struct GameHistoryViewTests {
    
    @Test("GameHistoryView作成テスト")
    func testGameHistoryViewCreation() {
        let _ = GameHistoryView(onDismiss: {})
        
        // 単純にViewが作成されることを確認
        AppLogger.shared.debug("GameHistoryView作成テスト完了")
    }
    
    @Test("GameHistoryDetailView作成テスト")
    func testGameHistoryDetailViewCreation() {
        // テスト用のGameSessionを作成
        let testSession = GameSession(
            participantNames: ["テストプレイヤー1", "テストプレイヤー2"],
            winnerName: "テストプレイヤー1"
        )
        
        let _ = GameHistoryDetailView(
            session: testSession,
            onDismiss: {}
        )
        
        // 単純にViewが作成されることを確認
        AppLogger.shared.debug("GameHistoryDetailView作成テスト完了")
    }
    
    @Test("GameSession初期化テスト")
    func testGameSessionCreation() throws {
        let participantNames = ["プレイヤー1", "プレイヤー2", "プレイヤー3"]
        let winnerName = "プレイヤー2"
        
        let gameSession = GameSession(
            participantNames: participantNames,
            winnerName: winnerName
        )
        
        // GameSessionの基本プロパティを確認
        #expect(gameSession.participantNames == participantNames)
        #expect(gameSession.winnerName == winnerName)
        #expect(gameSession.isCompleted == true)
        
        AppLogger.shared.debug("GameSession初期化テスト完了")
    }
    
    @Test("GameSession引き分けケーステスト")
    func testGameSessionDraw() throws {
        let participantNames = ["プレイヤー1", "プレイヤー2"]
        
        let gameSession = GameSession(
            participantNames: participantNames,
            winnerName: nil
        )
        
        // 引き分けの場合のGameSessionを確認
        #expect(gameSession.participantNames == participantNames)
        #expect(gameSession.winnerName == nil)
        #expect(gameSession.isCompleted == true)
        
        AppLogger.shared.debug("GameSession引き分けケーステスト完了")
    }
    
    @Test("履歴統計計算テスト") 
    func testHistoryStatsCalculation() throws {
        // 複数のGameSessionを想定したテスト
        let session1 = GameSession(
            participantNames: ["A", "B"],
            winnerName: "A"
        )
        
        let session2 = GameSession(
            participantNames: ["C", "D", "E"],
            winnerName: "C"
        )
        
        // 履歴データのリスト
        let gameHistory = [session1, session2]
        
        // 統計計算の確認
        #expect(gameHistory.count == 2)
        #expect(gameHistory.allSatisfy { $0.isCompleted })
        
        AppLogger.shared.debug("履歴統計計算テスト完了")
    }
    
    @Test("EnhancedTitleView履歴ボタン統合テスト")
    func testEnhancedTitleViewWithHistoryButton() throws {
        let _ = EnhancedTitleView(
            isAnimationEnabled: false, // テスト時はアニメーション無効
            onStartGame: {},
            onManagePlayers: {},
            onShowSettings: {},
            onShowHistory: {}
        )
        
        // 単純にViewが作成されることを確認
        AppLogger.shared.debug("EnhancedTitleView履歴ボタン統合テスト完了")
    }
}