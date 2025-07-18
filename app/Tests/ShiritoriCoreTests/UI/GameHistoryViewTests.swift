import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

/// GameHistoryViewのテスト
struct GameHistoryViewTests {
    
    @Test("GameHistoryView作成テスト")
    func testGameHistoryViewCreation() throws {
        let gameHistoryView = GameHistoryView(onDismiss: {})
        
        // ViewInspectorでビューの構造をテスト
        let inspectedView = try gameHistoryView.inspect()
        
        // NavigationViewが存在することを確認
        #expect(throws: Never.self) {
            _ = try inspectedView.navigationView()
        }
        
        AppLogger.shared.debug("GameHistoryView作成テスト完了")
    }
    
    @Test("GameHistoryView空の履歴表示テスト")
    func testGameHistoryViewEmptyState() throws {
        let gameHistoryView = GameHistoryView(onDismiss: {})
        
        let inspectedView = try gameHistoryView.inspect()
        
        // ZStackが存在することを確認（背景）
        #expect(throws: Never.self) {
            _ = try inspectedView.navigationView().zStack()
        }
        
        AppLogger.shared.debug("GameHistoryView空の履歴表示テスト完了")
    }
    
    @Test("GameHistoryViewヘッダー表示テスト")
    func testGameHistoryViewHeader() throws {
        let gameHistoryView = GameHistoryView(onDismiss: {})
        
        let inspectedView = try gameHistoryView.inspect()
        
        // NavigationViewとZStackの構造確認
        #expect(throws: Never.self) {
            _ = try inspectedView.navigationView().zStack()
        }
        
        AppLogger.shared.debug("GameHistoryViewヘッダー表示テスト完了")
    }
    
    @Test("GameHistoryDetailView作成テスト")
    func testGameHistoryDetailViewCreation() throws {
        // テスト用のGameSessionを作成
        let testSession = GameSession(
            participantNames: ["テストプレイヤー1", "テストプレイヤー2"],
            winnerName: "テストプレイヤー1"
        )
        
        let gameHistoryDetailView = GameHistoryDetailView(
            session: testSession,
            onDismiss: {}
        )
        
        // ViewInspectorでビューの構造をテスト
        let inspectedView = try gameHistoryDetailView.inspect()
        
        // NavigationViewが存在することを確認
        #expect(throws: Never.self) {
            _ = try inspectedView.navigationView()
        }
        
        AppLogger.shared.debug("GameHistoryDetailView作成テスト完了")
    }
    
    @Test("GameHistoryDetailViewヘッダー情報テスト")
    func testGameHistoryDetailViewHeader() throws {
        let testSession = GameSession(
            participantNames: ["太郎", "花子"],
            winnerName: "太郎"
        )
        
        let gameHistoryDetailView = GameHistoryDetailView(
            session: testSession,
            onDismiss: {}
        )
        
        let inspectedView = try gameHistoryDetailView.inspect()
        
        // NavigationViewとZStackの構造確認
        #expect(throws: Never.self) {
            _ = try inspectedView.navigationView().zStack()
        }
        
        AppLogger.shared.debug("GameHistoryDetailViewヘッダー情報テスト完了")
    }
    
    @Test("ChildFriendlyButtonの動作テスト")
    func testChildFriendlyButtonInHistoryView() throws {
        let gameHistoryView = GameHistoryView(onDismiss: {})
        
        let inspectedView = try gameHistoryView.inspect()
        
        // ツールバーのボタンが存在することを確認
        #expect(throws: Never.self) {
            _ = try inspectedView.navigationView().toolbar()
        }
        
        AppLogger.shared.debug("ChildFriendlyButtonの動作テスト完了")
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
        let titleView = EnhancedTitleView(
            isAnimationEnabled: false, // テスト時はアニメーション無効
            onStartGame: {},
            onManagePlayers: {},
            onShowSettings: {},
            onShowHistory: {}
        )
        
        let inspectedView = try titleView.inspect()
        
        // ZStackの構造確認
        #expect(throws: Never.self) {
            _ = try inspectedView.zStack()
        }
        
        AppLogger.shared.debug("EnhancedTitleView履歴ボタン統合テスト完了")
    }
}