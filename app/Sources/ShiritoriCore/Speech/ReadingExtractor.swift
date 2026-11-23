import Foundation

/// 音声認識の結果から、しりとりの判定に使う「読み（ひらがな）」を取り出す。
///
/// 認識エンジンは「牛乳」「車」のように漢字で返すことがある。
/// 旧版はこの変換に700行以上の自前の辞書を持っていたが、OS の形態素解析で足りる。
public enum ReadingExtractor {
    /// 漢字・カタカナまじりの文字列を読み（ひらがな）にする。ひらがなにできなければ nil。
    public static func reading(of text: String) -> String? {
        let normalized = Kana.normalize(text)
        if Kana.isHiraganaWord(normalized) { return normalized }
        // 英字や数字が混ざった結果は読めないものとして扱う。
        // 下のローマ字 → ひらがな変換は「ABC」を「あぶく」にしてしまうので、先に弾く
        guard !normalized.isEmpty, normalized.unicodeScalars.allSatisfy(isKanaOrKanji) else { return nil }

        // 漢字を含む場合: 単語に区切り、各単語のローマ字読みをひらがなに直してつなぐ
        let cfText = normalized as CFString
        let tokenizer = CFStringTokenizerCreate(
            nil, cfText, CFRangeMake(0, CFStringGetLength(cfText)),
            kCFStringTokenizerUnitWordBoundary, Locale(identifier: "ja") as CFLocale
        )
        var result = ""
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            guard let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String else {
                return nil
            }
            let mutable = NSMutableString(string: latin)
            CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false)
            result += mutable as String
        }
        return Kana.isHiraganaWord(result) ? result : nil
    }

    private static func isKanaOrKanji(_ scalar: Unicode.Scalar) -> Bool {
        switch scalar.value {
        case 0x3041...0x3096, 0x30FC: true   // ひらがな、長音
        case 0x4E00...0x9FFF, 0x3005: true   // 漢字、繰り返し記号「々」
        default: false
        }
    }

    /// 認識の候補から、採用する1つを選ぶ。
    ///
    /// 次に使える文字で始まる候補を優先する。しりとりでは次の文字が決まっているので、
    /// 第1候補が聞き間違いでも、別候補に正しい言葉が入っていれば救える。
    /// 当てはまる候補が無ければ、読みが取れた最初の候補を返す（「○から だよ」と伝えるため）。
    public static func best(from candidates: [String], heads: [String]) -> (heard: String, reading: String)? {
        let readable = candidates.compactMap { candidate in
            reading(of: candidate).map { (heard: candidate, reading: $0) }
        }
        return readable.first { ShiritoriRules.starts($0.reading, withAnyOf: heads) } ?? readable.first
    }
}
