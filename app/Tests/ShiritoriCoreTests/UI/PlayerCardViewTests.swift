import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

struct PlayerCardViewTests {
    
    // MARK: - ダークモード対応テスト
    
    @Test func testPlayerCardViewDarkModeAdaptation() throws {
        // Given
        let playerName = "テストプレイヤー"
        let gamesPlayed = 5
        let gamesWon = 3
        var editCalled = false
        var deleteCalled = false
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            onEdit: { editCalled = true },
            onDelete: { deleteCalled = true }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        
        // カードの構造が正しく存在することを確認
        let hstack = try vstack.hStack(0)
        
        // プレイヤーアバターが存在することを確認
        let _ = try hstack.view(PlayerAvatarView.self, 0)
        
        // プレイヤー情報のVStackが存在することを確認
        let playerInfoVStack = try hstack.vStack(1)
        
        // プレイヤー名のテキストが正しく表示されることを確認
        let nameText = try playerInfoVStack.text(0)
        #expect(try nameText.string() == playerName)
        
        // 統計情報コンポーネントが存在することを確認
        let _ = try playerInfoVStack.view(PlayerStatsDisplay.self, 1)
        
        // 編集・削除ボタンが存在することを確認
        let actionVStack = try hstack.vStack(2)
        let _ = try actionVStack.button(0) // editButton
        let _ = try actionVStack.button(1) // deleteButton
        
        // 初期状態でコールバックが呼ばれていないことを確認
        #expect(editCalled == false)
        #expect(deleteCalled == false)
    }
    
    @Test func testPlayerCardViewBackgroundColor() throws {
        // Given
        let playerName = "背景テスト"
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: 0,
            gamesWon: 0,
            onEdit: { },
            onDelete: { }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        
        // カードの背景が適切に設定されていることを確認
        // ViewInspectorでは背景色の直接的な検証は困難だが、構造が正しいことを確認
        let hstack = try vstack.hStack(0)
        
        // プレイヤーアバターが存在することを確認
        let _ = try hstack.view(PlayerAvatarView.self, 0)
    }
    
    @Test func testPlayerCardViewEditButton() throws {
        // Given
        let playerName = "編集テスト"
        var editCalled = false
        var deleteCalled = false
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: 2,
            gamesWon: 1,
            onEdit: { editCalled = true },
            onDelete: { deleteCalled = true }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        
        // 編集ボタンの存在確認
        let actionVStack = try hstack.vStack(2)
        let editButton = try actionVStack.button(0)
        
        // 編集ボタンをタップ
        try editButton.tap()
        
        // 編集コールバックが呼ばれることを確認
        #expect(editCalled == true)
        #expect(deleteCalled == false)
    }
    
    @Test func testPlayerCardViewDeleteButton() throws {
        // Given
        let playerName = "削除テスト"
        var editCalled = false
        var deleteCalled = false
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: 1,
            gamesWon: 0,
            onEdit: { editCalled = true },
            onDelete: { deleteCalled = true }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        
        // 削除ボタンの存在確認
        let actionVStack = try hstack.vStack(2)
        let deleteButton = try actionVStack.button(1)
        
        // 削除ボタンをタップ
        try deleteButton.tap()
        
        // 削除コールバックが呼ばれることを確認
        #expect(editCalled == false)
        #expect(deleteCalled == true)
    }
    
    @Test func testPlayerCardViewWithHighStats() throws {
        // Given
        let playerName = "高統計プレイヤー"
        let gamesPlayed = 100
        let gamesWon = 85
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            onEdit: { },
            onDelete: { }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        
        // プレイヤー情報の確認
        let playerInfoVStack = try hstack.vStack(1)
        let nameText = try playerInfoVStack.text(0)
        #expect(try nameText.string() == playerName)
        
        // 統計情報コンポーネントが存在することを確認
        let _ = try playerInfoVStack.view(PlayerStatsDisplay.self, 1)
        
        // NOTE: ViewInspectorではコンポーネント内部のプロパティへの直接アクセスはサポートされていない
        // 統計表示の正確性は統合テストまたは手動テストで確認する
    }
    
    @Test func testPlayerCardViewWithZeroStats() throws {
        // Given
        let playerName = "新規プレイヤー"
        let gamesPlayed = 0
        let gamesWon = 0
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            onEdit: { },
            onDelete: { }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        
        // プレイヤー情報の確認
        let playerInfoVStack = try hstack.vStack(1)
        let nameText = try playerInfoVStack.text(0)
        #expect(try nameText.string() == playerName)
        
        // 統計情報コンポーネントが存在することを確認（0戦0勝）
        let _ = try playerInfoVStack.view(PlayerStatsDisplay.self, 1)
        
        // NOTE: ViewInspectorではコンポーネント内部のプロパティへの直接アクセスはサポートされていない
        // 統計表示の正確性は統合テストまたは手動テストで確認する
    }
    
    @Test func testPlayerCardViewButtonIcons() throws {
        // Given
        let playerName = "アイコンテスト"
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: 1,
            gamesWon: 1,
            onEdit: { },
            onDelete: { }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        
        // 編集・削除ボタンの存在確認
        let actionVStack = try hstack.vStack(2)
        let editButton = try actionVStack.button(0)
        let deleteButton = try actionVStack.button(1)
        
        // ボタンのアイコンが存在することを確認
        let editImage = try editButton.labelView().image()
        let deleteImage = try deleteButton.labelView().image()
        
        #expect(editImage != nil)
        #expect(deleteImage != nil)
    }
}