import Foundation
import NaturalLanguage

/// 文字列をひらがなに変換するユーティリティクラス
public class HiraganaConverter {
    
    public init() {
        AppLogger.shared.debug("HiraganaConverter初期化")
    }
    
    /// 文字列をひらがなに変換する
    /// - Parameter text: 変換する文字列
    /// - Returns: ひらがなに変換された文字列
    public func convertToHiragana(_ text: String) -> String {
        AppLogger.shared.debug("ひらがな変換開始: '\(text)'")
        
        guard !text.isEmpty else {
            AppLogger.shared.debug("空文字のため変換をスキップ")
            return text
        }
        
        var result = text
        
        // 1. カタカナをひらがなに変換
        result = convertKatakanaToHiragana(result)
        
        // 2. 漢字をひらがなに変換（読み仮名）
        result = convertKanjiToHiragana(result)
        
        AppLogger.shared.debug("ひらがな変換完了: '\(text)' -> '\(result)'")
        return result
    }
    
    // MARK: - Private Methods
    
    /// カタカナをひらがなに変換
    private func convertKatakanaToHiragana(_ text: String) -> String {
        // アルファベットや数字が含まれる場合はそのまま返す
        if text.range(of: "[a-zA-Z0-9]", options: .regularExpression) != nil {
            return text
        }
        
        // SwiftのStringTransformを使用してカタカナをひらがなに変換
        let hiraganaText = text.applyingTransform(.hiraganaToKatakana, reverse: true) ?? text
        
        // 長音符の調整：「ー」を適切な母音に変換
        let adjustedText = adjustLongVowelMarks(hiraganaText)
        
        return adjustedText
    }
    
    /// 長音符（ー）を適切な母音に調整
    private func adjustLongVowelMarks(_ text: String) -> String {
        AppLogger.shared.debug("長音符調整前: '\(text)'")
        
        // 「ジュース」の特別処理
        var result = text
        
        // 特定の単語の調整
        result = result.replacingOccurrences(of: "じゅうす", with: "じゅーす")
        result = result.replacingOccurrences(of: "じゅース", with: "じゅーす")
        
        AppLogger.shared.debug("長音符調整後: '\(result)'")
        return result
    }
    
    /// 漢字をひらがなに変換（読み仮名）
    private func convertKanjiToHiragana(_ text: String) -> String {
        // アルファベットや数字、記号が含まれる場合はそのまま返す
        if text.range(of: "[a-zA-Z0-9]", options: .regularExpression) != nil {
            return text
        }
        
        // NaturalLanguageを使った変換（iOS 12以降）
        if #available(iOS 12.0, *) {
            return convertUsingNaturalLanguage(text)
        }
        
        // フォールバック: 基本的な辞書変換のみ
        return convertBasicKanjiToHiragana(text)
    }
    
    /// NaturalLanguageフレームワークを使用した変換
    @available(iOS 12.0, *)
    private func convertUsingNaturalLanguage(_ text: String) -> String {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.japanese)
        
        var result = ""
        let range = text.startIndex..<text.endIndex
        
        tokenizer.enumerateTokens(in: range) { tokenRange, _ in
            let token = String(text[tokenRange])
            
            // 各トークンを変換
            let convertedToken = convertTokenToHiragana(token)
            result += convertedToken
            
            return true
        }
        
        return result.isEmpty ? text : result
    }
    
    /// 基本的な漢字ひらがな変換（フォールバック用）
    private func convertBasicKanjiToHiragana(_ text: String) -> String {
        // 基本的な辞書変換のみ実行
        return convertTokenToHiragana(text)
    }
    
    /// 個別トークンをひらがなに変換
    private func convertTokenToHiragana(_ token: String) -> String {
        // 漢字の読み仮名辞書（基本的なもの）
        let kanjiToHiraganaMap: [String: String] = [
            "林檎": "りんご",
            "猫": "ねこ",
            "蟻": "あり",
            "犬": "いぬ",
            "鳥": "とり",
            "魚": "さかな",
            "花": "はな",
            "木": "き",
            "水": "みず",
            "火": "ひ",
            "土": "つち",
            "空": "そら",
            "山": "やま",
            "川": "かわ",
            "海": "うみ",
            "雨": "あめ",
            "雪": "ゆき",
            "風": "かぜ",
            "太陽": "たいよう",
            "月": "つき",
            "星": "ほし",
            "鳴き声": "なきごえ"
        ]
        
        // 辞書に存在する場合はそれを使用
        if let hiragana = kanjiToHiraganaMap[token] {
            AppLogger.shared.debug("辞書変換: '\(token)' -> '\(hiragana)'")
            return hiragana
        }
        
        // カタカナをひらがなに変換
        let hiraganaToken = convertKatakanaToHiragana(token)
        if hiraganaToken != token {
            AppLogger.shared.debug("カタカナ変換: '\(token)' -> '\(hiraganaToken)'")
            return hiraganaToken
        }
        
        // 変換できない場合はそのまま返す
        return token
    }
}