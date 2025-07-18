//
//  ShiritoriRuleEngine.swift
//  ShiritoriApp
//
//  Created on 2025/07/12
//

import Foundation

// MARK: - しりとりエラー種別
enum ShiritoriErrorType {
    case invalidConnection   // 文字の接続が不正
    case endsWithN          // 「ん」で終わる単語
    case duplicateWord      // 重複した単語
    case emptyWord          // 空の単語
    case invalidWord        // 無効な単語（意味のない繰り返しなど）
}

// MARK: - しりとり検証結果
struct ShiritoriValidationResult {
    let isValid: Bool
    let errorType: ShiritoriErrorType?
    let errorMessage: String?
    
    init(isValid: Bool, errorType: ShiritoriErrorType? = nil, errorMessage: String? = nil) {
        self.isValid = isValid
        self.errorType = errorType
        self.errorMessage = errorMessage
    }
}

// MARK: - しりとりルールエンジン
final class ShiritoriRuleEngine {
    
    private let wordValidator = WordValidator()
    private let wordNormalizer = ShiritoriWordNormalizer()
    
    // MARK: - イニシャライザ
    init() {
        AppLogger.shared.info("ShiritoriRuleEngineを初期化しました")
    }
    
    // MARK: - しりとりチェーン全体の検証
    func validateShiritoriChain(_ words: [String]) -> ShiritoriValidationResult {
        AppLogger.shared.debug("しりとりチェーンの検証開始: \(words.count)個の単語")
        
        guard !words.isEmpty else {
            AppLogger.shared.warning("空の単語リストが渡されました")
            return ShiritoriValidationResult(isValid: false, errorType: .emptyWord, errorMessage: "単語が入力されていません")
        }
        
        // 重複チェック
        let uniqueWords = Set(words)
        if uniqueWords.count != words.count {
            AppLogger.shared.error("重複した単語が検出されました")
            return ShiritoriValidationResult(isValid: false, errorType: .duplicateWord, errorMessage: "同じ単語を複数回使用することはできません")
        }
        
        // 各単語の検証
        for (index, word) in words.enumerated() {
            // 単語の妥当性チェック（意味のない繰り返しなど）
            if !wordValidator.isValidWord(word) {
                AppLogger.shared.error("無効な単語が検出されました: \(word) (位置: \(index))")
                return ShiritoriValidationResult(isValid: false, errorType: .invalidWord, errorMessage: "「\(word)」は意味のない言葉のため使用できません")
            }
            
            // 「ん」で終わる単語チェック
            if word.hasSuffix("ん") {
                AppLogger.shared.error("「ん」で終わる単語が検出されました: \(word) (位置: \(index))")
                return ShiritoriValidationResult(isValid: false, errorType: .endsWithN, errorMessage: "「\(word)」は「ん」で終わるため使用できません")
            }
        }
        
        // しりとり接続チェック
        for i in 1..<words.count {
            let previousWord = words[i-1]
            let currentWord = words[i]
            
            if !canWordFollow(previousWord: previousWord, nextWord: currentWord) {
                AppLogger.shared.error("しりとり接続エラー: \(previousWord) → \(currentWord)")
                return ShiritoriValidationResult(isValid: false, errorType: .invalidConnection, errorMessage: "「\(previousWord)」の次に「\(currentWord)」は続けません")
            }
        }
        
        AppLogger.shared.info("しりとりチェーンが有効です: \(words.joined(separator: " → "))")
        return ShiritoriValidationResult(isValid: true)
    }
    
    // MARK: - 単語の接続チェック
    func canWordFollow(previousWord: String, nextWord: String) -> Bool {
        guard !previousWord.isEmpty && !nextWord.isEmpty else {
            AppLogger.shared.warning("空の単語での接続チェックが試行されました")
            return false
        }
        
        // しりとり用に正規化した単語で接続チェック
        let normalizedPrevious = wordNormalizer.normalizeForShiritori(previousWord)
        let normalizedNext = wordNormalizer.normalizeForShiritori(nextWord)
        
        let previousLastChar = String(normalizedPrevious.suffix(1))
        let nextFirstChar = String(normalizedNext.prefix(1))
        
        let canFollow = previousLastChar == nextFirstChar
        
        if normalizedPrevious != previousWord || normalizedNext != nextWord {
            AppLogger.shared.debug("正規化適用: '\(previousWord)' -> '\(normalizedPrevious)', '\(nextWord)' -> '\(normalizedNext)'")
        }
        AppLogger.shared.debug("単語接続チェック: '\(normalizedPrevious)'(\(previousLastChar)) → '\(normalizedNext)'(\(nextFirstChar)) = \(canFollow)")
        
        return canFollow
    }
    
    // MARK: - 単語のしりとり適性チェック
    func isWordValidForShiritori(_ word: String) -> Bool {
        guard !word.isEmpty else {
            AppLogger.shared.debug("空の単語は無効です")
            return false
        }
        
        // WordValidatorによる妥当性チェック
        guard wordValidator.isValidWord(word) else {
            AppLogger.shared.debug("単語 '\(word)' は無効な単語です")
            return false
        }
        
        // 正規化した単語で「ん」終了チェック
        let normalizedWord = wordNormalizer.normalizeForShiritori(word)
        let isValid = !normalizedWord.hasSuffix("ん")
        
        if normalizedWord != word {
            AppLogger.shared.debug("正規化適用: '\(word)' -> '\(normalizedWord)'")
        }
        AppLogger.shared.debug("単語 '\(word)' のしりとり適性: \(isValid)")
        
        return isValid
    }
    
    // MARK: - 使用済み単語の検索
    func findUsedWords(_ word: String, in existingWords: [String]) -> [String] {
        let usedWords = existingWords.filter { $0 == word }
        
        AppLogger.shared.debug("単語 '\(word)' の使用履歴: \(usedWords.count)回")
        
        return usedWords
    }
}