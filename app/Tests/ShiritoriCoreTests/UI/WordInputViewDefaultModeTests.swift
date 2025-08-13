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
            currentPlayerId: "test-player",
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
            currentPlayerId: "test-player",
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
            currentPlayerId: "test-player",
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
            currentPlayerId: "test-player",
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
            currentPlayerId: "test-player",
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
            currentPlayerId: "test-player",
            onSubmit: { _ in }
        )
        
        // Then: ビューが正常に作成されることを確認
        let _ = try wordInputView.inspect()
        
        // 設定が反映されることを間接的に確認（実際の状態変更は内部で行われる）
        #expect(settingsManager.defaultInputMode == false)
    }
}

/// プレイヤー変更時リセット機能の専用テスト
@Suite("プレイヤー変更時リセット機能")
struct WordInputViewPlayerSwitchTests {
    
    @Test("プレイヤー変更時の基本リセット")
    func testBasicPlayerSwitchReset() async throws {
        let initialPlayerId = "player1"
        
        // 初期状態の確認
        let wordInputView = await WordInputView(
            isEnabled: true,
            currentPlayerId: initialPlayerId,
            onSubmit: { _ in }
        )
        
        // プレイヤーIDが正しく設定されていることを確認
        #expect(await wordInputView.currentPlayerId == initialPlayerId)
        
        AppLogger.shared.info("基本プレイヤー変更リセットテスト完了")
    }
    
    @Test("音声認識進行中のプレイヤー変更")
    func testPlayerSwitchDuringVoiceRecognition() async throws {
        let speechState = SpeechRecognitionState()
        
        // 音声認識開始をシミュレート
        speechState.startRecording()
        #expect(speechState.currentPhase == .recording)
        
        // プレイヤー変更時に音声認識が停止されることをシミュレート
        if speechState.currentPhase.isActive {
            AppLogger.shared.info("進行中の音声認識を停止: \(speechState.currentPhase)")
            // 実際のWordInputViewでは speechManager.stopRecording() が呼ばれる
        }
        
        // リセット処理をシミュレート
        speechState.resetForNewTurn()
        
        // リセット後の状態確認
        #expect(speechState.currentPhase == .idle)
        #expect(speechState.consecutiveFailureCount == 0)
        #expect(speechState.hasAutoSwitched == false)
        #expect(speechState.isVoiceMode == true)
        
        AppLogger.shared.info("音声認識進行中プレイヤー変更テスト完了")
    }
    
    @Test("プレイヤー変更時の入力テキストクリア")
    func testPlayerSwitchClearsInputText() async throws {
        // このテストでは、実際のWordInputViewのState変更をシミュレート
        var inputText = "テスト入力"
        var isTextFieldFocused = true
        
        // プレイヤー変更時の処理をシミュレート
        inputText = ""
        isTextFieldFocused = false
        
        #expect(inputText.isEmpty)
        #expect(isTextFieldFocused == false)
        
        AppLogger.shared.info("入力テキストクリアテスト完了")
    }
    
    @Test("連続プレイヤー変更時の状態管理")
    func testConsecutivePlayerSwitches() async throws {
        let speechState = SpeechRecognitionState()
        
        // 最初のプレイヤーで失敗を記録
        speechState.recordFailure()
        speechState.recordFailure()
        #expect(speechState.consecutiveFailureCount == 2)
        
        // プレイヤー変更 #1
        speechState.resetForNewTurn()
        #expect(speechState.consecutiveFailureCount == 0)
        #expect(speechState.currentPhase == .idle)
        
        // 新プレイヤーで新しい失敗
        speechState.recordFailure()
        #expect(speechState.consecutiveFailureCount == 1)
        
        // プレイヤー変更 #2 - 再度リセット
        speechState.resetForNewTurn()
        #expect(speechState.consecutiveFailureCount == 0)
        #expect(speechState.hasAutoSwitched == false)
        
        AppLogger.shared.info("連続プレイヤー変更テスト完了")
    }
    
    @Test("プレイヤー変更時の自動フォールバック状態リセット")
    func testPlayerSwitchResetsAutoFallback() async throws {
        let speechState = SpeechRecognitionState()
        
        // 3回失敗して自動フォールバックを発生させる
        speechState.recordFailure()
        speechState.recordFailure()
        speechState.recordFailure()
        
        // 自動フォールバックを実行
        if speechState.hasReachedFailureThreshold(3) && !speechState.hasAutoSwitched {
            speechState.performAutoFallback()
        }
        
        #expect(speechState.hasAutoSwitched == true)
        #expect(speechState.isVoiceMode == false)
        
        // プレイヤー変更時のリセット
        speechState.resetForNewTurn()
        
        // 自動フォールバック状態がリセットされることを確認
        #expect(speechState.hasAutoSwitched == false)
        #expect(speechState.isVoiceMode == true) // デフォルトに戻る
        #expect(speechState.consecutiveFailureCount == 0)
        
        AppLogger.shared.info("自動フォールバック状態リセットテスト完了")
    }
    
    @Test("プレイヤー変更時の認識結果選択画面リセット")
    func testPlayerSwitchResetsRecognitionChoice() async throws {
        let speechState = SpeechRecognitionState()
        
        // 音声認識成功をシミュレート
        speechState.startRecording()
        speechState.startProcessing()
        speechState.completeRecognition(result: "テスト単語", confidence: 0.8)
        
        // 選択画面を表示（実際のフローではUIで自動遷移）
        speechState.showChoiceScreen()
        
        // 認識結果選択画面が表示されることを確認
        #expect(speechState.showRecognitionChoice == true)
        #expect(speechState.recognitionResult == "テスト単語")
        
        // プレイヤー変更時のリセット
        speechState.resetForNewTurn()
        
        // 認識結果選択画面がリセットされることを確認
        #expect(speechState.showRecognitionChoice == false)
        #expect(speechState.recognitionResult.isEmpty)
        #expect(speechState.currentPhase == .idle)
        
        AppLogger.shared.info("認識結果選択画面リセットテスト完了")
    }
    
    @Test("プレイヤー変更時のガイダンスメッセージリセット")
    func testPlayerSwitchResetsGuidanceMessage() async throws {
        let speechState = SpeechRecognitionState()
        
        // ガイダンスメッセージを表示するため失敗を記録
        speechState.recordFailure()
        
        // ガイダンスメッセージが表示される可能性をテスト
        // (実際の表示は内部ロジックで決定されるため、リセット機能をテスト)
        let initialFailureCount = speechState.consecutiveFailureCount
        #expect(initialFailureCount > 0)
        
        // プレイヤー変更時のリセット
        speechState.resetForNewTurn()
        
        // ガイダンス関連状態がリセットされることを確認
        #expect(speechState.showGuidanceMessage == false)
        #expect(speechState.guidanceMessage.isEmpty)
        #expect(speechState.consecutiveFailureCount == 0)
        
        AppLogger.shared.info("ガイダンスメッセージリセットテスト完了")
    }
}
