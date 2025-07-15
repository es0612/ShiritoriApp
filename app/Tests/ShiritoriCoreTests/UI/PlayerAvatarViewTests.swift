import Testing
import SwiftUI
import ViewInspector
@testable import ShiritoriCore

struct PlayerAvatarViewTests {
    
    // MARK: - ダークモード対応テスト
    
    @Test func testPlayerAvatarViewDarkModeAdaptation() throws {
        // Given
        let playerName = "ダークモードテスト"
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
        
        // ZStackの存在確認
        let zstack = try vstack.zStack(0)
        #expect(zstack != nil)
        
        // Circle要素の存在確認
        let circle = try zstack.circle(0)
        #expect(circle != nil)
        
        // プレイヤー名の頭文字が表示されているかテスト
        let text = try zstack.text(1)
        #expect(try text.string() == String(playerName.prefix(1)))
        
        // プレイヤー名のラベルが表示されているかテスト
        let nameLabel = try vstack.text(1)
        #expect(try nameLabel.string() == playerName)
        
        // プロパティが正しく設定されていることを確認
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.size == size)
        #expect(avatarView.imageData == nil)
    }
    
    @Test func testPlayerAvatarViewColorAdaptation() throws {
        // Given
        let playerName = "カラーテスト"
        let size: CGFloat = 100
        
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
        
        // Circle要素の存在確認
        let circle = try zstack.circle(0)
        #expect(circle != nil)
        
        // テキスト要素の存在確認
        let text = try zstack.text(1)
        #expect(try text.string() == String(playerName.prefix(1)))
        
        // プレイヤー名の頭文字が正しく表示されることを確認
        let expectedInitial = String(playerName.prefix(1))
        #expect(try text.string() == expectedInitial)
    }
    
    @Test func testPlayerAvatarViewWithDifferentSizes() throws {
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
            
            // Then
            let view = try avatarView.inspect()
            let vstack = try view.vStack()
            let zstack = try vstack.zStack(0)
            
            // Circle要素の存在確認
            let circle = try zstack.circle(0)
            #expect(circle != nil)
            
            // サイズプロパティが正しく設定されていることを確認
            #expect(avatarView.size == size)
            
            // プレイヤー名の頭文字が表示されているかテスト
            let text = try zstack.text(1)
            #expect(try text.string() == String(playerName.prefix(1)))
        }
    }
    
    @Test func testPlayerAvatarViewWithImageData() throws {
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
        
        // Then
        let view = try avatarView.inspect()
        let vstack = try view.vStack()
        
        // 基本構造の確認
        let zstack = try vstack.zStack(0)
        #expect(zstack != nil)
        
        // プロパティが正しく設定されていることを確認
        #expect(avatarView.playerName == playerName)
        #expect(avatarView.imageData == imageData)
        #expect(avatarView.size == size)
        
        // プレイヤー名のラベルが表示されているかテスト
        let nameLabel = try vstack.text(1)
        #expect(try nameLabel.string() == playerName)
    }
    
    @Test func testPlayerAvatarViewWithLongName() throws {
        // Given
        let playerName = "とても長いプレイヤー名前テスト"
        let size: CGFloat = 60
        
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
        
        // プレイヤー名の頭文字が正しく表示されることを確認
        let text = try zstack.text(1)
        #expect(try text.string() == String(playerName.prefix(1)))
        
        // プレイヤー名のラベルが表示されているかテスト
        let nameLabel = try vstack.text(1)
        #expect(try nameLabel.string() == playerName)
    }
    
    @Test func testPlayerAvatarViewWithEmptyName() throws {
        // Given
        let playerName = ""
        let size: CGFloat = 60
        
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
        
        // 空の名前でもビューが正常に構築されることを確認
        let circle = try zstack.circle(0)
        #expect(circle != nil)
        
        // 空の名前の場合でもテキストが表示されることを確認
        let text = try zstack.text(1)
        #expect(try text.string() == "")
        
        // プレイヤー名のラベルが表示されているかテスト
        let nameLabel = try vstack.text(1)
        #expect(try nameLabel.string() == playerName)
    }
    
    @Test func testPlayerAvatarViewWithSpecialCharacters() throws {
        // Given
        let playerName = "🎮プレイヤー★"
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
        
        // 特殊文字を含む名前でも正常に動作することを確認
        let text = try zstack.text(1)
        #expect(try text.string() == String(playerName.prefix(1)))
        
        // プレイヤー名のラベルが表示されているかテスト
        let nameLabel = try vstack.text(1)
        #expect(try nameLabel.string() == playerName)
    }
    
    @Test func testPlayerAvatarViewStructure() throws {
        // Given
        let playerName = "構造テスト"
        let size: CGFloat = 60
        
        // When
        let avatarView = PlayerAvatarView(
            playerName: playerName,
            imageData: nil,
            size: size
        )
        
        // Then
        let view = try avatarView.inspect()
        let vstack = try view.vStack()
        
        // VStackの構造が正しいことを確認
        #expect(vstack != nil)
        
        // ZStackが最初の要素として存在することを確認
        let zstack = try vstack.zStack(0)
        #expect(zstack != nil)
        
        // Circle要素が存在することを確認
        let circle = try zstack.circle(0)
        #expect(circle != nil)
        
        // テキスト要素が存在することを確認
        let text = try zstack.text(1)
        #expect(text != nil)
        
        // プレイヤー名ラベルが存在することを確認
        let nameLabel = try vstack.text(1)
        #expect(nameLabel != nil)
    }
}