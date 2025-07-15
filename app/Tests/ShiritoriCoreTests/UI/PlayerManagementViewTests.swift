import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

struct PlayerManagementViewTests {
    
    @Test func testPlayerManagementViewCreation() {
        // Given
        var dismissCalled = false
        
        // When
        let view = PlayerManagementView(
            onDismiss: { dismissCalled = true }
        )
        
        // Then
        #expect(dismissCalled == false)
    }
    
    @Test func testPlayerCardViewCreation() throws {
        // Given
        let playerName = "たろうくん"
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
        
        // Then - プロパティの確認
        #expect(card.playerName == playerName)
        #expect(card.gamesPlayed == gamesPlayed)
        #expect(card.gamesWon == gamesWon)
        #expect(editCalled == false)
        #expect(deleteCalled == false)
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        
        // プレイヤーアバターの存在確認
        let avatarView = try hstack.view(PlayerAvatarView.self, 0)
        #expect(avatarView.playerName == playerName)
        
        // プレイヤー名の表示確認
        let playerInfoVStack = try hstack.vStack(1)
        let nameText = try playerInfoVStack.text(0)
        #expect(try nameText.string() == playerName)
        
        // 編集・削除ボタンの存在確認
        let actionVStack = try hstack.vStack(2)
        let editButton = try actionVStack.button(0)
        let deleteButton = try actionVStack.button(1)
        
        // ボタンのタップテスト
        try editButton.tap()
        #expect(editCalled == true)
        
        try deleteButton.tap()
        #expect(deleteCalled == true)
    }
    
    @Test func testPlayerCardViewWithZeroGames() throws {
        // Given
        let playerName = "はなちゃん"
        let gamesPlayed = 0
        let gamesWon = 0
        
        // When
        let card = PlayerCardView(
            playerName: playerName,
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            onEdit: {},
            onDelete: {}
        )
        
        // Then - プロパティの確認
        #expect(card.playerName == playerName)
        #expect(card.gamesPlayed == 0)
        #expect(card.gamesWon == 0)
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try card.inspect()
        let vstack = try view.vStack()
        let hstack = try vstack.hStack(0)
        
        // プレイヤーアバターの存在確認
        let avatarView = try hstack.view(PlayerAvatarView.self, 0)
        #expect(avatarView.playerName == playerName)
        
        // プレイヤー名の表示確認
        let playerInfoVStack = try hstack.vStack(1)
        let nameText = try playerInfoVStack.text(0)
        #expect(try nameText.string() == playerName)
        
        // 統計情報の表示確認（0戦0勝）
        let statsDisplay = try playerInfoVStack.view(PlayerStatsDisplay.self, 1)
        #expect(statsDisplay.gamesPlayed == 0)
        #expect(statsDisplay.gamesWon == 0)
    }
    
    @Test func testAddPlayerSheetCreation() throws {
        // Given
        let isPresented = true
        var saveCalled = false
        var cancelCalled = false
        var savedPlayerName: String?
        
        // When
        let sheet = AddPlayerSheet(
            isPresented: .constant(isPresented),
            onSave: { name in 
                saveCalled = true
                savedPlayerName = name
            },
            onCancel: { cancelCalled = true }
        )
        
        // Then - 初期状態の確認
        #expect(saveCalled == false)
        #expect(cancelCalled == false)
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try sheet.inspect()
        let navigationView = try view.navigationView()
        let zstack = try navigationView.zStack()
        let vstack = try zstack.vStack(1)
        
        // タイトルテキストの確認
        let titleVStack = try vstack.vStack(0)
        let titleText = try titleVStack.text(0)
        #expect(try titleText.string() == "✨ あたらしい プレイヤー")
        
        // テキストフィールドの存在確認
        let inputVStack = try vstack.vStack(1)
        let fieldVStack = try inputVStack.vStack(0)
        let labelText = try fieldVStack.text(0)
        #expect(try labelText.string() == "なまえ")
        
        let textField = try fieldVStack.textField(1)
        #expect(textField != nil)
    }
    
    @Test func testPlayerStatsDisplayCreation() throws {
        // Given
        let gamesPlayed = 10
        let gamesWon = 7
        let winRate = 0.7
        
        // When
        let stats = PlayerStatsDisplay(
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            winRate: winRate
        )
        
        // Then - プロパティの確認
        #expect(stats.gamesPlayed == gamesPlayed)
        #expect(stats.gamesWon == gamesWon)
        #expect(stats.winRate == winRate)
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try stats.inspect()
        let vstack = try view.vStack()
        
        // 試合数の表示確認
        let gamesText = try vstack.text(0)
        #expect(try gamesText.string().contains("\(gamesPlayed)"))
        
        // 勝利数の表示確認
        let winsText = try vstack.text(1)
        #expect(try winsText.string().contains("\(gamesWon)"))
        
        // 勝率の表示確認
        let winRateText = try vstack.text(2)
        #expect(try winRateText.string().contains("70.0%"))
    }
    
    @Test func testPlayerStatsDisplayWithPerfectWinRate() throws {
        // Given
        let gamesPlayed = 5
        let gamesWon = 5
        let winRate = 1.0
        
        // When
        let stats = PlayerStatsDisplay(
            gamesPlayed: gamesPlayed,
            gamesWon: gamesWon,
            winRate: winRate
        )
        
        // Then - プロパティの確認
        #expect(stats.gamesPlayed == gamesPlayed)
        #expect(stats.gamesWon == gamesWon)
        #expect(stats.winRate == winRate)
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try stats.inspect()
        let vstack = try view.vStack()
        
        // 試合数の表示確認
        let gamesText = try vstack.text(0)
        #expect(try gamesText.string().contains("\(gamesPlayed)"))
        
        // 勝利数の表示確認
        let winsText = try vstack.text(1)
        #expect(try winsText.string().contains("\(gamesWon)"))
        
        // 勝率の表示確認（100%）
        let winRateText = try vstack.text(2)
        #expect(try winRateText.string().contains("100.0%"))
    }
    
    @Test func testEmptyPlayerListViewCreation() throws {
        // Given
        var addPlayerCalled = false
        
        // When
        let emptyView = EmptyPlayerListView(
            onAddPlayer: { addPlayerCalled = true }
        )
        
        // Then - 初期状態の確認
        #expect(addPlayerCalled == false)
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try emptyView.inspect()
        let vstack = try view.vStack()
        
        // アイコンの存在確認
        let iconVStack = try vstack.vStack(1)
        let iconZStack = try iconVStack.zStack(0)
        let circle = try iconZStack.circle(0)
        #expect(circle != nil)
        
        // メッセージテキストの確認
        let messageVStack = try iconVStack.vStack(1)
        let titleText = try messageVStack.text(0)
        #expect(try titleText.string() == "まだ プレイヤーが いません")
        
        // 追加ボタンの存在確認とタップテスト
        let addButton = try vstack.view(ChildFriendlyButton.self, 2)
        #expect(addButton.title == "➕ はじめての プレイヤー")
        
        // ボタンのタップ動作をテスト
        let buttonView = try addButton.inspect()
        let button = try buttonView.implicitAnyView().button()
        try button.tap()
        #expect(addPlayerCalled == true)
    }
}