import Testing
@testable import ShiritoriCore

/// 音声認識の結果（漢字・カタカナまじり）から読みを取る
@Suite struct ReadingExtractorTests {
    /// 入力は、聞き比べ試作（ビルド 43）で実機の音声認識が実際に返した文字列
    @Test(arguments: [
        ("りんご", "りんご"), ("ゴリラ", "ごりら"), ("ラッパ", "らっぱ"), ("パンダ", "ぱんだ"),
        ("牛乳", "ぎゅうにゅう"), ("うさぎ", "うさぎ"), ("キリン", "きりん"), ("車", "くるま"),
        ("ケーキ", "けーき"), ("新幹線", "しんかんせん"), ("猫", "ねこ"), ("おにぎり", "おにぎり"),
        ("りんご。", "りんご"),
    ])
    func reading(text: String, expected: String) {
        #expect(ReadingExtractor.reading(of: text) == expected)
    }

    /// OS の読みが、子供の言う読みと違う言葉（レビューで実際に変換して見つけたもの）
    @Test(arguments: [
        ("宝物", "たからもの"), ("腕時計", "うでどけい"),          // どちらも辞書にある言葉
        ("日曜日", "にちようび"), ("誕生日", "たんじょうび"), ("明日", "あした"), ("三日月", "みかづき"),
        ("お母さん", "おかあさん"), ("お父さん", "おとうさん"),
    ])
    func reading_usesChildFriendlyReading(text: String, expected: String) {
        #expect(ReadingExtractor.reading(of: text) == expected)
    }

    @Test func reading_keepsLongVowelMarkInKanaPartOfMixedWord() {
        // かなの部分はそのまま使う（ローマ字経由にすると「ー」が母音に化ける）
        #expect(ReadingExtractor.reading(of: "コーヒー牛乳") == "こーひーぎゅうにゅう")
    }

    @Test func reading_returnsNilForUnreadable() {
        #expect(ReadingExtractor.reading(of: "") == nil)
        #expect(ReadingExtractor.reading(of: "ABC") == nil)
        #expect(ReadingExtractor.reading(of: "123") == nil)
        #expect(ReadingExtractor.reading(of: "。") == nil)
    }

    @Test func best_prefersCandidateMatchingHead() {
        let result = ReadingExtractor.best(from: ["車", "ごま"], heads: ["ご"])
        #expect(result?.reading == "ごま")
        #expect(result?.heard == "ごま")
    }

    @Test func best_fallsBackToFirstReadable() {
        let result = ReadingExtractor.best(from: ["ABC", "車"], heads: ["ご"])
        #expect(result?.reading == "くるま")
        #expect(result?.heard == "車")
    }

    @Test func best_returnsNilWhenNothingReadable() {
        #expect(ReadingExtractor.best(from: [], heads: ["ご"]) == nil)
        #expect(ReadingExtractor.best(from: ["ABC"], heads: ["ご"]) == nil)
    }
}
