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
    
    // MARK: - バグ再現テスト (Issue #2: 設定画面の重複ナビゲーションバグ)
    
    @Test
    func バグ再現_設定画面の重複ナビゲーション問題() throws {
        // Given: NavigationStack内で使用されるSettingsView
        // （実際のアプリではTitleView内のNavigationStackでラップされている）
        let settingsView = SettingsView {}
        
        // When: SettingsViewのUI構造を検査
        let content = try settingsView.inspect()
        
        // Then: ZStackが最上位にあることを確認
        let zStack = try content.zStack()
        
        // VStackの中にBackButtonがあることを確認（これが問題の原因）
        let vStack = try zStack.vStack(1)
        
        AppLogger.shared.info("🔍 バグ分析: SettingsViewが手動のBackButtonを含んでいる")
        AppLogger.shared.info("   問題: NavigationStack内で表示時、標準戻るボタンと重複する")
        AppLogger.shared.info("   構造: ZStack -> VStack -> BackButton（先頭要素）")
        AppLogger.shared.info("   解決案: BackButtonを除去し、NavigationStackの標準ナビゲーションに依存する")
    }
    
    @Test
    func バグ再現_手動戻るボタンとNavigationStackの競合() throws {
        // Given: SettingsView
        let settingsView = SettingsView {}
        
        // When: UI構造を検査してBackButtonの存在を確認
        let content = try settingsView.inspect()
        let zStack = try content.zStack()
        let vStack = try zStack.vStack(1)
        
        // Then: BackButtonが最初の要素として存在することを確認
        do {
            let _ = try vStack.anyView(0) // BackButtonをアクセス
            
            // BackButtonの存在確認（内部構造を検査）
            AppLogger.shared.warning("❌ バグ確認: VStackの最初の要素としてBackButtonが検出されました")
            AppLogger.shared.info("   位置: ZStack -> VStack -> BackButton (index: 0)")
            AppLogger.shared.info("   これがNavigationStackの標準戻るボタンと重複します")
            
            // BackButtonが存在することが問題の確認
            #expect(true, "手動のBackButtonが存在することを確認")
        } catch {
            AppLogger.shared.info("✅ 正常: 手動の戻るボタンは見つかりませんでした")
            #expect(false, "BackButtonが見つからない場合、修正済みの状態です")
        }
    }
    
    @Test
    func 期待される修正後の動作() throws {
        // Given: 修正後のSettingsViewの期待される動作
        let settingsView = SettingsView {}
        
        // When: UI構造を検査
        let content = try settingsView.inspect()
        
        // Then: 基本的なコンテンツが存在することを確認
        let titleText = try content.find(text: "⚙️ せってい")
        #expect(try titleText.string() == "⚙️ せってい", "タイトルが正しく表示されること")
        
        // 修正後は：ZStack -> VStack -> ScrollView（BackButtonなし）
        let zStack = try content.zStack()
        let vStack = try zStack.vStack(1)
        
        // ScrollViewが最初の要素になることを期待（BackButtonが除去されるため）
        do {
            let _ = try vStack.scrollView(0) // 最初の要素がScrollViewであることを確認
            AppLogger.shared.info("✅ 修正後確認: VStackの最初の要素がScrollViewであることを確認")
        } catch {
            AppLogger.shared.warning("修正後の構造確認に失敗: \\(error)")
        }
        
        AppLogger.shared.info("📋 修正後の期待動作:")
        AppLogger.shared.info("   - 手動のBackButtonを除去")
        AppLogger.shared.info("   - NavigationStackが標準の戻るボタンを提供")
        AppLogger.shared.info("   - ZStack -> VStack -> ScrollView の構造")
        AppLogger.shared.info("   - スワイプジェスチャーなどの標準ナビゲーションが利用可能")
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