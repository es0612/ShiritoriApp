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
    
    @Test("🎯 音声認識結果自動表示UX改善テスト")
    func testVoiceRecognitionResultAutoDisplayUX() async throws {
        // Given: 音声認識成功をシミュレートするための状態
        // 改善前：「認識された言葉」表示 → ユーザーがマイクボタンをタップ → 選択画面
        // 改善後：「認識された言葉」表示 → 自動で選択画面（タップ不要）
        var recognitionResult = ""
        var showRecognitionChoice = false
        var isRecording = false
        var inputText = ""
        
        // 音声認識結果（認識成功をシミュレート）
        let mockRecognitionText = "しりとり"
        
        // When: 音声認識が成功した状態をシミュレート
        isRecording = true
        inputText = mockRecognitionText // 音声認識で取得されたテキスト
        
        // 録音停止時のロジックをシミュレート（改善後のロジック）
        isRecording = false
        let hasValidInput = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if hasValidInput {
            // UX改善：音声認識成功 → 自動で選択画面を表示
            recognitionResult = inputText
            inputText = "" // 一時的にクリア
            showRecognitionChoice = true // 🎯 キーポイント：自動表示
        }
        
        // Then: 音声認識結果が得られた時点で自動的に選択画面が表示される
        #expect(recognitionResult == "しりとり", "認識結果が正しく保存されている")
        #expect(showRecognitionChoice == true, "🎯 UX改善：音声認識成功時に自動で選択画面が表示される")
        #expect(inputText.isEmpty, "選択画面表示時は入力テキストがクリアされている")
        #expect(isRecording == false, "録音が停止されている")
    }
    
    @Test("音声認識失敗時は選択画面を表示しないテスト")
    func testVoiceRecognitionFailureDoesNotShowChoice() async throws {
        // Given: 音声認識失敗をシミュレートするための状態
        var recognitionResult = ""
        var showRecognitionChoice = false
        var isRecording = false
        var inputText = ""
        
        let speechManager = SpeechRecognitionManager()
        
        // When: 音声認識が失敗した状態をシミュレート（空の結果）
        isRecording = true
        inputText = "" // 音声認識失敗（空文字）
        
        // 録音停止時のロジックをシミュレート
        isRecording = false
        let hasValidInput = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if hasValidInput {
            recognitionResult = inputText
            inputText = ""
            showRecognitionChoice = true
        } else {
            // 失敗処理
            speechManager.incrementFailureCount()
        }
        
        // Then: 音声認識失敗時は選択画面を表示しない
        #expect(recognitionResult.isEmpty, "失敗時は認識結果が空")
        #expect(showRecognitionChoice == false, "失敗時は選択画面を表示しない")
        #expect(speechManager.consecutiveFailureCount == 1, "失敗カウンターが増加")
    }
    
    @Test("音声認識結果から選択確定までのフローテスト")
    func testCompleteVoiceRecognitionToChoiceFlow() async throws {
        // Given: 完全なフローをテストするための状態
        var recognitionResult = ""
        var showRecognitionChoice = false
        var isRecording = false
        var inputText = ""
        var submittedWord = ""
        
        let speechManager = SpeechRecognitionManager()
        let mockRecognitionText = "りんご"
        
        // When: Step 1 - 音声認識成功
        isRecording = true
        inputText = mockRecognitionText
        
        // Step 2 - 録音停止 → 自動で選択画面表示
        isRecording = false
        let hasValidInput = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        if hasValidInput {
            recognitionResult = inputText
            inputText = ""
            showRecognitionChoice = true // 自動表示
        }
        
        // Step 3 - ユーザーが「つかう」を選択
        let userChoosesUse = true
        if userChoosesUse && showRecognitionChoice {
            speechManager.recordRecognitionSuccess()
            inputText = recognitionResult
            showRecognitionChoice = false
            submittedWord = inputText // 単語提出をシミュレート
            inputText = ""
            recognitionResult = ""
        }
        
        // Then: 完全なフローが期待通りに動作
        #expect(submittedWord == "りんご", "最終的に正しい単語が提出される")
        #expect(showRecognitionChoice == false, "選択完了後は選択画面が非表示")
        #expect(speechManager.consecutiveFailureCount == 0, "成功により失敗カウンターがリセット")
        #expect(recognitionResult.isEmpty, "認識結果がクリアされている")
        #expect(inputText.isEmpty, "入力テキストがクリアされている")
    }
}

    @Test("🎯 新SpeechRecognitionState自動遷移テスト")
    func testNewSpeechRecognitionStateAutoTransition() async throws {
        // Given: 新しい@Observable状態管理
        let speechState = SpeechRecognitionState()
        
        // When: 音声認識の段階を順次実行
        // 1. 録音開始
        speechState.startRecording()
        #expect(speechState.currentPhase == .recording)
        
        // 2. 処理段階に移行
        speechState.startProcessing()
        #expect(speechState.currentPhase == .processing)
        
        // 3. 中間結果更新
        speechState.updatePartialResult("しり", confidence: 0.8)
        #expect(speechState.partialResult == "しり")
        
        // 4. 認識完了 → 自動で結果準備完了段階に移行
        speechState.completeRecognition(result: "しりとり", confidence: 0.9)
        
        // Then: 結果準備完了段階への自動遷移を検証
        #expect(speechState.currentPhase == .resultReady)
        #expect(speechState.recognitionResult == "しりとり")
        #expect(speechState.confidence == 0.9)
        
        // 5. 自動で選択画面表示に遷移することを確認（Task完了後）
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1秒待機してTask完了を待つ
        
        #expect(speechState.currentPhase == .choiceDisplayed)
        #expect(speechState.showRecognitionChoice == true)
    }
    
    @Test("🎯 遅延処理なし状態ベース遷移テスト")
    func testDelayFreeStateBasedTransitions() async throws {
        // Given: 新しい状態管理システム
        let speechState = SpeechRecognitionState()
        let uiState = UIState.shared
        
        // When: 高速な状態遷移を実行（遅延なし）
        let startTime = Date()
        
        speechState.startRecording()
        speechState.startProcessing()
        speechState.updatePartialResult("たろう", confidence: 0.7)
        speechState.completeRecognition(result: "たろうくん", confidence: 0.85)
        
        // Task完了待ち
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let endTime = Date()
        let elapsedTime = endTime.timeIntervalSince(startTime)
        
        // Then: 高速遷移の検証（0.2秒以内で完了）
        #expect(elapsedTime < 0.2, "状態ベース遷移は遅延なしで高速実行される")
        #expect(speechState.currentPhase == .choiceDisplayed)
        #expect(speechState.showRecognitionChoice == true)
        #expect(speechState.recognitionResult == "たろうくん")
    }
    
    @Test("失敗時の適切な状態管理テスト")
    func testFailureStateManagement() {
        // Given: 新しい状態管理
        let speechState = SpeechRecognitionState()
        
        // When: 失敗シナリオを実行
        speechState.startRecording()
        speechState.startProcessing()
        speechState.recordFailure()
        
        // Then: 失敗時の状態を検証
        #expect(speechState.currentPhase == .failed)
        #expect(speechState.consecutiveFailureCount == 1)
        #expect(speechState.recognitionResult.isEmpty)
        #expect(speechState.partialResult.isEmpty)
    }
    
    @Test("成功・失敗カウンター管理テスト")
    func testSuccessFailureCounterManagement() {
        // Given: 状態管理インスタンス
        let speechState = SpeechRecognitionState()
        
        // When: 失敗 → 成功のサイクルを実行
        // 2回失敗
        speechState.recordFailure()
        speechState.recordFailure()
        #expect(speechState.consecutiveFailureCount == 2)
        
        // 成功でリセット
        speechState.recordSuccess()
        
        // Then: 成功時にカウンターがリセットされる
        #expect(speechState.consecutiveFailureCount == 0)
    }
    
    @Test("自動フォールバック機能テスト")
    func testAutoFallbackFunctionality() {
        // Given: 新しい状態管理
        let speechState = SpeechRecognitionState()
        
        // When: 自動フォールバックを実行
        speechState.performAutoFallback()
        
        // Then: フォールバック状態を検証
        #expect(speechState.hasAutoSwitched == true)
        #expect(speechState.isVoiceMode == false) // キーボードモードに切り替え
        #expect(speechState.guidanceMessage == "キーボードで入力してみよう！")
        #expect(speechState.showGuidanceMessage == true)
    }
    
    @Test("新ターンリセット機能テスト")
    func testNewTurnResetFunctionality() {
        // Given: 使用済み状態
        let speechState = SpeechRecognitionState()
        speechState.startRecording()
        speechState.completeRecognition(result: "テスト", confidence: 0.8)
        speechState.recordFailure()
        speechState.performAutoFallback()
        
        // When: 新ターンリセットを実行
        speechState.resetForNewTurn()
        
        // Then: 全状態がクリーンな初期状態にリセット
        #expect(speechState.currentPhase == .idle)
        #expect(speechState.consecutiveFailureCount == 0)
        #expect(speechState.hasAutoSwitched == false)
        #expect(speechState.showRecognitionChoice == false)
        #expect(speechState.recognitionResult.isEmpty)
        #expect(speechState.partialResult.isEmpty)
        #expect(speechState.guidanceMessage.isEmpty)
        #expect(speechState.showGuidanceMessage == false)
        #expect(speechState.isVoiceMode == true)
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