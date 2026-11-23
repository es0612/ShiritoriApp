import Foundation

/// 音声認識の結果から、しりとりの判定に使う「読み（ひらがな）」を取り出す。
///
/// 認識エンジンは「牛乳」「車」のように漢字で返すことがある。
/// 旧版はこの変換に700行以上の自前の辞書を持っていたが、OS の形態素解析で足りる。
public enum ReadingExtractor {
    /// OS の読みが、子供の言う読みと違う言葉の上書き。
    ///
    /// OS の形態素解析は「宝物」を「ほうもつ」、「明日」を「あす」と読む。正しく言った子供が
    /// 「『た』から だよ」と言われてしまうので、見つかったものをここに足していく。
    /// 足すときは `ReadingExtractorTests` にも同じ例を足すこと。
    private static let overrides: [String: String] = [
        "宝物": "たからもの", "腕時計": "うでどけい",
        "日曜日": "にちようび", "誕生日": "たんじょうび", "明日": "あした", "三日月": "みかづき",
        "お母さん": "おかあさん", "お父さん": "おとうさん",
    ]

    /// 漢字・カタカナまじりの文字列を読み（ひらがな）にする。ひらがなにできなければ nil。
    public static func reading(of text: String) -> String? {
        let normalized = Kana.normalize(text)
        if Kana.isHiraganaWord(normalized) { return normalized }
        // 英字や数字が混ざった結果は読めないものとして扱う。
        // 下のローマ字 → ひらがな変換は「ABC」を「あぶく」にしてしまうので、先に弾く
        guard !normalized.isEmpty, normalized.unicodeScalars.allSatisfy(isKanaOrKanji) else { return nil }
        if let known = overrides[normalized] { return known }

        // 漢字を含む場合: 単語に区切り、単語ごとに読みを決めてつなぐ
        let nsText = normalized as NSString
        let tokenizer = CFStringTokenizerCreate(
            nil, nsText, CFRangeMake(0, nsText.length),
            kCFStringTokenizerUnitWordBoundary, Locale(identifier: "ja") as CFLocale
        )
        var result = ""
        while !CFStringTokenizerAdvanceToNextToken(tokenizer).isEmpty {
            let range = CFStringTokenizerGetCurrentTokenRange(tokenizer)
            let token = nsText.substring(with: NSRange(location: range.location, length: range.length))
            if Kana.isHiraganaWord(token) {
                // かなの部分はそのまま使う。ローマ字を経由すると「こーひー」が「こおひい」に化ける
                result += token
            } else if let known = overrides[token] {
                result += known
            } else if let latin = CFStringTokenizerCopyCurrentTokenAttribute(tokenizer, kCFStringTokenizerAttributeLatinTranscription) as? String {
                let mutable = NSMutableString(string: latin)
                CFStringTransform(mutable, nil, kCFStringTransformLatinHiragana, false)
                result += mutable as String
            } else {
                return nil
            }
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
