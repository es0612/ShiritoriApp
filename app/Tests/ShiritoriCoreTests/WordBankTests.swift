import Testing
@testable import ShiritoriCore

/// アプリの言葉選び（設計書 §5.6）
@Suite struct WordBankTests {
    /// 「ら」で始まる言葉が6語あるので、「ら」で終わる言葉は行き止まりにならない。
    /// 「る」で始まる言葉は1語だけなので、「る」で終わる言葉は行き止まり。
    let bank = WordBank(words: [
        "ごりら", "ごーる",
        "らっぱ", "らくだ", "らじお", "らっこ", "らいす", "らけっと",
        "るびー",
        "やま", "やぎ", "しゃつ",
    ].map { Word(reading: $0, emoji: nil) })

    @Test func pick_returnsUnusedWordStartingWithFirstHead() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<30 {
            let word = bank.pick(heads: ["や", "しゃ"], used: [], using: &rng)
            #expect(word?.reading.hasPrefix("や") == true)
        }
    }

    @Test func pick_skipsUsed() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<30 {
            #expect(bank.pick(heads: ["や"], used: ["やま"], using: &rng)?.reading == "やぎ")
        }
    }

    @Test func pick_returnsNilWhenNoCandidate() {
        var rng = SeededGenerator(seed: 1)
        #expect(bank.pick(heads: ["ぬ"], used: [], using: &rng) == nil)
        #expect(bank.pick(heads: ["や"], used: ["やま", "やぎ"], using: &rng) == nil)
        #expect(bank.pick(heads: [], used: [], using: &rng) == nil)
    }

    @Test func pick_avoidsDeadEndWhenAlternativeExists() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<50 {
            #expect(bank.pick(heads: ["ご"], used: [], using: &rng)?.reading == "ごりら")
        }
    }

    @Test func pick_returnsDeadEndWhenOnlyChoice() {
        var rng = SeededGenerator(seed: 1)
        #expect(bank.pick(heads: ["ご"], used: ["ごりら"], using: &rng)?.reading == "ごーる")
    }

    @Test func pickAny_avoidsDeadEndWhenAlternativeExists() {
        var rng = SeededGenerator(seed: 1)
        for _ in 0..<50 {
            // 行き止まりでないのは「ごりら」だけ
            #expect(bank.pickAny(used: [], using: &rng)?.reading == "ごりら")
        }
    }

    @Test func pickAny_returnsNilWhenAllUsed() {
        var rng = SeededGenerator(seed: 1)
        let all = Set(bank.words.map(\.reading))
        #expect(bank.pickAny(used: all, using: &rng) == nil)
    }

    @Test func hints_matchAnyHead() {
        #expect(Set(bank.hints(for: ["や", "しゃ"])) == ["やま", "やぎ", "しゃつ"])
        #expect(bank.hints(for: []).isEmpty)
    }

    @Test func hints_capAt100() {
        let big = WordBank(words: (1...150).map { Word(reading: "あ" + String(repeating: "い", count: $0), emoji: nil) })
        #expect(big.hints(for: ["あ"]).count == 100)
    }
}
