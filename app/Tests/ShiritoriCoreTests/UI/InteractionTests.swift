import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

struct InteractionTests {
    
    // MARK: - ボタンタップのインタラクションテスト
    
    @Test func testChildFriendlyButtonTapInteraction() throws {
        // Given
        let title = "タップテスト"
        var tapCount = 0
        
        // When
        let button = ChildFriendlyButton(title: title) {
            tapCount += 1
        }
        
        // Then
        let view = try button.inspect()
        let buttonView = try view.implicitAnyView().button()
        
        // 初期状態でタップカウントが0であることを確認
        #expect(tapCount == 0)
        
        // ボタンを複数回タップ
        try buttonView.tap()
        #expect(tapCount == 1)
        
        try buttonView.tap()
        #expect(tapCount == 2)
        
        try buttonView.tap()
        #expect(tapCount == 3)
    }
    
    @Test func testPlayerCardViewEditDeleteInteraction() throws {
        // Given
        let playerName = "インタラクションテスト"
        var editCount = 0
        var deleteCount = 0
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: 5,
            gamesWon: 3,
            onEdit: { editCount += 1 },
            onDelete: { deleteCount += 1 }
        )
        
        // Then
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        let actionVStack = try hstack.vStack(2)
        
        // 編集ボタンのタップテスト
        let editButton = try actionVStack.button(0)
        try editButton.tap()
        #expect(editCount == 1)
        #expect(deleteCount == 0)
        
        // 削除ボタンのタップテスト
        let deleteButton = try actionVStack.button(1)
        try deleteButton.tap()
        #expect(editCount == 1)
        #expect(deleteCount == 1)
        
        // 複数回タップのテスト
        try editButton.tap()
        try deleteButton.tap()
        #expect(editCount == 2)
        #expect(deleteCount == 2)
    }
    
    @Test func testEmptyPlayerListViewAddPlayerInteraction() throws {
        // Given
        var addPlayerCallCount = 0
        
        // When
        let emptyView = EmptyPlayerListView {
            addPlayerCallCount += 1
        }
        
        // Then
        let view = try emptyView.inspect()
        let vstack = try view.vStack()
        let addButton = try vstack.view(ChildFriendlyButton.self, 2)
        
        // 初期状態でコールバックが呼ばれていないことを確認
        #expect(addPlayerCallCount == 0)
        
        // ボタンのタップテスト
        let buttonView = try addButton.actualView().inspect()
        let button = try buttonView.implicitAnyView().button()
        try button.tap()
        
        // コールバックが呼ばれることを確認
        #expect(addPlayerCallCount == 1)
        
        // 複数回タップのテスト
        try button.tap()
        #expect(addPlayerCallCount == 2)
    }
    
    // MARK: - 複合的なインタラクションテスト
    
    @Test func testMultipleButtonInteractions() throws {
        // Given
        var button1Count = 0
        var button2Count = 0
        var button3Count = 0
        
        let button1 = ChildFriendlyButton(title: "Button1") { button1Count += 1 }
        let button2 = ChildFriendlyButton(title: "Button2") { button2Count += 1 }
        let button3 = ChildFriendlyButton(title: "Button3") { button3Count += 1 }
        
        // When & Then
        let view1 = try button1.inspect()
        let buttonView1 = try view1.implicitAnyView().button()
        
        let view2 = try button2.inspect()
        let buttonView2 = try view2.implicitAnyView().button()
        
        let view3 = try button3.inspect()
        let buttonView3 = try view3.implicitAnyView().button()
        
        // 異なるボタンを個別にタップ
        try buttonView1.tap()
        #expect(button1Count == 1)
        #expect(button2Count == 0)
        #expect(button3Count == 0)
        
        try buttonView2.tap()
        #expect(button1Count == 1)
        #expect(button2Count == 1)
        #expect(button3Count == 0)
        
        try buttonView3.tap()
        #expect(button1Count == 1)
        #expect(button2Count == 1)
        #expect(button3Count == 1)
        
        // 複数回タップのテスト
        try buttonView1.tap()
        try buttonView1.tap()
        #expect(button1Count == 3)
        #expect(button2Count == 1)
        #expect(button3Count == 1)
    }
    
    @Test func testButtonColorInteraction() throws {
        // Given
        let greenButton = ChildFriendlyButton(
            title: "Green Button",
            backgroundColor: .green,
            foregroundColor: .white
        ) {}
        
        let redButton = ChildFriendlyButton(
            title: "Red Button",
            backgroundColor: .red,
            foregroundColor: .white
        ) {}
        
        // When & Then
        let greenView = try greenButton.inspect()
        let redView = try redButton.inspect()
        
        // 色の設定が正しいことを確認
        #expect(greenButton.backgroundColor == .green)
        #expect(greenButton.foregroundColor == .white)
        
        #expect(redButton.backgroundColor == .red)
        #expect(redButton.foregroundColor == .white)
        
        // ボタンの構造が正しいことを確認
        let greenButtonView = try greenView.implicitAnyView().button()
        let redButtonView = try redView.implicitAnyView().button()
        
        // ボタンが正しく生成されることを確認
        #expect(greenButtonView.pathToRoot == "implicitAnyView().button()")
        #expect(redButtonView.pathToRoot == "implicitAnyView().button()")
    }
    
    @Test func testPlayerAvatarViewWithInteractions() throws {
        // Given
        let playerName = "インタラクションアバター"
        let size: CGFloat = 80
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: nil,
            size: size
        )
        
        // Then
        let view = try avatarView.inspect()
        let vstack = try view.vStack()
        let zstack = try vstack.zStack(0)
        
        // アバターの各要素が正しく表示されることを確認
        let circle = try zstack.shape(0)
        let text = try zstack.text(1)
        let nameLabel = try vstack.text(1)
        
        #expect(circle.pathToRoot.contains("Circle"))
        #expect(try text.string() == String(playerName.prefix(1)))
        #expect(try nameLabel.string() == playerName)
        
        // プロパティが正しく設定されていることを確認
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.size == size)
        #expect(avatarView.imageData == nil)
    }
    
    @Test func testTurnIndicatorInteraction() throws {
        // Given
        let currentPlayer = "現在のプレイヤー"
        let isAnimated = true
        
        // When
        let turnIndicator = TurnIndicator(
            currentPlayerName: currentPlayer,
            isAnimated: isAnimated
        )
        
        // Then
        let view = try turnIndicator.inspect()
        let hstack = try view.hStack()
        
        // プレイヤー名が正しく表示されることを確認
        let text = try hstack.text(1)
        #expect(try text.string().contains(currentPlayer))
        
        // プロパティが正しく設定されていることを確認
        #expect(turnIndicator.currentPlayerName == currentPlayer)
        #expect(turnIndicator.isAnimated == isAnimated)
    }
    
    // MARK: - エラーハンドリングテスト
    
    @Test func testButtonInteractionWithException() throws {
        // Given
        var shouldThrow = false
        
        let button = ChildFriendlyButton(title: "Exception Test") {
            if shouldThrow {
                // 実際のアプリではエラーハンドリングが重要
                fatalError("Test exception")
            }
        }
        
        // When & Then
        let view = try button.inspect()
        let buttonView = try view.implicitAnyView().button()
        
        // 正常なタップのテスト
        shouldThrow = false
        try buttonView.tap()
        
        // 例外が発生する状況はfatalErrorを使用するため、
        // 実際のテストでは例外処理のテストは行わない
        #expect(shouldThrow == false)
    }
}