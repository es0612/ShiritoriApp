import SwiftUI
import Foundation

/// 入力検証管理クラス
/// WordInputViewから入力検証・変換ロジックを分離して、責務を明確化
@Observable
public class InputValidationManager {
    
    // MARK: - Dependencies
    private let hiraganaConverter = HiraganaConverter()
    private let wordValidator = WordValidator()
    
    // MARK: - Validation Results
    public enum ValidationResult {
        case valid(processedWord: String, originalWord: String)
        case empty(reason: String)
        case invalid(reason: String)
        
        var isValid: Bool {
            switch self {
            case .valid:
                return true
            case .empty, .invalid:
                return false
            }
        }
        
        var processedWord: String? {
            switch self {
            case .valid(let processedWord, _):
                return processedWord
            case .empty, .invalid:
                return nil
            }
        }
        
        var errorMessage: String? {
            switch self {
            case .valid:
                return nil
            case .empty(let reason), .invalid(let reason):
                return reason
            }
        }
    }
    
    // MARK: - Validation Settings
    public struct ValidationSettings {
        public let allowEmptyInput: Bool
        public let maxLength: Int
        public let minLength: Int
        public let requireHiragana: Bool
        
        public init(
            allowEmptyInput: Bool = false,
            maxLength: Int = 20,
            minLength: Int = 1,
            requireHiragana: Bool = true
        ) {
            self.allowEmptyInput = allowEmptyInput
            self.maxLength = maxLength
            self.minLength = minLength
            self.requireHiragana = requireHiragana
        }
        
        public static let defaultSettings = ValidationSettings()
    }
    
    public init() {
        AppLogger.shared.debug("InputValidationManager初期化完了")
    }
    
    // MARK: - Main Validation Method
    
    /// 入力文字列を検証・変換する
    /// @param rawInput 生の入力文字列
    /// @param settings 検証設定（デフォルトあり）
    /// @return 検証結果
    public func validateAndProcessInput(
        _ rawInput: String,
        settings: ValidationSettings = .defaultSettings
    ) -> ValidationResult {
        
        AppLogger.shared.debug("入力検証開始: '\(rawInput)'")
        
        // Step 1: 基本的な前処理
        let trimmedInput = rawInput.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Step 2: 空文字チェック
        if trimmedInput.isEmpty {
            if settings.allowEmptyInput {
                return .valid(processedWord: "", originalWord: rawInput)
            } else {
                return .empty(reason: "文字を入力してください")
            }
        }
        
        // Step 3: 入力清浄化（無効な文字を除去）
        let sanitizedInput = wordValidator.sanitizeInput(trimmedInput)
        
        if sanitizedInput.isEmpty {
            AppLogger.shared.warning("清浄化後に空文字になりました: '\(trimmedInput)'")
            return .invalid(reason: "有効な文字が含まれていません")
        }
        
        if sanitizedInput != trimmedInput {
            AppLogger.shared.info("入力清浄化: '\(trimmedInput)' -> '\(sanitizedInput)'")
        }
        
        // Step 4: 長さ制限チェック
        if sanitizedInput.count > settings.maxLength {
            return .invalid(reason: "文字数が多すぎます（最大\(settings.maxLength)文字）")
        }
        
        if sanitizedInput.count < settings.minLength {
            return .invalid(reason: "文字数が少なすぎます（最小\(settings.minLength)文字）")
        }
        
        // Step 5: ひらがな変換（正規化は行わない）
        let hiraganaWord = hiraganaConverter.convertToHiragana(sanitizedInput)
        
        if hiraganaWord != sanitizedInput {
            AppLogger.shared.info("ひらがな変換: '\(sanitizedInput)' -> '\(hiraganaWord)'")
        }
        
        // Step 6: ひらがな要求チェック
        if settings.requireHiragana && !isValidHiraganaWord(hiraganaWord) {
            return .invalid(reason: "ひらがなの単語を入力してください")
        }
        
        // Step 7: 単語の形式チェック
        let wordFormatResult = validateWordFormat(hiraganaWord)
        if let error = wordFormatResult {
            return .invalid(reason: error)
        }
        
        AppLogger.shared.info("入力検証成功: '\(hiraganaWord)'")
        return .valid(processedWord: hiraganaWord, originalWord: rawInput)
    }
    
    // MARK: - Quick Validation Methods
    
    /// 単語提出用の簡易検証（デフォルト設定）
    public func validateForSubmission(_ input: String) -> ValidationResult {
        return validateAndProcessInput(input, settings: .defaultSettings)
    }
    
    /// 音声認識結果用の検証（より寛容な設定）
    public func validateSpeechRecognitionResult(_ input: String) -> ValidationResult {
        let speechSettings = ValidationSettings(
            allowEmptyInput: false,
            maxLength: 25, // 音声認識では少し長めも許可
            minLength: 1,
            requireHiragana: true
        )
        return validateAndProcessInput(input, settings: speechSettings)
    }
    
    /// リアルタイム入力用の検証（制限を緩和）
    public func validateRealTimeInput(_ input: String) -> ValidationResult {
        let realtimeSettings = ValidationSettings(
            allowEmptyInput: true, // リアルタイムでは空文字も許可
            maxLength: 30,
            minLength: 0,
            requireHiragana: false // リアルタイムではひらがな要求なし
        )
        return validateAndProcessInput(input, settings: realtimeSettings)
    }
    
    // MARK: - Format Validation Helpers
    
    /// ひらがな単語の妥当性チェック
    private func isValidHiraganaWord(_ word: String) -> Bool {
        // ひらがなの文字範囲（U+3041-U+3096）と一部の記号のみ許可
        let hiraganaRange = CharacterSet(charactersIn: "\u{3041}"..."\u{3096}")
        let allowedCharacterSet = hiraganaRange.union(CharacterSet(charactersIn: "ー・"))
        let wordCharacterSet = CharacterSet(charactersIn: word)
        return allowedCharacterSet.isSuperset(of: wordCharacterSet)
    }
    
    /// 単語形式の詳細検証
    private func validateWordFormat(_ word: String) -> String? {
        // 連続する同じ文字のチェック（例：「あああ」）
        if hasRepeatingCharacters(word, maxRepeats: 3) {
            return "同じ文字が連続しすぎています"
        }
        
        // 特殊文字の組み合わせチェック
        if hasInvalidCharacterCombination(word) {
            return "無効な文字の組み合わせです"
        }
        
        // しりとりで使えない文字で終わっているかチェック
        if endsWithInvalidCharacter(word) {
            return "「ん」で終わる単語は使用できません"
        }
        
        return nil
    }
    
    /// 連続する同じ文字のチェック
    private func hasRepeatingCharacters(_ word: String, maxRepeats: Int) -> Bool {
        var count = 1
        var previousChar: Character?
        
        for char in word {
            if let prev = previousChar, prev == char {
                count += 1
                if count > maxRepeats {
                    return true
                }
            } else {
                count = 1
            }
            previousChar = char
        }
        
        return false
    }
    
    /// 無効な文字組み合わせのチェック
    private func hasInvalidCharacterCombination(_ word: String) -> Bool {
        // 長音記号の連続チェック
        if word.contains("ーー") {
            return true
        }
        
        // 中黒の不適切な使用チェック
        if word.hasPrefix("・") || word.hasSuffix("・") {
            return true
        }
        
        return false
    }
    
    /// しりとりで無効な終了文字のチェック
    private func endsWithInvalidCharacter(_ word: String) -> Bool {
        let invalidEndingCharacters = ["ん", "ン"]
        return invalidEndingCharacters.contains { word.hasSuffix($0) }
    }
    
    // MARK: - Character Analysis
    
    /// 単語の最初の文字を取得（しりとり用）
    public func getFirstCharacter(_ word: String) -> String? {
        guard let firstChar = word.first else { return nil }
        return String(firstChar)
    }
    
    /// 単語の最後の文字を取得（しりとり用）
    public func getLastCharacter(_ word: String) -> String? {
        guard let lastChar = word.last else { return nil }
        
        // 長音記号で終わる場合は、その前の文字を返す
        if lastChar == "ー" && word.count > 1 {
            let secondToLast = word.dropLast().last
            return secondToLast.map(String.init)
        }
        
        return String(lastChar)
    }
    
    /// ひらがな文字の正規化（濁音・半濁音の処理）
    public func normalizeHiraganaCharacter(_ char: String) -> String {
        let normalizations: [String: String] = [
            // 濁音
            "が": "か", "ぎ": "き", "ぐ": "く", "げ": "け", "ご": "こ",
            "ざ": "さ", "じ": "し", "ず": "す", "ぜ": "せ", "ぞ": "そ",
            "だ": "た", "ぢ": "ち", "づ": "つ", "で": "て", "ど": "と",
            "ば": "は", "び": "ひ", "ぶ": "ふ", "べ": "へ", "ぼ": "ほ",
            // 半濁音
            "ぱ": "は", "ぴ": "ひ", "ぷ": "ふ", "ぺ": "へ", "ぽ": "ほ"
        ]
        
        return normalizations[char] ?? char
    }
    
    // MARK: - Debug & Statistics
    
    /// 検証統計情報
    public struct ValidationStatistics {
        public let totalValidations: Int
        public let successfulValidations: Int
        public let failedValidations: Int
        public let averageInputLength: Double
        public let commonFailureReasons: [String: Int]
        
        public var successRate: Double {
            guard totalValidations > 0 else { return 0.0 }
            return Double(successfulValidations) / Double(totalValidations)
        }
    }
    
    private var validationCount = 0
    private var successCount = 0
    private var failureReasons: [String] = []
    private var inputLengths: [Int] = []
    
    /// 検証統計の更新
    private func updateStatistics(result: ValidationResult, inputLength: Int) {
        validationCount += 1
        inputLengths.append(inputLength)
        
        switch result {
        case .valid:
            successCount += 1
        case .empty(let reason), .invalid(let reason):
            failureReasons.append(reason)
        }
    }
    
    /// 検証統計の取得
    public func getValidationStatistics() -> ValidationStatistics {
        let averageLength = inputLengths.isEmpty ? 0.0 : Double(inputLengths.reduce(0, +)) / Double(inputLengths.count)
        
        let reasonCounts = failureReasons.reduce(into: [String: Int]()) { counts, reason in
            counts[reason, default: 0] += 1
        }
        
        return ValidationStatistics(
            totalValidations: validationCount,
            successfulValidations: successCount,
            failedValidations: validationCount - successCount,
            averageInputLength: averageLength,
            commonFailureReasons: reasonCounts
        )
    }
    
    /// 統計のリセット
    public func resetStatistics() {
        validationCount = 0
        successCount = 0
        failureReasons.removeAll()
        inputLengths.removeAll()
        AppLogger.shared.debug("InputValidationManager統計をリセット")
    }
}