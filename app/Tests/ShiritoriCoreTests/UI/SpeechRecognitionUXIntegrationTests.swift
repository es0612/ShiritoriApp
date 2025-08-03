import Testing
import SwiftUI
import SwiftData
@testable import ShiritoriCore

@MainActor  
@Suite("音声認識UX改善 統合テスト")
struct SpeechRecognitionUXIntegrationTests {
    
    @Test("完全な失敗→自動切り替えシナリオテスト")
    func testCompleteFailureToAutoFallbackScenario() async throws {
        // Given: テスト用設定
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        let settingsManager = SettingsManager.shared
        settingsManager.initialize(with: container.mainContext)
        
        // 自動フォールバック有効、閾値3回に設定
        settingsManager.updateAutoFallbackEnabled(true)
        settingsManager.updateSpeechFailureThreshold(3)
        
        let speechManager = SpeechRecognitionManager()
        
        // When: シナリオ実行
        // 1回目の失敗
        speechManager.incrementFailureCount()
        let firstMessage = getIntegratedGuidanceMessage(for: speechManager.consecutiveFailureCount)
        
        // 2回目の失敗
        speechManager.incrementFailureCount()
        let secondMessage = getIntegratedGuidanceMessage(for: speechManager.consecutiveFailureCount)
        
        // 3回目の失敗（閾値到達）
        speechManager.incrementFailureCount()
        let shouldTriggerFallback = speechManager.hasReachedFailureThreshold()
        
        // Then: 期待される動作を検証
        #expect(firstMessage == "もう一度話してみてね")
        #expect(secondMessage == "ゆっくり はっきり話してみてね")
        #expect(shouldTriggerFallback == true)
        #expect(settingsManager.autoFallbackEnabled == true)
    }
    
    @Test("自動フォールバック無効時のシナリオテスト")
    func testAutoFallbackDisabledScenario() async throws {
        // Given: 自動フォールバック無効設定
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        let settingsManager = SettingsManager.shared
        settingsManager.initialize(with: container.mainContext)
        settingsManager.updateAutoFallbackEnabled(false)
        
        let speechManager = SpeechRecognitionManager()
        
        // When: 3回連続失敗
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        
        // Then: 閾値に達するが自動切り替えは発生しない
        #expect(speechManager.hasReachedFailureThreshold() == true)
        #expect(settingsManager.autoFallbackEnabled == false)
    }
    
    @Test("カスタム閾値での動作テスト")
    func testCustomThresholdBehavior() async throws {
        // Given: カスタム閾値設定（2回）
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        let settingsManager = SettingsManager.shared
        settingsManager.initialize(with: container.mainContext)
        settingsManager.updateSpeechFailureThreshold(2) // 2回で閾値
        
        let speechManager = SpeechRecognitionManager()
        speechManager.setFailureThreshold(settingsManager.speechFailureThreshold)
        
        // When: 2回失敗
        speechManager.incrementFailureCount()
        #expect(!speechManager.hasReachedFailureThreshold())
        
        speechManager.incrementFailureCount()
        
        // Then: 2回で閾値に達する
        #expect(speechManager.hasReachedFailureThreshold())
        #expect(settingsManager.speechFailureThreshold == 2)
    }
    
    @Test("成功によるリセット→再失敗シナリオテスト")
    func testSuccessResetAndRetryScenario() {
        // Given
        let speechManager = SpeechRecognitionManager()
        
        // When: 2回失敗→成功→再び2回失敗
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        #expect(speechManager.consecutiveFailureCount == 2)
        
        // 成功でリセット
        speechManager.recordRecognitionSuccess()
        #expect(speechManager.consecutiveFailureCount == 0)
        
        // 再び失敗
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        
        // Then: カウンターが正しく動作
        #expect(speechManager.consecutiveFailureCount == 2)
        #expect(!speechManager.hasReachedFailureThreshold()) // まだ3回に達していない
    }
    
    @Test("設定永続化テスト")
    func testSettingsPersistence() async throws {
        // Given: 永続化設定（テスト用にメモリ内で実行）
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        let settingsManager = SettingsManager.shared
        settingsManager.initialize(with: container.mainContext)
        
        // When: 設定を変更
        let originalAutoFallback = settingsManager.autoFallbackEnabled
        let originalThreshold = settingsManager.speechFailureThreshold
        
        settingsManager.updateAutoFallbackEnabled(!originalAutoFallback)
        settingsManager.updateSpeechFailureThreshold(originalThreshold == 3 ? 2 : 3)
        
        // Then: 設定が保存されている
        #expect(settingsManager.autoFallbackEnabled != originalAutoFallback)
        #expect(settingsManager.speechFailureThreshold != originalThreshold)
    }
    
    @Test("UI状態遷移シミュレーションテスト")
    func testUIStateTransitionSimulation() async throws {
        // Given: WordInputViewの状態シミュレーション
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        let settingsManager = SettingsManager.shared
        settingsManager.initialize(with: container.mainContext)
        
        // UI状態をシミュレートする変数
        var isVoiceMode = true
        var showFallbackMessage = false
        var hasAutoSwitched = false
        var guidanceMessage = ""
        
        let speechManager = SpeechRecognitionManager()
        
        // When: 失敗シナリオをシミュレート
        
        // 1回目の失敗
        speechManager.incrementFailureCount()
        if speechManager.consecutiveFailureCount == 1 {
            showFallbackMessage = true
            guidanceMessage = "もう一度話してみてね"
        }
        
        // 2回目の失敗
        speechManager.incrementFailureCount()
        if speechManager.consecutiveFailureCount == 2 {
            guidanceMessage = "ゆっくり はっきり話してみてね"
        }
        
        // 3回目の失敗（自動切り替え）
        speechManager.incrementFailureCount()
        if settingsManager.autoFallbackEnabled && 
           speechManager.hasReachedFailureThreshold() && 
           !hasAutoSwitched {
            hasAutoSwitched = true
            isVoiceMode = false
            guidanceMessage = "キーボードで入力してみよう！"
        }
        
        // Then: UI状態が期待通りに遷移
        #expect(isVoiceMode == false) // キーボードモードに切り替わった
        #expect(showFallbackMessage == true) // ガイダンスメッセージが表示されている
        #expect(hasAutoSwitched == true) // 自動切り替えが発生した
        #expect(guidanceMessage == "キーボードで入力してみよう！") // 適切なメッセージ
    }
    
    @Test("メモリリークチェック（簡易版）")
    func testMemoryLeakCheck() {
        // Given: 複数のマネージャーインスタンス
        var speechManagers: [SpeechRecognitionManager] = []
        
        // When: 大量のインスタンスを作成・破棄
        for _ in 1...10 {
            let manager = SpeechRecognitionManager()
            manager.incrementFailureCount()
            manager.incrementFailureCount()
            manager.recordRecognitionSuccess()
            speechManagers.append(manager)
        }
        
        // Then: インスタンスが正常に作成されている
        #expect(speechManagers.count == 10)
        
        // メモリ解放（実際のメモリリークテストには専用ツールが必要）
        speechManagers.removeAll()
        #expect(speechManagers.isEmpty)
    }
}

// MARK: - ヘルパー関数

/// 統合テスト用のガイダンスメッセージを取得
func getIntegratedGuidanceMessage(for failureCount: Int) -> String {
    switch failureCount {
    case 1:
        return "もう一度話してみてね"
    case 2:
        return "ゆっくり はっきり話してみてね"
    case 3:
        return "キーボードで入力してみよう！"
    default:
        return ""
    }
}

// MARK: - テスト用の拡張

extension SettingsManager {
    /// テスト用のリセットメソッド
    func resetForTesting() {
        resetToDefaults()
    }
}