import Testing
import SwiftUI
@testable import ShiritoriCore

struct TitleViewTests {
    
    @Test func testEnhancedTitleViewCreation() {
        // Given
        let isAnimationEnabled = true
        var startButtonTapped = false
        var playersButtonTapped = false
        
        // When
        let titleView = EnhancedTitleView(
            isAnimationEnabled: isAnimationEnabled,
            onStartGame: { startButtonTapped = true },
            onManagePlayers: { playersButtonTapped = true }
        )
        
        // Then
        #expect(titleView.isAnimationEnabled == isAnimationEnabled)
        #expect(startButtonTapped == false)
        #expect(playersButtonTapped == false)
    }
    
    @Test func testEnhancedTitleViewWithoutAnimation() {
        // Given
        let isAnimationEnabled = false
        var actionCalled = false
        
        // When
        let titleView = EnhancedTitleView(
            isAnimationEnabled: isAnimationEnabled,
            onStartGame: { actionCalled = true },
            onManagePlayers: { actionCalled = true }
        )
        
        // Then
        #expect(titleView.isAnimationEnabled == false)
    }
    
    @Test func testAnimatedTitleTextCreation() {
        // Given
        let title = "しりとりあそび"
        let isAnimated = true
        
        // When
        let animatedTitle = AnimatedTitleText(
            title: title,
            isAnimated: isAnimated
        )
        
        // Then
        #expect(animatedTitle.title == title)
        #expect(animatedTitle.isAnimated == isAnimated)
    }
    
    @Test func testAnimatedTitleTextWithoutAnimation() {
        // Given
        let title = "テストタイトル"
        let isAnimated = false
        
        // When
        let animatedTitle = AnimatedTitleText(
            title: title,
            isAnimated: isAnimated
        )
        
        // Then
        #expect(animatedTitle.title == title)
        #expect(animatedTitle.isAnimated == false)
    }
    
    @Test func testChildFriendlyBackgroundCreation() {
        // Given
        let animationSpeed: Double = 2.0
        
        // When
        let background = ChildFriendlyBackground(
            animationSpeed: animationSpeed
        )
        
        // Then
        #expect(background.animationSpeed == animationSpeed)
    }
    
    @Test func testChildFriendlyBackgroundDefaultSpeed() {
        // Given & When
        let background = ChildFriendlyBackground()
        
        // Then
        #expect(background.animationSpeed == 1.0)
    }
}