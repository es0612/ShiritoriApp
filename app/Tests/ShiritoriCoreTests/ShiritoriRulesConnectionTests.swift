import Testing
@testable import ShiritoriCore

/// 文字のつなぎ方（設計書 §5.4）
@Suite struct ShiritoriRulesConnectionTests {
    @Test(arguments: [
        ("りんご", ["ご"]),
        ("ぜりー", ["り", "い"]),            // 長音: 伸ばす前の文字、または伸ばした母音
        ("でんしゃ", ["や", "しゃ"]),        // 小さい文字: 大きくした文字、または拗音ごと
        ("こーひー", ["ひ", "い"]),
        ("しちゅー", ["ゆ", "ちゅ", "う"]),
        ("らっこっ", ["つ"]),                // 小さい「っ」
        ("はなぢ", ["ぢ", "じ"]),
        ("かんづ", ["づ", "ず"]),
        ("を", ["を", "お"]),
        ("ぶた", ["た"]),
        ("め", ["め"]),
        ("ー", []),
        ("", []),
    ])
    func nextHeads(reading: String, expected: [String]) {
        #expect(ShiritoriRules.nextHeads(after: reading) == expected)
    }

    @Test func starts() {
        #expect(ShiritoriRules.starts("ごりら", withAnyOf: ["ご"]))
        #expect(ShiritoriRules.starts("しゃしん", withAnyOf: ["や", "しゃ"]))
        #expect(ShiritoriRules.starts("やま", withAnyOf: ["や", "しゃ"]))
        #expect(!ShiritoriRules.starts("だんご", withAnyOf: ["た"]))   // 濁点は区別する
        #expect(!ShiritoriRules.starts("ごりら", withAnyOf: []))
    }

    @Test func endsWithN() {
        #expect(ShiritoriRules.endsWithN("きりん"))
        #expect(!ShiritoriRules.endsWithN("りんご"))
        #expect(!ShiritoriRules.endsWithN(""))
    }
}
