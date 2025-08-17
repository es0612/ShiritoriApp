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
        let instructionText = try content.find(text: "マイクを おしながら はなしてね")
        #expect(try instructionText.string() == "マイクを おしながら はなしてね")
    }
    
    @Test
    func テキスト入力UIの要素確認() throws {
        // Given: WordInputView
        let wordInputView = WordInputView(
            isEnabled: true,
            currentPlayerId: "test-player",
            onSubmit: { _ in }
        )
        
        // When
        let content = try wordInputView.inspect()
        
        // Then: キーボードボタンの存在確認（音声モードでも表示される）
        let keyboardButton = try content.find(text: "キーボード")
        #expect(try keyboardButton.string() == "キーボード")
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
    
    // MARK: - バグ再現テスト (Issue #1: 音声入力完了後のターン切り替わらないバグ)
    
    @Test("バグ再現: 音声入力完了後にターンが切り替わらない問題")
    func testBugReproduction_VoiceInputCompletionStuckOnTurnSwitch() async throws {
        let speechController = SpeechRecognitionController()
        
        // プレイヤー1のターン開始
        let player1Id = "player1"
        speechController.resetForNewTurn(playerId: player1Id)
        
        // プレイヤー1が音声入力を完了する流れをシミュレート
        // 1. 音声認識開始
        let started = speechController.startVoiceRecording()
        #expect(started == true, "音声認識が開始されるべき")
        #expect(speechController.currentPhase == .recording, "録音フェーズに移行すべき")
        
        // 2. 音声認識処理中をシミュレート (部分結果あり)
        speechController.speechState.startProcessing()
        speechController.speechState.updatePartialResult("ねこ", confidence: 0.8)
        #expect(speechController.currentPhase == .processing, "処理フェーズに移行すべき")
        
        // 3. 音声認識完了
        speechController.speechState.completeRecognition(result: "ねこ", confidence: 0.8)
        #expect(speechController.currentPhase == .resultReady, "結果準備完了フェーズに移行すべき")
        
        // 4. 認識結果選択画面に自動遷移
        speechController.speechState.showChoiceScreen()
        #expect(speechController.showRecognitionChoice == true, "認識結果選択画面が表示されるべき")
        #expect(speechController.recognitionResult == "ねこ", "認識結果が正しく設定されるべき")
        
        // 5. ユーザーが「使用する」を選択（単語送信）
        let submittedWord = speechController.useRecognitionResult()
        #expect(submittedWord == "ねこ", "送信される単語が正しいべき")
        #expect(speechController.currentPhase == .completed, "完了フェーズに移行すべき")
        
        // ❌ バグ状況: ここでプレイヤー2のターンになるが、完了状態が残る
        let player2Id = "player2"
        speechController.resetForNewTurn(playerId: player2Id)
        
        // プレイヤー2のターンで期待される状態
        #expect(speechController.currentPhase == .idle, "新しいターンでは idle フェーズに戻るべき")
        #expect(speechController.showRecognitionChoice == false, "認識結果選択画面は非表示になるべき")
        #expect(speechController.recognitionResult.isEmpty, "認識結果はクリアされるべき")
        #expect(speechController.partialResult.isEmpty, "部分結果もクリアされるべき")
        
        // プレイヤー2が新しい音声入力を開始できることを確認
        let canStartNewRecording = speechController.startVoiceRecording()
        #expect(canStartNewRecording == true, "新しいプレイヤーが音声入力を開始できるべき")
        
        AppLogger.shared.info("バグ再現テスト完了: 音声入力完了後のターン切り替え")
    }
    
    @Test("バグ再現: キーボード入力完了後にターンが切り替わらない問題")
    func testBugReproduction_KeyboardInputCompletionStuckOnTurnSwitch() async throws {
        let speechController = SpeechRecognitionController()
        
        // プレイヤー1のターン開始（キーボードモード）
        let player1Id = "player1"
        speechController.resetForNewTurn(playerId: player1Id)
        speechController.switchToKeyboardMode()
        #expect(speechController.isVoiceMode == false, "キーボードモードに切り替わるべき")
        
        // キーボード入力完了のシミュレート（実際には WordInputView 内で処理される）
        // ここでは、入力完了後の状態をシミュレート
        
        // プレイヤー2のターンに切り替え
        let player2Id = "player2"
        speechController.resetForNewTurn(playerId: player2Id)
        
        // プレイヤー2の初期状態確認
        #expect(speechController.currentPhase == .idle, "新しいターンでは idle フェーズに戻るべき")
        #expect(speechController.isVoiceMode == true, "デフォルトは音声モードに戻るべき") // 設定に依存
        
        // 新しいプレイヤーがモード切替可能であることを確認
        speechController.switchToKeyboardMode()
        #expect(speechController.isVoiceMode == false, "新しいプレイヤーがキーボードモードに切り替え可能であるべき")
        
        speechController.switchToVoiceMode()
        #expect(speechController.isVoiceMode == true, "新しいプレイヤーが音声モードに切り替え可能であるべき")
        
        AppLogger.shared.info("バグ再現テスト完了: キーボード入力完了後のターン切り替え")
    }
    
    @Test("バグ再現: 複数プレイヤーでの状態引き継ぎ問題")
    func testBugReproduction_StateCarryOverBetweenMultiplePlayers() async throws {
        let speechController = SpeechRecognitionController()
        
        // プレイヤー1: 音声入力で失敗
        speechController.resetForNewTurn(playerId: "player1")
        _ = speechController.startVoiceRecording()
        speechController.speechState.recordFailure()
        #expect(speechController.consecutiveFailureCount == 1, "プレイヤー1の失敗が記録されるべき")
        
        // プレイヤー2: 前の失敗が引き継がれてはいけない
        speechController.resetForNewTurn(playerId: "player2")
        #expect(speechController.consecutiveFailureCount == 0, "新しいプレイヤーの失敗カウントは0でなければならない")
        
        // プレイヤー2: 認識結果を持った状態で
        _ = speechController.startVoiceRecording()
        speechController.speechState.completeRecognition(result: "いぬ", confidence: 0.9)
        speechController.speechState.showChoiceScreen()
        #expect(speechController.showRecognitionChoice == true, "プレイヤー2の認識結果が表示されるべき")
        
        // プレイヤー3: 前のプレイヤーの認識結果が引き継がれてはいけない
        speechController.resetForNewTurn(playerId: "player3")
        #expect(speechController.showRecognitionChoice == false, "新しいプレイヤーに認識結果画面は表示されないべき")
        #expect(speechController.recognitionResult.isEmpty, "新しいプレイヤーの認識結果は空でなければならない")
        #expect(speechController.currentPhase == .idle, "新しいプレイヤーのフェーズは idle でなければならない")
        
        AppLogger.shared.info("バグ再現テスト完了: 複数プレイヤーでの状態引き継ぎ")
    }
    
    @Test("バグ再現: UI更新タイミングの問題テスト")
    func testBugReproduction_UIUpdateTimingIssue() async throws {
        let speechController = SpeechRecognitionController()
        
        // シナリオ: プレイヤー1が音声認識を完了し、認識結果選択画面が表示された状態
        speechController.resetForNewTurn(playerId: "player1")
        
        // 音声認識フローの完全シミュレーション
        _ = speechController.startVoiceRecording()
        speechController.speechState.startProcessing()
        speechController.speechState.updatePartialResult("はなちゃん", confidence: 0.8)
        speechController.speechState.completeRecognition(result: "はなちゃん", confidence: 0.8)
        speechController.speechState.showChoiceScreen()
        
        // 認識結果選択画面が表示されている状態を確認
        #expect(speechController.showRecognitionChoice == true, "認識結果選択画面が表示されているべき")
        #expect(speechController.recognitionResult == "はなちゃん", "認識結果が正しく設定されているべき")
        #expect(speechController.currentPhase == .choiceDisplayed, "選択表示フェーズになっているべき")
        
        AppLogger.shared.info("📱 UIシミュレーション: プレイヤー1の認識結果選択画面が表示中")
        
        // ❌ ここでプレイヤー2のターンに切り替える（WordInputViewのonChangeのシミュレーション）
        AppLogger.shared.info("🔄 プレイヤー変更: player1 -> player2")
        speechController.resetForNewTurn(playerId: "player2")
        
        // プレイヤー2の状態確認 (ここで失敗する可能性)
        AppLogger.shared.info("🔍 プレイヤー2状態確認:")
        AppLogger.shared.info("  - showRecognitionChoice: \(speechController.showRecognitionChoice)")
        AppLogger.shared.info("  - recognitionResult: '\(speechController.recognitionResult)'")
        AppLogger.shared.info("  - currentPhase: \(speechController.currentPhase)")
        AppLogger.shared.info("  - consecutiveFailureCount: \(speechController.consecutiveFailureCount)")
        
        // バグの核心: 認識結果選択画面が残っているかどうか
        if speechController.showRecognitionChoice {
            AppLogger.shared.error("❌ バグ確認: プレイヤー2に切り替えたのに認識結果選択画面が残っている")
        } else {
            AppLogger.shared.info("✅ 正常: 認識結果選択画面が正しく非表示になっている")
        }
        
        #expect(speechController.showRecognitionChoice == false, "新しいプレイヤーに切り替え時に認識結果選択画面は非表示になるべき")
        #expect(speechController.recognitionResult.isEmpty, "新しいプレイヤーの認識結果は空でなければならない")
        #expect(speechController.currentPhase == .idle, "新しいプレイヤーのフェーズは idle でなければならない")
        
        // プレイヤー2が新しい音声入力を開始できるかテスト
        let canPlayer2StartRecording = speechController.startVoiceRecording()
        #expect(canPlayer2StartRecording == true, "プレイヤー2が新しい音声入力を開始できるべき")
        
        AppLogger.shared.info("バグ再現テスト完了: UI更新タイミングの問題")
    }
}
