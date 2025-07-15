import Testing
@testable import ShiritoriCore

@Suite("WordValidator Tests")
struct WordValidatorTests {
    
    @Test("WordValidator初期化テスト")
    func testWordValidatorInitialization() {
        // When
        let validator = WordValidator()
        
        // Then: 初期化が成功すること
        #expect(validator != nil)
    }
    
    @Test("有効な単語")
    func testValidWords() {
        // Given
        let validator = WordValidator()
        
        // When & Then: 有効な単語は通る
        #expect(validator.isValidWord("りんご") == true)
        #expect(validator.isValidWord("ねこ") == true)
        #expect(validator.isValidWord("あり") == true)
        #expect(validator.isValidWord("かがみ") == true)
    }
    
    @Test("意味のない繰り返し文字の無効判定")
    func testInvalidRepeatWords() {
        // Given
        let validator = WordValidator()
        
        // When & Then: 意味のない繰り返しは無効
        #expect(validator.isValidWord("るるるる") == false)
        #expect(validator.isValidWord("ああああ") == false)
        #expect(validator.isValidWord("かかかか") == false)
        #expect(validator.isValidWord("ににににに") == false)
    }
    
    @Test("短すぎる単語の無効判定")
    func testTooShortWords() {
        // Given
        let validator = WordValidator()
        
        // When & Then: 1文字は無効
        #expect(validator.isValidWord("あ") == false)
        #expect(validator.isValidWord("か") == false)
        #expect(validator.isValidWord("") == false)
    }
    
    @Test("無効なパターンの判定")
    func testInvalidPatterns() {
        // Given
        let validator = WordValidator()
        
        // When & Then: 無効なパターン
        #expect(validator.isValidWord("ううううう") == false)  // 同じ音の繰り返し
        #expect(validator.isValidWord("つつつつ") == false)    // 同じ音の繰り返し
        #expect(validator.isValidWord("をををを") == false)    // 助詞の繰り返し
    }
    
    @Test("有効な長い単語")
    func testValidLongWords() {
        // Given
        let validator = WordValidator()
        
        // When & Then: 有効な長い単語は通る
        #expect(validator.isValidWord("はくぶつかん") == true)
        #expect(validator.isValidWord("ゆうえんち") == true)
        #expect(validator.isValidWord("じどうしゃ") == true)
    }
    
    @Test("境界条件のテスト")
    func testBoundaryConditions() {
        // Given
        let validator = WordValidator()
        
        // When & Then: 境界条件
        #expect(validator.isValidWord("りり") == false)      // 2文字の繰り返し
        #expect(validator.isValidWord("りす") == true)       // 2文字の有効な単語
        #expect(validator.isValidWord("りりり") == false)    // 3文字の繰り返し
        #expect(validator.isValidWord("りんご") == true)     // 3文字の有効な単語
    }
}