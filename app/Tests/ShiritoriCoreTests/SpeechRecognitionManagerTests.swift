import Testing
@testable import ShiritoriCore

@Suite("SpeechRecognitionManager Tests")
struct SpeechRecognitionManagerTests {
    
    @Test("SpeechRecognitionManager初期化テスト")
    func testSpeechRecognitionManagerInitialization() {
        // When
        let manager = SpeechRecognitionManager()
        
        // Then
        #expect(!manager.isRecording)
        #expect(!manager.isAvailable)
    }
    
    @Test("音声認識開始テスト - 許可なし")
    func testStartRecordingWithoutPermission() async {
        // Given
        let manager = SpeechRecognitionManager()
        
        // When
        await manager.startRecording { _ in }
        
        // Then: 許可がないため録音開始されない
        #expect(!manager.isRecording)
    }
    
    @Test("音声認識停止テスト")
    func testStopRecording() {
        // Given
        let manager = SpeechRecognitionManager()
        
        // When
        manager.stopRecording()
        
        // Then
        #expect(!manager.isRecording)
    }
    
    @Test("音声認識許可確認テスト")
    func testRequestSpeechPermission() async {
        // Given
        let manager = SpeechRecognitionManager()
        
        // When
        let hasPermission = await manager.requestSpeechPermission()
        
        // Then: テスト環境では許可が取得できない
        #expect(!hasPermission)
    }
    
    // MARK: - 失敗トラッキング機能のテスト
    
    @Test("連続失敗カウンター初期値テスト")
    func testConsecutiveFailureCountInitialization() {
        // Given & When
        let manager = SpeechRecognitionManager()
        
        // Then
        #expect(manager.consecutiveFailureCount == 0)
    }
    
    @Test("失敗カウンター増加テスト")
    func testIncrementFailureCount() {
        // Given
        let manager = SpeechRecognitionManager()
        
        // When
        manager.incrementFailureCount()
        manager.incrementFailureCount()
        
        // Then
        #expect(manager.consecutiveFailureCount == 2)
    }
    
    @Test("失敗カウンターリセットテスト")
    func testResetFailureCount() {
        // Given
        let manager = SpeechRecognitionManager()
        manager.incrementFailureCount()
        manager.incrementFailureCount()
        
        // When
        manager.resetFailureCount()
        
        // Then
        #expect(manager.consecutiveFailureCount == 0)
    }
    
    @Test("3回連続失敗検出テスト")
    func testThreeConsecutiveFailuresDetection() {
        // Given
        let manager = SpeechRecognitionManager()
        
        // When
        manager.incrementFailureCount()
        manager.incrementFailureCount()
        #expect(!manager.hasReachedFailureThreshold())
        
        manager.incrementFailureCount()
        
        // Then
        #expect(manager.hasReachedFailureThreshold())
    }
    
    @Test("音声認識成功時の失敗カウンターリセットテスト")
    func testFailureCountResetOnSuccess() {
        // Given
        let manager = SpeechRecognitionManager()
        manager.incrementFailureCount()
        manager.incrementFailureCount()
        
        // When
        manager.recordRecognitionSuccess()
        
        // Then
        #expect(manager.consecutiveFailureCount == 0)
    }
    
    @Test("失敗閾値カスタマイズテスト")
    func testCustomFailureThreshold() {
        // Given
        let manager = SpeechRecognitionManager()
        manager.setFailureThreshold(2) // 2回で閾値に達する設定
        
        // When
        manager.incrementFailureCount()
        #expect(!manager.hasReachedFailureThreshold())
        
        manager.incrementFailureCount()
        
        // Then
        #expect(manager.hasReachedFailureThreshold())
    }
}