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

    public static func endsWithN(_ reading: String) -> Bool {
        reading.last == "ん"
    }
}
