import Testing
import SwiftUI
@testable import ShiritoriCore

struct CommonUIComponentsTests {
    
    // MARK: - ChildFriendlyButton Tests
    
    @Test func testChildFriendlyButtonCreation() {
        // Given
        let title = "スタート"
        let backgroundColor = Color.green
        let foregroundColor = Color.white
        
        // When
        let button = ChildFriendlyButton(
            title: title,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor
        ) {
            // テストアクション
        }
        
        // Then
        #expect(button.title == title)
        #expect(button.backgroundColor == backgroundColor)
        #expect(button.foregroundColor == foregroundColor)
    }
    
    @Test func testChildFriendlyButtonDefaultColors() {
        // Given
        let title = "デフォルトボタン"
        
        // When
        let button = ChildFriendlyButton(title: title) {
            // テストアクション
        }
        
        // Then
        #expect(button.title == title)
        #expect(button.backgroundColor == Color.blue)
        #expect(button.foregroundColor == Color.white)
    }
    
    // MARK: - PlayerAvatarView Tests
    
    @Test func testPlayerAvatarViewWithImage() {
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
        
        // Then
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.imageData == imageData)
        #expect(avatarView.size == size)
    }
    
    @Test func testPlayerAvatarViewWithoutImage() {
        // Given
        let playerName = "はなちゃん"
        let size: CGFloat = 80
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: nil,
            size: size
        )
        
        // Then
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.imageData == nil)
        #expect(avatarView.size == size)
    }
    
    // MARK: - WordDisplayCard Tests
    
    @Test func testWordDisplayCardWithWord() {
        // Given
        let word = "りんご"
        let isHighlighted = true
        
        // When
        let wordCard = WordDisplayCard(
            word: word,
            isHighlighted: isHighlighted
        )
        
        // Then
        #expect(wordCard.word == word)
        #expect(wordCard.isHighlighted == isHighlighted)
    }
    
    @Test func testWordDisplayCardWithoutWord() {
        // Given
        let word: String? = nil
        let isHighlighted = false
        
        // When
        let wordCard = WordDisplayCard(
            word: word,
            isHighlighted: isHighlighted
        )
        
        // Then
        #expect(wordCard.word == nil)
        #expect(wordCard.isHighlighted == isHighlighted)
    }
    
    // MARK: - MicrophoneButton Tests
    
    @Test func testMicrophoneButtonCreation() {
        // Given
        let isRecording = false
        let size: CGFloat = 120
        
        // When
        let micButton = MicrophoneButton(
            isRecording: isRecording,
            size: size,
            onTouchDown: {},
            onTouchUp: {}
        )
        
        // Then
        #expect(micButton.isRecording == isRecording)
        #expect(micButton.size == size)
    }
    
    @Test func testMicrophoneButtonRecordingState() {
        // Given
        let isRecording = true
        let size: CGFloat = 100
        
        // When
        let micButton = MicrophoneButton(
            isRecording: isRecording,
            size: size,
            onTouchDown: {},
            onTouchUp: {}
        )
        
        // Then
        #expect(micButton.isRecording == true)
    }
    
    // MARK: - TurnIndicator Tests
    
    @Test func testTurnIndicatorCurrentPlayer() {
        // Given
        let currentPlayerName = "たろうくん"
        let isAnimated = true
        
        // When
        let turnIndicator = TurnIndicator(
            currentPlayerName: currentPlayerName,
            isAnimated: isAnimated
        )
        
        // Then
        #expect(turnIndicator.currentPlayerName == currentPlayerName)
        #expect(turnIndicator.isAnimated == isAnimated)
    }
    
    @Test func testTurnIndicatorWithoutAnimation() {
        // Given
        let currentPlayerName = "はなちゃん"
        let isAnimated = false
        
        // When
        let turnIndicator = TurnIndicator(
            currentPlayerName: currentPlayerName,
            isAnimated: isAnimated
        )
        
        // Then
        #expect(turnIndicator.currentPlayerName == currentPlayerName)
        #expect(turnIndicator.isAnimated == false)
    }
}