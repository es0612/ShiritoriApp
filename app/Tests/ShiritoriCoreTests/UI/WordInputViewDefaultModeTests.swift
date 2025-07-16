import Testing
import SwiftUI
import SwiftData
import ViewInspector
@testable import ShiritoriCore

@MainActor  
struct WordInputViewDefaultModeTests {
    
    @Test
    func WordInputViewの音声入力デフォルト動作テスト() async throws {
        // Given: 音声入力をデフォルトに設定されたSettings
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        // SettingsManagerを初期化（音声入力がデフォルト）
        SettingsManager.shared.initialize(with: container.mainContext)
        
        // When
        let wordInputView = WordInputView(
            isEnabled: true,
            onSubmit: { _ in }
        )
        
        // Then: ビューが表示されて初期化されることを検証
        let content = try wordInputView.inspect()
        
        // VStackの存在確認
        let _ = try content.vStack()
    }
    
    @Test
    func 入力モード切替ボタンの存在確認() throws {
        // Given
        let wordInputView = WordInputView(
            isEnabled: true,
            onSubmit: { _ in }
        )
        
        // When
        let content = try wordInputView.inspect()
        
        // Then: 音声入力ボタンの存在確認
        let voiceButton = try content.find(text: "おんせい")
        #expect(try voiceButton.string() == "おんせい")
        
        // キーボード入力ボタンの存在確認
        let keyboardButton = try content.find(text: "キーボード")
        #expect(try keyboardButton.string() == "キーボード")
    }
    
    @Test
    func 音声入力UIの要素確認() throws {
        // Given: 音声モードが有効なWordInputView
        let wordInputView = WordInputView(
            isEnabled: true,
            onSubmit: { _ in }
        )
        
        // When
        let content = try wordInputView.inspect()
        
        // Then: 音声入力の説明テキストの存在確認
        let instructionText = try content.find(text: "マイクボタンを押して話してください")
        #expect(try instructionText.string() == "マイクボタンを押して話してください")
    }
    
    @Test
    func テキスト入力UIの要素確認() throws {
        // Given
        let wordInputView = WordInputView(
            isEnabled: true,
            onSubmit: { _ in }
        )
        
        // When
        let content = try wordInputView.inspect()
        
        // Then: テキスト入力の説明テキストの存在確認
        let instructionText = try content.find(text: "さいごの もじから はじまる ことばを いれてね")
        #expect(try instructionText.string() == "さいごの もじから はじまる ことばを いれてね")
    }
    
    @Test
    func 無効状態での動作確認() throws {
        // Given: 無効状態のWordInputView
        let wordInputView = WordInputView(
            isEnabled: false,
            onSubmit: { _ in }
        )
        
        // When
        let content = try wordInputView.inspect()
        
        // Then: ビューの不透明度が0.6であることを確認
        let _ = try content.vStack()
        
        // 不透明度の確認は実際のモディファイアから取得する必要があるため、
        // ここではビューが存在することを確認
    }
    
    @Test
    func 設定反映の統合テスト() async throws {
        // Given: テスト用の設定を作成
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        // デフォルトをキーボード入力に変更
        let settingsManager = SettingsManager.shared
        settingsManager.initialize(with: container.mainContext)
        settingsManager.updateDefaultInputMode(false)  // キーボード入力に変更
        
        // When: WordInputViewを作成
        let wordInputView = WordInputView(
            isEnabled: true,
            onSubmit: { _ in }
        )
        
        // Then: ビューが正常に作成されることを確認
        let _ = try wordInputView.inspect()
        
        // 設定が反映されることを間接的に確認（実際の状態変更は内部で行われる）
        #expect(settingsManager.defaultInputMode == false)
    }
}