/// しりとりのルール。値を受け取って値を返すだけで、状態を持たない。
public enum ShiritoriRules {
    /// 「ぢ・づ・を」で終わる言葉は、同じ音の「じ・ず・お」から続けてもよい。
    private static let sameSound: [Character: Character] = ["ぢ": "じ", "づ": "ず", "を": "お"]

    /// その言葉のあとに使える「最初の文字」を返す（設計書 §5.4）。
    ///
    /// 家庭によってルールが分かれる所（長音・小さい文字）は、どれも受け入れる。
    /// 先頭の要素が、アプリが返事に使う候補。決められないとき（空文字や「ー」だけ）は空を返す。
    public static func nextHeads(after reading: String) -> [String] {
        var characters = Array(reading)
        var hadLongVowel = false
        while characters.last == "ー" {
            characters.removeLast()
            hadLongVowel = true
        }
        guard let last = characters.last else { return [] }

        var heads: [String] = []
        if Kana.isSmall(last) {
            heads.append(String(Kana.large(last)))
            // 拗音（しゃ・ちゅ・きょ）は、2文字ひとまとまりで始まる言葉も受け入れる（でんしゃ → しゃしん）
            if "ゃゅょ".contains(last), characters.count >= 2 {
                heads.append(String(characters[characters.count - 2]) + String(last))
            }
        } else {
            heads.append(String(last))
            if let same = sameSound[last] {
                heads.append(String(same))
            }
        }
        // 長音で終わる言葉は、伸ばした母音から続けてもよい（ぜりー → い）
        if hadLongVowel, let vowel = Kana.vowel(of: last) {
            heads.append(String(vowel))
        }

        // 順番を保ったまま重複を除く（例: 「あー」は あ が2回出る）
        var seen = Set<String>()
        return heads.filter { seen.insert($0).inserted }
    }

    /// 読みが、使える最初の文字のどれかで始まっているか。濁点・半濁点は区別する。
    public static func starts(_ reading: String, withAnyOf heads: [String]) -> Bool {
        heads.contains { reading.hasPrefix($0) }
    }

    /// 「ん」で終わるか。「ごはんー」のように伸ばして言っても「ん」で終わる言葉として扱う。
    public static func endsWithN(_ reading: String) -> Bool {
        reading.last { $0 != "ー" } == "ん"
    }
}

/// 子供の言葉に対する判定の結果（設計書 §5.3 の順1〜5）。
public enum Verdict: Equatable, Sendable {
    /// 順1: 読みが取れない（無音、英数字など、ひらがなにできない）
    case unreadable
    /// 順2: 最初の文字が合っていない。`expected` は「○から だよ」と伝える文字
    case wrongHead(expected: String)
    /// 順3: 「ん」で終わる
    case endsWithN
    /// 順4: このあそびで既に出た言葉
    case alreadyUsed
    /// 順5: 上のどれでもない。辞書にあるかどうかは問わない
    case accepted
}

extension ShiritoriRules {
    /// 子供の言葉を判定する。`reading` は正規化済みの読みで、取れなかったときは nil。
    ///
    /// 判定に辞書は使わない。アプリが知らない言葉を「間違い」にしないため。
    public static func judge(reading: String?, heads: [String], used: Set<String>) -> Verdict {
        guard let reading, Kana.isHiraganaWord(reading) else { return .unreadable }
        // 「ー」だけのように次の文字を決められない言葉は、受け入れると次の番が続けられない
        if !endsWithN(reading), nextHeads(after: reading).isEmpty { return .unreadable }
        guard starts(reading, withAnyOf: heads) else { return .wrongHead(expected: heads.first ?? "") }
        if endsWithN(reading) { return .endsWithN }
        if used.contains(reading) { return .alreadyUsed }
        return .accepted
    }
}
