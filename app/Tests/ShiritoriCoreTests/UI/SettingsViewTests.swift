import Testing
import SwiftUI
import SwiftData
import ViewInspector
@testable import ShiritoriCore

@MainActor
struct SettingsViewTests {
    
    @Test
    func SettingsViewの初期化テスト() throws {
        // Given
        let expectation = TestExpectation()
        
        // When
        let settingsView = SettingsView { 
            expectation.fulfill()
        }
        
        // Then - SettingsViewが正常に初期化されることを確認
        let _ = try settingsView.inspect()
    }
    
    @Test
    func SettingsViewのUI要素存在確認() throws {
        // Given
        let settingsView = SettingsView {}
        
        // When
        let content = try settingsView.inspect()
        
        // Then
        // NavigationViewの存在確認
        let navigationView = try content.navigationView()
        
        // ZStackの存在確認（背景とメインコンテンツ）
        let zStack = try navigationView.zStack()
        
        // スクロールビューの存在確認
        let _ = try zStack.anyView(1)
    }
    
    @Test
    func 設定セクションの表示確認() throws {
        // Given
        let settingsView = SettingsView {}
        
        // When
        let content = try settingsView.inspect()
        
        // Then
        // ヘッダーテキストの存在確認
        let titleText = try content.find(text: "⚙️ せってい")
        #expect(try titleText.string() == "⚙️ せってい")
        
        // 説明テキストの存在確認  
        let descriptionText = try content.find(text: "あそびかたを かえられるよ")
        #expect(try descriptionText.string() == "あそびかたを かえられるよ")
    }
}

// MARK: - テスト用カスタム型

class TestExpectation {
    private var isFulfilled = false
    
    func fulfill() {
        isFulfilled = true
    }
    
    var fulfilled: Bool {
        return isFulfilled
    }
}