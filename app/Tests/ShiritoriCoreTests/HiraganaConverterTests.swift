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
    
    @Test("海関連の漢字変換（現在失敗するテスト）")
    func testSeaRelatedKanjiConversion() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then: これらのテストは現在失敗することが期待される
        #expect(converter.convertToHiragana("貝殻") == "かいがら")
        #expect(converter.convertToHiragana("海藻") == "かいそう")
        #expect(converter.convertToHiragana("海星") == "ひとで")
        #expect(converter.convertToHiragana("海月") == "くらげ")
        #expect(converter.convertToHiragana("貝") == "かい")
        #expect(converter.convertToHiragana("殻") == "から")
    }
    
    @Test("しりとりでよく使われる漢字単語の変換")
    func testCommonShiritoriKanjiWords() {
        // Given
        let converter = HiraganaConverter()
        
        // When & Then: これらのテストは現在失敗することが期待される
        #expect(converter.convertToHiragana("象") == "ぞう")
        #expect(converter.convertToHiragana("梅") == "うめ")
        #expect(converter.convertToHiragana("桜") == "さくら")
        #expect(converter.convertToHiragana("雨") == "あめ")
        #expect(converter.convertToHiragana("雪") == "ゆき")
        #expect(converter.convertToHiragana("星") == "ほし")
        #expect(converter.convertToHiragana("月") == "つき")
        #expect(converter.convertToHiragana("太陽") == "たいよう")
        #expect(converter.convertToHiragana("海") == "うみ")
        #expect(converter.convertToHiragana("山") == "やま")
        #expect(converter.convertToHiragana("川") == "かわ")
        #expect(converter.convertToHiragana("森") == "もり")
        #expect(converter.convertToHiragana("花") == "はな")
        #expect(converter.convertToHiragana("鳥") == "とり")
        #expect(converter.convertToHiragana("魚") == "さかな")
    }
}