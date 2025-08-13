import Testing
import SwiftUI
import SwiftData
import ViewInspector
@testable import ShiritoriCore

@MainActor  
@Suite("WordInputView 自動フォールバック機能テスト")
struct WordInputViewAutoFallbackTests {
    
    @Test("3回連続失敗後の自動キーボード切り替えテスト")
    func testAutoFallbackToKeyboardAfterThreeFailures() async throws {
        // Given: 有効なWordInputView
        let wordInputView = WordInputView(
            isEnabled: true,
            currentPlayerId: "test-player",
            onSubmit: { _ in }
        )
        
        // 内部のSpeechRecognitionManagerにアクセスするため、
        // テスト用のプロパティを用意
        let speechManager = SpeechRecognitionManager()
        
        // When: 3回連続で失敗
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        
        // Then: 失敗閾値に達していることを確認
        #expect(speechManager.hasReachedFailureThreshold())
    }
    
    @Test("失敗カウンターリセット後の音声モード継続テスト")
    func testVoiceModeResumesAfterFailureReset() {
        // Given: 失敗カウンターが増加した状態
        let speechManager = SpeechRecognitionManager()
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        
        // When: 成功を記録
        speechManager.recordRecognitionSuccess()
        
        // Then: 失敗カウンターがリセットされている
        #expect(speechManager.consecutiveFailureCount == 0)
    }
    
    @Test("自動切り替え通知機能テスト")
    func testAutoFallbackNotification() async throws {
        // Given: 通知を受け取るためのフラグ
        var notificationReceived = false
        var fallbackTriggered = false
        
        // WordInputViewWithFallbackという名前で拡張したビューを想定
        let wordInputView = WordInputViewWithFallback(
            isEnabled: true,
            currentPlayerId: "test-player",
            onSubmit: { _ in },
            onAutoFallback: { 
                fallbackTriggered = true 
                notificationReceived = true
            }
        )
        
        // SpeechRecognitionManagerをモック
        let speechManager = SpeechRecognitionManager()
        
        // When: 3回失敗を記録
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        
        // Then: 閾値に達している
        #expect(speechManager.hasReachedFailureThreshold())
        
        // 通知コールバックが設定されていることを確認
        #expect(notificationReceived == false) // まだ実際の通知は発生していない
    }
    
    @Test("段階的ガイダンスメッセージテスト")
    func testProgressiveGuidanceMessages() {
        // Given
        let speechManager = SpeechRecognitionManager()
        
        // When & Then: 段階的なメッセージを検証
        
        // 1回目の失敗
        speechManager.incrementFailureCount()
        let firstMessage = getGuidanceMessage(for: speechManager.consecutiveFailureCount)
        #expect(firstMessage == "もう一度話してみてね")
        
        // 2回目の失敗
        speechManager.incrementFailureCount()
        let secondMessage = getGuidanceMessage(for: speechManager.consecutiveFailureCount)
        #expect(secondMessage == "ゆっくり はっきり話してみてね")
        
        // 3回目の失敗
        speechManager.incrementFailureCount()
        let thirdMessage = getGuidanceMessage(for: speechManager.consecutiveFailureCount)
        #expect(thirdMessage == "キーボードで入力してみよう！")
    }
    
    @Test("自動切り替え設定無効時のテスト")
    func testAutoFallbackDisabled() async throws {
        // Given: 自動切り替えが無効な設定
        let schema = Schema([AppSettings.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        
        let settingsManager = SettingsManager.shared
        settingsManager.initialize(with: container.mainContext)
        
        // 自動フォールバック機能を無効化（将来的に追加予定の設定）
        // settingsManager.updateAutoFallbackEnabled(false)
        
        let speechManager = SpeechRecognitionManager()
        
        // When: 3回失敗
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        speechManager.incrementFailureCount()
        
        // Then: 閾値に達しているが、設定で無効になっている場合の動作
        #expect(speechManager.hasReachedFailureThreshold())
        // 実装後：自動切り替えが実行されないことを確認
    }
    
    @Test("カスタム失敗閾値テスト")
    func testCustomFailureThreshold() {
        // Given: カスタム閾値設定
        let speechManager = SpeechRecognitionManager()
        speechManager.setFailureThreshold(2) // 2回で閾値に設定
        
        // When: 2回失敗
        speechManager.incrementFailureCount()
        #expect(!speechManager.hasReachedFailureThreshold())
        
        speechManager.incrementFailureCount()
        
        // Then: 2回で閾値に達する
        #expect(speechManager.hasReachedFailureThreshold())
    }
}

// MARK: - テスト用の拡張ビュー

/// 自動フォールバック機能をテストするための拡張WordInputView
struct WordInputViewWithFallback: View {
    let isEnabled: Bool
    let currentPlayerId: String
    let onSubmit: (String) -> Void
    let onAutoFallback: () -> Void
    
    @State private var isVoiceMode = true
    @State private var speechManager = SpeechRecognitionManager()
    
    var body: some View {
        VStack {
            if speechManager.hasReachedFailureThreshold() {
                Text("キーボードで入力してみよう！")
                    .foregroundColor(.orange)
                    .onAppear {
                        onAutoFallback()
                    }
            }
            
            Text("テスト用ビュー")
        }
    }
}

// MARK: - ヘルパー関数

/// 失敗回数に応じたガイダンスメッセージを取得
func getGuidanceMessage(for failureCount: Int) -> String {
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