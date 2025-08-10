import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

struct CommonUIComponentsTests {
    
    // MARK: - ChildFriendlyButton Tests
    
    @Test func testChildFriendlyButtonCreation() throws {
        // Given
        let title = "スタート"
        let backgroundColor = Color.green
        let foregroundColor = Color.white
        var actionCalled = false
        
        // When
        let button = ChildFriendlyButton(
            title: title,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ) {
            actionCalled = true
        }
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try button.inspect()
        let buttonView = try view.implicitAnyView().button()
        
        // ボタンのタップ動作をテスト
        try buttonView.tap()
        #expect(actionCalled == true)
    }
    
    @Test func testChildFriendlyButtonDefaultColors() throws {
        // Given
        let title = "デフォルトボタン"
        var actionCalled = false
        
        // When
        let button = ChildFriendlyButton(title: title) {
            actionCalled = true
        }
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try button.inspect()
        let buttonView = try view.implicitAnyView().button()
        
        // ボタンのラベルテキストを確認
        let text = try buttonView.labelView().text()
        #expect(try text.string() == title)
        
        // ボタンのタップ動作をテスト
        try buttonView.tap()
        #expect(actionCalled == true)
    }
    
    // MARK: - PlayerAvatarView Tests
    
    @Test func testPlayerAvatarViewWithImage() throws {
        // Given
        let playerName = "たろうくん"
        let imageData = Data() // 空のImageData
        let size: CGFloat = 60
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: imageData,
            size: size
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try avatarView.inspect()
        let vstack = try view.vStack()
        
        // ZStackの存在確認
        let zstack = try vstack.zStack(0)
        
        // Circle要素の存在確認
        let _ = try zstack.shape(0)
        
        // プレイヤー名の頭文字が表示されているかテスト
        let text = try zstack.text(1)
        #expect(try text.string() == String(playerName.prefix(1)))
        
        // プレイヤー名のラベルが表示されているかテスト
        let nameLabel = try vstack.text(1)
        #expect(try nameLabel.string() == playerName)
    }
    
    @Test func testPlayerAvatarViewWithoutImage() throws {
        // Given
        let playerName = "はなちゃん"
        let size: CGFloat = 80
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: nil,
            size: size
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try avatarView.inspect()
        let vstack = try view.vStack()
        
        // ZStackの存在確認
        let zstack = try vstack.zStack(0)
        
        // Circle要素の存在確認
        let _ = try zstack.shape(0)
        
        // プレイヤー名の頭文字が表示されているかテスト
        let text = try zstack.text(1)
        #expect(try text.string() == String(playerName.prefix(1)))
        
        // プレイヤー名のラベルが表示されているかテスト
        let nameLabel = try vstack.text(1)
        #expect(try nameLabel.string() == playerName)
    }
    
    // MARK: - WordDisplayCard Tests
    
    @Test func testWordDisplayCardWithWord() throws {
        // Given
        let word = "りんご"
        let isHighlighted = true
        
        // When
        let wordCard = WordDisplayCard(
            word: word,
            isHighlighted: isHighlighted
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try wordCard.inspect()
        let vstack = try view.vStack()
        
        // 単語テキストが表示されているかテスト
        let text = try vstack.text(0)
        #expect(try text.string() == word)
    }
    
    @Test func testWordDisplayCardWithoutWord() throws {
        // Given
        let word: String? = nil
        let isHighlighted = false
        
        // When
        let wordCard = WordDisplayCard(
            word: word,
            isHighlighted: isHighlighted
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try wordCard.inspect()
        let vstack = try view.vStack()
        
        // 単語がない場合の表示テスト
        let text = try vstack.text(0)
        #expect(try text.string() == "")
    }
    
    // MARK: - MicrophoneButton Tests
    
    @Test func testMicrophoneButtonCreation() throws {
        // Given
        let speechState = SpeechRecognitionState()
        let size: CGFloat = 120
        var touchDownCalled = false
        var touchUpCalled = false
        
        // When
        let micButton = MicrophoneButton(
            speechState: speechState,
            size: size,
            onTouchDown: { touchDownCalled = true },
            onTouchUp: { touchUpCalled = true }
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try micButton.inspect()
        let button = try view.button()
        
        // マイクアイコンが表示されているかテスト
        let _ = try button.labelView().image()
        
        // 初期状態ではタッチイベントが呼ばれていないことを確認
        #expect(touchDownCalled == false)
        #expect(touchUpCalled == false)
    }
    
    @Test func testMicrophoneButtonRecordingState() throws {
        // Given
        let speechState = SpeechRecognitionState()
        speechState.startRecording() // 録音状態に設定
        let size: CGFloat = 100
        
        // When
        let micButton = MicrophoneButton(
            speechState: speechState,
            size: size,
            onTouchDown: {},
            onTouchUp: {}
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try micButton.inspect()
        let button = try view.button()
        
        // 録音状態でマイクアイコンが表示されているかテスト
        let _ = try button.labelView().image()
    }
    
    // MARK: - TurnIndicator Tests
    
    @Test func testTurnIndicatorCurrentPlayer() throws {
        // Given
        let currentPlayerName = "たろうくん"
        let isAnimated = true
        
        // When
        let turnIndicator = TurnIndicator(
            currentPlayerName: currentPlayerName,
            isAnimated: isAnimated
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try turnIndicator.inspect()
        let hstack = try view.hStack()
        
        // プレイヤー名が表示されているかテスト
        let text = try hstack.text(1)
        #expect(try text.string().contains(currentPlayerName))
    }
    
    @Test func testTurnIndicatorWithoutAnimation() throws {
        // Given
        let currentPlayerName = "はなちゃん"
        let isAnimated = false
        
        // When
        let turnIndicator = TurnIndicator(
            currentPlayerName: currentPlayerName,
            isAnimated: isAnimated
        )
        
        // Then - ViewInspectorではプロパティの直接アクセスではなく、Viewの構造を確認
        
        // ViewInspectorを使用した実際のView構造の確認
        let view = try turnIndicator.inspect()
        let hstack = try view.hStack()
        
        // プレイヤー名が表示されているかテスト
        let text = try hstack.text(1)
        #expect(try text.string().contains(currentPlayerName))
    }
}