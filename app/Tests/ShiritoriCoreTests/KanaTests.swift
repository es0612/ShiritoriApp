import Testing
@testable import ShiritoriCore

@Suite struct KanaTests {
    @Test func normalize_convertsKatakanaAndStripsPunctuation() {
        #expect(Kana.normalize("ケーキ") == "けーき")
        #expect(Kana.normalize("りんご。") == "りんご")
        #expect(Kana.normalize(" ゴ リ ラ ") == "ごりら")
    }

    @Test func isHiraganaWord() {
        #expect(Kana.isHiraganaWord("けーき"))
        #expect(!Kana.isHiraganaWord(""))
        #expect(!Kana.isHiraganaWord("りんご1"))
        #expect(!Kana.isHiraganaWord("林檎"))
    }

    @Test func largeAndVowel() {
        #expect(Kana.large("ゃ") == "や")
        #expect(Kana.large("っ") == "つ")
        #expect(Kana.large("か") == "か")
        #expect(Kana.isSmall("ょ"))
        #expect(!Kana.isSmall("よ"))
        #expect(Kana.vowel(of: "か") == "あ")
        #expect(Kana.vowel(of: "ぎ") == "い")
        #expect(Kana.vowel(of: "ゅ") == "う")
        #expect(Kana.vowel(of: "ぽ") == "お")
        #expect(Kana.vowel(of: "ん") == nil)
        #expect(Kana.vowel(of: "ー") == nil)
    }
}
