import Testing
import SwiftUI
@testable import ShiritoriCore

struct PlayerAvatarViewTests {
    
    @Test func testPlayerAvatarViewCreation() {
        // Given
        let playerName = "テストプレイヤー"
        let size: CGFloat = 80
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: nil,
            size: size
        )
        
        // Then - プロパティが正しく設定されていることを確認
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.size == size)
        #expect(avatarView.imageData == nil)
    }
    
    @Test func testPlayerAvatarViewWithImageData() {
        // Given
        let playerName = "画像テスト"
        let imageData = Data([0x00, 0x01, 0x02, 0x03]) // ダミー画像データ
        let size: CGFloat = 80
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: imageData,
            size: size
        )
        
        // Then - プロパティが正しく設定されていることを確認
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.imageData == imageData)
        #expect(avatarView.size == size)
    }
    
    @Test func testPlayerAvatarViewWithDifferentSizes() {
        // Given
        let playerName = "サイズテスト"
        let sizes: [CGFloat] = [40, 60, 80, 120]
        
        for size in sizes {
            // When
            let avatarView = PlayerAvatarView(
                playerName: playerName,
                imageData: nil,
                size: size
            )
            
            // Then - サイズプロパティが正しく設定されていることを確認
            #expect(avatarView.size == size)
        }
    }
    
    @Test func testPlayerAvatarViewWithEmptyName() {
        // Given
        let playerName = ""
        let size: CGFloat = 60
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: nil,
            size: size
        )
        
        // Then - 空の名前でも正常にビューが構築されることを確認
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.size == size)
    }
}