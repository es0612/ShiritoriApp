import Foundation

/// しりとり専用の単語正規化クラス
/// 長音符「ー」や拗音「ょ」「ゅ」「っ」などをしりとりに適した形に変換する
public class ShiritoriWordNormalizer {
    
    public init() {
        AppLogger.shared.debug("ShiritoriWordNormalizer初期化")
    }
    
    /// 単語をしりとり用に正規化する
    /// - Parameter word: 正規化する単語
    /// - Returns: しりとりに適した形に正規化された単語
    public func normalizeForShiritori(_ word: String) -> String {
        AppLogger.shared.debug("しりとり正規化開始: '\(word)'")
        
        guard !word.isEmpty else {
            AppLogger.shared.debug("空文字のため正規化をスキップ")
            return word
        }
        
        var result = word
        
        // ステップ1: 拗音・促音を通常の文字に変換（長音符の前に実行）
        result = convertSmallKana(result)
        
        // ステップ2: 長音符「ー」を適切な母音に変換
        result = convertLongVowelMarks(result)
        
        AppLogger.shared.debug("しりとり正規化完了: '\(word)' -> '\(result)'")
        return result
    }
    
    // MARK: - 長音符変換
    
    /// 長音符「ー」を適切な母音に変換
    private func convertLongVowelMarks(_ text: String) -> String {
        var result = ""
        var previousChar = ""
        
        for char in text {
            let charString = String(char)
            
            if charString == "ー" {
                // 前の文字が複合文字（拗音）の場合を考慮
                let vowel: String
                if result.count >= 2 {
                    // 直前の2文字を確認（拗音の場合）
                    let lastTwoChars = String(result.suffix(2))
                    vowel = getCorrespondingVowelForLongMark(previousChar: previousChar, context: lastTwoChars)
                } else {
                    vowel = getCorrespondingVowelForLongMark(previousChar: previousChar, context: previousChar)
                }
                result += vowel
                AppLogger.shared.debug("長音符変換: 前の文字'\(previousChar)' (コンテキスト: '\(result.suffix(2))') -> 母音'\(vowel)'")
            } else {
                result += charString
                previousChar = charString
            }
        }
        
        return result
    }
    
    /// 長音符専用の母音判定（複雑な変換ルールに対応）
    private func getCorrespondingVowelForLongMark(previousChar: String, context: String) -> String {
        // 通常の母音判定に従う（特別なケースは実装しない）
        return getCorrespondingVowel(for: previousChar)
    }
    
    /// 文字に対応する母音を取得
    public func getCorrespondingVowel(for character: String) -> String {
        guard !character.isEmpty else { return "あ" }
        
        let char = character.first!
        
        // 特別なケース: 拗音の場合は元の音に基づく母音を返す
        switch character {
        case "しょ", "ちょ", "にょ", "ひょ", "みょ", "りょ", "ぎょ", "じょ", "びょ", "ぴょ", "きょ":
            return "う" // 「しょー」→「しょう」
        case "しゃ", "ちゃ", "にゃ", "ひゃ", "みゃ", "りゃ", "ぎゃ", "じゃ", "びゃ", "ぴゃ", "きゃ":
            return "あ" // 「しゃー」→「しゃあ」
        case "しゅ", "ちゅ", "にゅ", "ひゅ", "みゅ", "りゅ", "ぎゅ", "じゅ", "びゅ", "ぴゅ", "きゅ":
            return "う" // 「しゅー」→「しゅう」
        default:
            break
        }
        
        // ひらがなの母音系統を判定
        switch char {
        // あ行系統
        case "あ", "か", "が", "さ", "ざ", "た", "だ", "な", "は", "ば", "ぱ", "ま", "や", "ら", "わ", "ん":
            return "あ"
        // い行系統
        case "い", "き", "ぎ", "し", "じ", "ち", "ぢ", "に", "ひ", "び", "ぴ", "み", "り":
            return "い"
        // う行系統
        case "う", "く", "ぐ", "す", "ず", "つ", "づ", "ぬ", "ふ", "ぶ", "ぷ", "む", "ゆ", "る":
            return "う"
        // え行系統
        case "え", "け", "げ", "せ", "ぜ", "て", "で", "ね", "へ", "べ", "ぺ", "め", "れ":
            return "え"
        // お行系統
        case "お", "こ", "ご", "そ", "ぞ", "と", "ど", "の", "ほ", "ぼ", "ぽ", "も", "よ", "ろ", "を":
            return "う" // 「よ」は「う」音に変換（「しょー」→「しょう」）
        default:
            AppLogger.shared.warning("未対応の文字: '\(character)' - デフォルト母音'あ'を使用")
            return "あ"
        }
    }
    
    // MARK: - 拗音・促音変換
    
    /// 拗音・促音を通常の文字に変換
    private func convertSmallKana(_ text: String) -> String {
        var result = ""
        
        for char in text {
            let charString = String(char)
            let normalizedChar = convertSmallToNormalKana(charString)
            result += normalizedChar
        }
        
        return result
    }
    
    /// 小書き文字を通常の文字に変換
    public func convertSmallToNormalKana(_ character: String) -> String {
        switch character {
        case "ゃ": return "や"
        case "ゅ": return "ゆ"
        case "ょ": return "よ"
        case "っ": return "つ"
        case "ぁ": return "あ"
        case "ぃ": return "い"
        case "ぅ": return "う"
        case "ぇ": return "え"
        case "ぉ": return "お"
        default: return character
        }
    }
    
    // MARK: - ユーティリティメソッド
    
    /// 単語がしりとり正規化を必要とするかチェック
    public func needsNormalization(_ word: String) -> Bool {
        return word.contains("ー") || 
               word.contains("ゃ") || word.contains("ゅ") || word.contains("ょ") ||
               word.contains("っ") || word.contains("ぁ") || word.contains("ぃ") ||
               word.contains("ぅ") || word.contains("ぇ") || word.contains("ぉ")
    }
    
    /// 正規化によってしりとりの接続性が改善されるかチェック
    public func improvesShiritoriConnection(word1: String, word2: String) -> Bool {
        let normalized1 = normalizeForShiritori(word1)
        let normalized2 = normalizeForShiritori(word2)
        
        let originalLastChar = String(word1.suffix(1))
        let originalFirstChar = String(word2.prefix(1))
        let normalizedLastChar = String(normalized1.suffix(1))
        let normalizedFirstChar = String(normalized2.prefix(1))
        
        let originalConnection = originalLastChar == originalFirstChar
        let normalizedConnection = normalizedLastChar == normalizedFirstChar
        
        return !originalConnection && normalizedConnection
    }
}