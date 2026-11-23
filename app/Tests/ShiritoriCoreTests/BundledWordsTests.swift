import Testing
@testable import ShiritoriCore

/// アプリに同梱する辞書が守るべき条件（設計書 §7）
@Suite struct BundledWordsTests {
    @Test func bundledWords_followTheRules() throws {
        let words = try WordBank.bundled().words
        #expect(words.count >= 240)
        #expect(Set(words.map(\.reading)).count == words.count, "重複がある")
        #expect(words.allSatisfy { Kana.isHiraganaWord($0.reading) }, "ひらがな以外が混ざっている")
        #expect(words.allSatisfy { !ShiritoriRules.endsWithN($0.reading) }, "「ん」で終わる語がある")
        #expect(words.allSatisfy { $0.reading.count >= 2 }, "1文字の語がある")
        #expect(!words.contains { $0.reading == "びーる" }, "子供向けでない語がある")
    }

    @Test func bundledWords_canAlwaysContinueFromTheirOwnEnding() throws {
        // アプリが出した言葉の次の文字を決められないと、あそびが止まる
        let words = try WordBank.bundled().words
        #expect(words.allSatisfy { !ShiritoriRules.nextHeads(after: $0.reading).isEmpty })
    }
}
