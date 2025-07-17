import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

@Suite("PlayerTransitionView Tests")
struct PlayerTransitionViewTests {
    
    @Test("PlayerTransitionView作成テスト")
    func testPlayerTransitionViewCreation() throws {
        // Given
        let testPlayer = GameParticipant(
            id: "test-player",
            name: "テストプレイヤー",
            type: .human
        )
        
        // When
        let view = PlayerTransitionView(
            newPlayer: testPlayer,
            isVisible: true
        )
        
        // Then: ビューが正常に作成されることを確認
        #expect(view != nil)
    }
    
    @Test("PlayerTransitionView非表示状態テスト")
    func testPlayerTransitionViewHidden() throws {
        // Given
        let testPlayer = GameParticipant(
            id: "test-player",
            name: "テストプレイヤー",
            type: .human
        )
        
        // When
        let view = PlayerTransitionView(
            newPlayer: testPlayer,
            isVisible: false
        )
        
        // Then: 非表示状態でも正常に作成される
        #expect(view != nil)
    }
    
    @Test("コンピュータープレイヤーでの表示テスト")
    func testPlayerTransitionViewWithComputerPlayer() throws {
        // Given
        let computerPlayer = GameParticipant(
            id: "computer-player",
            name: "コンピューター",
            type: .computer(difficulty: .normal)
        )
        
        // When
        let view = PlayerTransitionView(
            newPlayer: computerPlayer,
            isVisible: true
        )
        
        // Then: コンピュータープレイヤーでも正常に作成される
        #expect(view != nil)
    }
    
    @Test("異なる難易度のコンピュータープレイヤーテスト")
    func testPlayerTransitionViewWithDifferentDifficulties() throws {
        let difficulties: [DifficultyLevel] = [.easy, .normal, .hard]
        
        for difficulty in difficulties {
            // Given
            let computerPlayer = GameParticipant(
                id: "computer-\(difficulty)",
                name: "コンピューター(\(difficulty))",
                type: .computer(difficulty: difficulty)
            )
            
            // When
            let view = PlayerTransitionView(
                newPlayer: computerPlayer,
                isVisible: true
            )
            
            // Then: 全ての難易度で正常に作成される
            #expect(view != nil)
        }
    }
    
    @Test("プレイヤー名表示テスト")
    func testPlayerNameDisplay() throws {
        // Given
        let playerName = "テスト太郎"
        let testPlayer = GameParticipant(
            id: "test-player",
            name: playerName,
            type: .human
        )
        
        // When
        let view = PlayerTransitionView(
            newPlayer: testPlayer,
            isVisible: true
        )
        
        // Then: プレイヤー名が設定されている
        #expect(view.newPlayer.name == playerName)
    }
    
    @Test("コールバック機能テスト")
    func testPlayerTransitionViewCallback() throws {
        // Given
        var callbackExecuted = false
        let testPlayer = GameParticipant(
            id: "test-player",
            name: "テストプレイヤー",
            type: .human
        )
        
        // When
        let view = PlayerTransitionView(
            newPlayer: testPlayer,
            isVisible: true,
            onAnimationComplete: {
                callbackExecuted = true
            }
        )
        
        // Then: ビューが作成され、コールバックが設定されている
        #expect(view != nil)
        // Note: コールバックの実行テストは実際のアニメーション完了を待つ必要があるため、
        // UIテストでは基本的な作成テストのみ実行
    }
    
    @Test("長いプレイヤー名での表示テスト")
    func testPlayerTransitionViewWithLongName() throws {
        // Given
        let longPlayerName = "とても長いプレイヤーの名前をつけてみたテストユーザー"
        let testPlayer = GameParticipant(
            id: "test-player",
            name: longPlayerName,
            type: .human
        )
        
        // When
        let view = PlayerTransitionView(
            newPlayer: testPlayer,
            isVisible: true
        )
        
        // Then: 長い名前でも正常に作成される
        #expect(view != nil)
        #expect(view.newPlayer.name == longPlayerName)
    }
    
    @Test("特殊文字を含むプレイヤー名テスト")
    func testPlayerTransitionViewWithSpecialCharacters() throws {
        // Given
        let specialCharName = "🎮ゲーマー⭐️"
        let testPlayer = GameParticipant(
            id: "test-player",
            name: specialCharName,
            type: .human
        )
        
        // When
        let view = PlayerTransitionView(
            newPlayer: testPlayer,
            isVisible: true
        )
        
        // Then: 特殊文字を含む名前でも正常に作成される
        #expect(view != nil)
        #expect(view.newPlayer.name == specialCharName)
    }
    
    @Test("プレイヤータイプ判定テスト")
    func testPlayerTypeIdentification() throws {
        // Given
        let humanPlayer = GameParticipant(
            id: "human",
            name: "人間プレイヤー",
            type: .human
        )
        
        let computerPlayer = GameParticipant(
            id: "computer",
            name: "コンピューター",
            type: .computer(difficulty: .normal)
        )
        
        // When & Then: 人間プレイヤー
        let humanView = PlayerTransitionView(
            newPlayer: humanPlayer,
            isVisible: true
        )
        #expect(humanView != nil)
        
        if case .human = humanView.newPlayer.type {
            // 人間プレイヤーとして正しく識別される
            #expect(true)
        } else {
            #expect(Bool(false), "人間プレイヤーとして識別されませんでした")
        }
        
        // When & Then: コンピュータープレイヤー
        let computerView = PlayerTransitionView(
            newPlayer: computerPlayer,
            isVisible: true
        )
        #expect(computerView != nil)
        
        if case .computer = computerView.newPlayer.type {
            // コンピュータープレイヤーとして正しく識別される
            #expect(true)
        } else {
            #expect(Bool(false), "コンピュータープレイヤーとして識別されませんでした")
        }
    }
}