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
        
        // Then
        #expect(settingsView.onDismiss != nil)
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
        #expect(navigationView != nil)
        
        // ZStackの存在確認（背景とメインコンテンツ）
        let zStack = try navigationView.zStack()
        #expect(zStack != nil)
        
        // スクロールビューの存在確認
        let scrollView = try zStack.scrollView()
        #expect(scrollView != nil)
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
        #expect(titleText.string() == "⚙️ せってい")
        
        // 説明テキストの存在確認  
        let descriptionText = try content.find(text: "あそびかたを かえられるよ")
        #expect(descriptionText.string() == "あそびかたを かえられるよ")
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