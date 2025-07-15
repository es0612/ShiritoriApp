import Testing
import SwiftData
@testable import ShiritoriCore

@MainActor
struct SettingsManagerTests {
    
    @Test
    func SettingsManagerシングルトンテスト() {
        // When
        let manager1 = SettingsManager.shared
        let manager2 = SettingsManager.shared
        
        // Then
        #expect(manager1 === manager2)
    }
    
    @Test
    func デフォルト設定値の確認() {
        // Given
        let settings = AppSettings()
        
        // Then
        #expect(settings.defaultInputMode == true)  // デフォルトは音声入力
        #expect(settings.voiceAutoSubmit == true)
        #expect(settings.voiceSensitivity == 0.7)
        #expect(settings.id == "app_settings_singleton")
    }
    
    @Test
    func 設定値の更新テスト() async {
        // Given
        let settings = AppSettings()
        let originalDate = settings.lastUpdated
        
        // 微小な時間差を確保
        try? await Task.sleep(nanoseconds: 1_000_000) // 1ms
        
        // When
        settings.updateSettings(
            defaultInputMode: false,
            voiceAutoSubmit: false,
            voiceSensitivity: 0.5
        )
        
        // Then
        #expect(settings.defaultInputMode == false)
        #expect(settings.voiceAutoSubmit == false)
        #expect(settings.voiceSensitivity == 0.5)
        #expect(settings.lastUpdated > originalDate)
    }
    
    @Test
    func 音声感度の範囲制限テスト() {
        // Given
        let settings = AppSettings()
        
        // When: 範囲外の値を設定
        settings.updateSettings(voiceSensitivity: 1.5)  // 上限超過
        
        // Then: 1.0に制限される
        #expect(settings.voiceSensitivity == 1.0)
        
        // When: 範囲外の値を設定
        settings.updateSettings(voiceSensitivity: -0.5)  // 下限未満
        
        // Then: 0.0に制限される
        #expect(settings.voiceSensitivity == 0.0)
    }
    
    @Test
    func デフォルトリセット機能テスト() {
        // Given
        let settings = AppSettings()
        settings.updateSettings(
            defaultInputMode: false,
            voiceAutoSubmit: false,
            voiceSensitivity: 0.3
        )
        
        // When
        settings.resetToDefaults()
        
        // Then
        #expect(settings.defaultInputMode == true)
        #expect(settings.voiceAutoSubmit == true)
        #expect(settings.voiceSensitivity == 0.7)
    }
    
    @Test 
    func InputMode列挙型のテスト() {
        // When & Then
        #expect(InputMode.voice.displayName == "音声入力")
        #expect(InputMode.keyboard.displayName == "キーボード入力")
        #expect(InputMode.voice.iconName == "mic.fill")
        #expect(InputMode.keyboard.iconName == "keyboard")
        #expect(InputMode.voice.childFriendlyDescription == "こえで ことばを いうよ")
        #expect(InputMode.keyboard.childFriendlyDescription == "ゆびで もじを うつよ")
    }
    
    @Test
    func 設定マネージャーの便利メソッドテスト() {
        // Given  
        let settingsManager = SettingsManager.shared
        
        // InMemoryでテスト用モデルコンテナを作成
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        // When
        settingsManager.initialize(with: container.mainContext)
        
        // Then
        let displayName = settingsManager.getInputModeDisplayName()
        #expect(displayName == "音声入力")
    }
}