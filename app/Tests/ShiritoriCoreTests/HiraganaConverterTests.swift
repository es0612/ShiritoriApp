import Testing
@testable import ShiritoriCore

@Suite("HiraganaConverter Tests")
struct HiraganaConverterTests {
    
    @Test("HiraganaConverter初期化テスト")
    func testHiraganaConverterInitialization() {
        // When
        let converter = HiraganaConverter()
        
        // Then: 初期化が成功すること
        #expect(converter != nil)
    }
    
    @Test("カタカナをひらがなに変換")
    func testKatakanaToHiraganaConversion() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then
        #expect(converter.convertToHiragana("リンゴ") == "りんご")
        #expect(converter.convertToHiragana("カタカナ") == "かたかな")
        #expect(converter.convertToHiragana("アリ") == "あり")
        #expect(converter.convertToHiragana("ネコ") == "ねこ")
    }
    
    @Test("ひらがなはそのまま")
    func testHiraganaStaysTheSame() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then
        #expect(converter.convertToHiragana("りんご") == "りんご")
        #expect(converter.convertToHiragana("あり") == "あり")
        #expect(converter.convertToHiragana("ねこ") == "ねこ")
    }
    
    @Test("混在文字列の変換")
    func testMixedCharacterConversion() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then
        #expect(converter.convertToHiragana("りんゴ") == "りんご")
        #expect(converter.convertToHiragana("アりがとう") == "ありがとう")
    }
    
    @Test("空文字と特殊文字")
    func testEmptyAndSpecialCharacters() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then
        #expect(converter.convertToHiragana("") == "")
        #expect(converter.convertToHiragana("123") == "123")
        #expect(converter.convertToHiragana("abc") == "abc")
    }
    
    @Test("漢字の読み仮名変換")
    func testKanjiToHiraganaConversion() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then
        #expect(converter.convertToHiragana("林檎") == "りんご")
        #expect(converter.convertToHiragana("猫") == "ねこ")
        #expect(converter.convertToHiragana("蟻") == "あり")
    }
    
    @Test("文字種混在の複雑な変換")
    func testComplexMixedConversion() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then
        #expect(converter.convertToHiragana("林檎ジュース") == "りんごじゅーす")
        #expect(converter.convertToHiragana("ネコの鳴き声") == "ねこのなきごえ")
    }
}