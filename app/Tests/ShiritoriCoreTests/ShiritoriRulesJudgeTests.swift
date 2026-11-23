import Testing
@testable import ShiritoriCore

/// 判定（設計書 §5.3）。上から順に当てはめる。
@Suite struct ShiritoriRulesJudgeTests {
    let heads = ["ご"]
    let used: Set<String> = ["ごま"]

    private func judge(_ reading: String?) -> Verdict {
        ShiritoriRules.judge(reading: reading, heads: heads, used: used)
    }

    @Test func unreadable_whenNoReading() {
        #expect(judge(nil) == .unreadable)
        #expect(judge("") == .unreadable)
        #expect(judge("ごりら1") == .unreadable)
    }

    @Test func unreadable_whenNextHeadCannotBeDecided() {
        #expect(judge("ー") == .unreadable)
    }

    @Test func wrongHead_reportsTheHeadToUse() {
        #expect(judge("らっぱ") == .wrongHead(expected: "ご"))
    }

    @Test func endsWithN() {
        #expect(judge("ごはん") == .endsWithN)
    }

    @Test func endsWithN_evenWhenStretched() {
        // 「ごはんー」と伸ばして言っても「ん」で終わる言葉として扱う
        #expect(judge("ごはんー") == .endsWithN)
    }

    @Test func alreadyUsed() {
        #expect(judge("ごま") == .alreadyUsed)
    }

    @Test func accepted_evenIfNotInAnyDictionary() {
        #expect(judge("ごりら") == .accepted)
        #expect(judge("ごにょごにょ") == .accepted)
    }

    @Test func accepted_singleCharacterWord() {
        #expect(judge("ご") == .accepted)
    }

    @Test func wrongHead_isCheckedBeforeEndsWithN() {
        #expect(judge("ぱんつくったん") == .wrongHead(expected: "ご"))
    }
}
