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
}