import Testing
import Foundation
@testable import ShiritoriCore

@Suite("SoundManager Tests")
struct SoundManagerTests {
    
    @Test("SoundManagerシングルトンテスト")
    func testSoundManagerSingleton() {
        // Given & When
        let manager1 = SoundManager.shared
        let manager2 = SoundManager.shared
        
        // Then
        #expect(manager1 === manager2) // 同じインスタンスであることを確認
    }
    
    @Test("SoundManager初期状態テスト")
    func testSoundManagerInitialState() {
        // Given & When
        let manager = SoundManager.shared
        
        // Then: 初期状態の確認
        #expect(manager.isEnabled == true) // デフォルトで有効
        #expect(manager.volume >= 0.0 && manager.volume <= 1.0) // 音量範囲チェック
    }
    
    @Test("効果音有効無効設定テスト")
    func testSoundEnabledSetting() {
        // Given
        let manager = SoundManager.shared
        let initialState = manager.isEnabled
        
        // When: 設定をfalseに変更
        manager.setEnabled(false)
        
        // Then
        #expect(manager.isEnabled == false)
        
        // When: 設定をtrueに変更
        manager.setEnabled(true)
        
        // Then
        #expect(manager.isEnabled == true)
        
        // Cleanup: 元の状態に戻す
        manager.setEnabled(initialState)
    }
    
    @Test("音量設定テスト")
    func testVolumeSetting() {
        // Given
        let manager = SoundManager.shared
        let initialVolume = manager.volume
        
        // When: 音量を変更
        manager.setVolume(0.5)
        
        // Then
        #expect(manager.volume == 0.5)
        
        // When: 範囲外の値をテスト（下限）
        manager.setVolume(-0.1)
        
        // Then
        #expect(manager.volume == 0.0) // 下限でクランプされる
        
        // When: 範囲外の値をテスト（上限）
        manager.setVolume(1.5)
        
        // Then
        #expect(manager.volume == 1.0) // 上限でクランプされる
        
        // Cleanup: 元の音量に戻す
        manager.setVolume(initialVolume)
    }
    
    @Test("効果音再生メソッドテスト")
    func testSoundPlaybackMethods() {
        // Given
        let manager = SoundManager.shared
        
        // 効果音が有効な状態でテスト
        manager.setEnabled(true)
        
        // When & Then: メソッドがクラッシュしないことを確認
        manager.playCorrectSound()
        manager.playIncorrectSound()
        manager.playTurnChangeSound()
        manager.playEliminationSound()
        manager.playGameEndSound()
        
        // 静的メソッドのテスト
        SoundManager.playSuccessFeedback()
        SoundManager.playErrorFeedback()
        SoundManager.playTurnChangeFeedback()
        SoundManager.playEliminationFeedback()
        
        // 触覚フィードバックのテスト
        SoundManager.playHapticFeedback()
        
        // すべて正常に実行されれば成功
        #expect(true)
    }
    
    @Test("効果音無効時の動作テスト")
    func testSoundPlaybackWhenDisabled() {
        // Given
        let manager = SoundManager.shared
        let originalState = manager.isEnabled
        
        // When: 効果音を無効にする
        manager.setEnabled(false)
        
        // Then: メソッドがクラッシュしないことを確認
        manager.playCorrectSound()
        manager.playIncorrectSound()
        manager.playTurnChangeSound()
        manager.playEliminationSound()
        manager.playGameEndSound()
        
        // すべて正常に実行されれば成功
        #expect(true)
        
        // Cleanup: 元の状態に戻す
        manager.setEnabled(originalState)
    }
    
    @Test("音量境界値テスト")
    func testVolumeBoundaryValues() {
        // Given
        let manager = SoundManager.shared
        let originalVolume = manager.volume
        
        // When & Then: 最小値
        manager.setVolume(0.0)
        #expect(manager.volume == 0.0)
        
        // When & Then: 最大値
        manager.setVolume(1.0)
        #expect(manager.volume == 1.0)
        
        // When & Then: 中間値
        manager.setVolume(0.5)
        #expect(manager.volume == 0.5)
        
        // Cleanup
        manager.setVolume(originalVolume)
    }
    
    @Test("設定永続化テスト")
    func testSettingsPersistence() {
        // Given
        let manager = SoundManager.shared
        let originalEnabled = manager.isEnabled
        let originalVolume = manager.volume
        
        // When: 設定を変更
        let newEnabled = !originalEnabled
        let newVolume: Float = 0.3
        
        manager.setEnabled(newEnabled)
        manager.setVolume(newVolume)
        
        // Then: 現在の設定が反映されている
        #expect(manager.isEnabled == newEnabled)
        #expect(manager.volume == newVolume)
        
        // UserDefaultsに保存されているかチェック
        let savedEnabled = UserDefaults.standard.object(forKey: "sound_enabled") as? Bool
        let savedVolume = UserDefaults.standard.object(forKey: "sound_volume") as? Float
        
        #expect(savedEnabled == newEnabled)
        #expect(savedVolume == newVolume)
        
        // Cleanup: 元の設定に戻す
        manager.setEnabled(originalEnabled)
        manager.setVolume(originalVolume)
    }
}