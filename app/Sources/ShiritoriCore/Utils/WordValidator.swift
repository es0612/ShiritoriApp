import Foundation

/// 単語の妥当性を検証するクラス
public class WordValidator {
    
    public init() {
        AppLogger.shared.debug("WordValidator初期化")
    }
    
    /// 単語が妥当かどうかを判定する
    /// - Parameter word: 検証する単語
    /// - Returns: 妥当な場合true
    public func isValidWord(_ word: String) -> Bool {
        AppLogger.shared.debug("単語検証開始: '\(word)'")
        
        guard !word.isEmpty else {
            AppLogger.shared.debug("空文字のため無効")
            return false
        }
        
        // 有効な文字のみを含むかチェック
        if !containsOnlyValidCharacters(word) {
            AppLogger.shared.debug("無効な文字を含むため無効")
            return false
        }
        
        // 1文字の単語は無効
        guard word.count >= 2 else {
            AppLogger.shared.debug("1文字の単語のため無効")
            return false
        }
        
        // 繰り返しパターンチェック
        if isInvalidRepeatPattern(word) {
            AppLogger.shared.debug("無効な繰り返しパターンのため無効")
            return false
        }
        
        // その他の無効パターンチェック
        if isInvalidPattern(word) {
            AppLogger.shared.debug("無効なパターンのため無効")
            return false
        }
        
        AppLogger.shared.debug("単語検証完了: '\(word)' -> 有効")
        return true
    }
    
    /// 入力を清浄化する（無効な文字を除去）
    /// - Parameter input: 入力テキスト
    /// - Returns: 清浄化されたひらがなのみのテキスト
    public func sanitizeInput(_ input: String) -> String {
        AppLogger.shared.debug("入力清浄化開始: '\(input)'")
        
        let sanitized = input.compactMap { char in
            let charString = String(char)
            return isValidHiraganaCharacter(charString) ? char : nil
        }.map(String.init).joined()
        
        AppLogger.shared.debug("入力清浄化完了: '\(input)' -> '\(sanitized)'")
        return sanitized
    }
    
    /// 有効な文字のみを含むかチェック
    private func containsOnlyValidCharacters(_ text: String) -> Bool {
        for char in text {
            if !isValidHiraganaCharacter(String(char)) {
                AppLogger.shared.debug("無効な文字検出: '\(char)' in '\(text)'")
                return false
            }
        }
        return true
    }
    
    /// 有効なひらがな文字かチェック
    private func isValidHiraganaCharacter(_ char: String) -> Bool {
        guard let scalar = char.unicodeScalars.first else { return false }
        
        // ひらがな範囲（あ-ん）
        if scalar.value >= 0x3042 && scalar.value <= 0x3093 {
            return true
        }
        
        // 小書き文字と長音符
        let validSpecialChars: Set<String> = ["ゃ", "ゅ", "ょ", "っ", "ぁ", "ぃ", "ぅ", "ぇ", "ぉ", "ー"]
        return validSpecialChars.contains(char)
    }
    
    // MARK: - Private Methods
    
    /// 無効な繰り返しパターンかどうかを判定
    private func isInvalidRepeatPattern(_ word: String) -> Bool {
        let characters = Array(word)
        
        // 全て同じ文字の場合は無効
        if characters.allSatisfy({ $0 == characters.first }) {
            AppLogger.shared.debug("全て同じ文字: '\(word)'")
            return true
        }
        
        // 2文字の繰り返しパターン（例: "るる", "かか"）
        if word.count == 2 {
            if characters[0] == characters[1] {
                AppLogger.shared.debug("2文字の繰り返し: '\(word)'")
                return true
            }
        }
        
        // 3文字以上で同じ文字が連続している場合
        if word.count >= 3 {
            for i in 0..<(characters.count - 2) {
                if characters[i] == characters[i + 1] && 
                   characters[i + 1] == characters[i + 2] {
                    AppLogger.shared.debug("3文字以上の連続繰り返し: '\(word)'")
                    return true
                }
            }
        }
        
        return false
    }
    
    /// その他の無効パターンかどうかを判定
    private func isInvalidPattern(_ word: String) -> Bool {
        // 助詞の不適切な使用
        let invalidPatterns = [
            "をををを",
            "ははは",
            "にににに",
            "でででで",
            "がががが"
        ]
        
        for pattern in invalidPatterns {
            if word.contains(pattern) {
                AppLogger.shared.debug("無効パターン検出: '\(pattern)' in '\(word)'")
                return true
            }
        }
        
        return false
    }
}