/// かな1文字・かな文字列の基本操作。
///
/// しりとりの判定は「読み（ひらがな）」で行うので、まずここで文字をそろえる。
public enum Kana {
    private static let longVowelMark: Character = "ー"

    /// 空白・句読点・記号を除き、カタカナをひらがなにする。長音「ー」は残す。
    ///
    /// OS の `applyingTransform(.hiraganaToKatakana, reverse: true)` は「ケーキ」を「けえき」に
    /// 変えてしまう（長音を母音に置き換える）ので、文字コードをずらして自前で変換する。
    public static func normalize(_ text: String) -> String {
        var result = String.UnicodeScalarView()
        for character in text where !character.isWhitespace && !character.isPunctuation && !character.isSymbol {
            for scalar in character.unicodeScalars {
                // カタカナ「ァ」〜「ヶ」は、ひらがなの 0x60 後ろに同じ並びで置かれている
                if (0x30A1...0x30F6).contains(scalar.value), let hiragana = Unicode.Scalar(scalar.value - 0x60) {
                    result.append(hiragana)
                } else {
                    result.append(scalar)
                }
            }
        }
        return String(result)
    }

    /// ひらがなと「ー」だけでできていて、空でないか。
    public static func isHiraganaWord(_ text: String) -> Bool {
        guard !text.isEmpty else { return false }
        return text.unicodeScalars.allSatisfy { (0x3041...0x3096).contains($0.value) || $0.value == 0x30FC }
    }

    private static let smallToLarge: [Character: Character] = [
        "ゃ": "や", "ゅ": "ゆ", "ょ": "よ", "っ": "つ",
        "ぁ": "あ", "ぃ": "い", "ぅ": "う", "ぇ": "え", "ぉ": "お", "ゎ": "わ",
    ]

    /// 小さい文字を大きい文字にする（ゃ→や、っ→つ）。それ以外はそのまま。
    public static func large(_ character: Character) -> Character {
        smallToLarge[character] ?? character
    }

    public static func isSmall(_ character: Character) -> Bool {
        smallToLarge[character] != nil
    }

    /// 段ごとの文字。長音「ー」で終わる言葉の「伸ばした母音」を求めるのに使う。
    private static let vowelRows: [(vowel: Character, members: String)] = [
        ("あ", "あかがさざただなはばぱまやらわぁゃゎ"),
        ("い", "いきぎしじちぢにひびぴみりぃ"),
        ("う", "うくぐすずつづぬふぶぷむゆるぅゅっゔ"),
        ("え", "えけげせぜてでねへべぺめれぇ"),
        ("お", "おこごそぞとどのほぼぽもよろをぉょ"),
    ]

    /// その文字の段の母音（か→あ、ぎ→い、ゅ→う）。「ん」「ー」やかな以外は nil。
    public static func vowel(of character: Character) -> Character? {
        vowelRows.first { $0.members.contains(character) }?.vowel
    }
}
