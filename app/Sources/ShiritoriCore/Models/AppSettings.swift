import Foundation
import SwiftData

/// アプリケーション設定を管理するモデル
@Model
public final class AppSettings {
    
    // MARK: - プロパティ
    
    /// 設定ID（シングルトンパターン用）
    public var id: String
    
    /// デフォルト入力方式（true: 音声入力, false: キーボード入力）
    var defaultInputMode: Bool
    
    /// 音声入力の自動提出機能（true: 有効, false: 無効）
    var voiceAutoSubmit: Bool
    
    /// 音声認識の感度設定（0.0-1.0）
    var voiceSensitivity: Double
    
    /// 自動フォールバック機能（true: 有効, false: 無効）
    var autoFallbackEnabled: Bool
    
    /// 音声認識失敗閾値（1-5回、デフォルト3回）
    var speechFailureThreshold: Int
    
    /// 設定の最終更新日時
    var lastUpdated: Date
    
    // MARK: - イニシャライザ
    
    public init(
        defaultInputMode: Bool = true, // デフォルトを音声入力に変更
        voiceAutoSubmit: Bool = true,
        voiceSensitivity: Double = 0.7,
        autoFallbackEnabled: Bool = true,
        speechFailureThreshold: Int = 3
    ) {
        AppLogger.shared.info("AppSettings初期化: defaultInputMode=\(defaultInputMode), autoFallback=\(autoFallbackEnabled), threshold=\(speechFailureThreshold)")
        
        self.id = "app_settings_singleton"
        self.defaultInputMode = defaultInputMode
        self.voiceAutoSubmit = voiceAutoSubmit
        self.voiceSensitivity = voiceSensitivity
        self.autoFallbackEnabled = autoFallbackEnabled
        self.speechFailureThreshold = max(1, min(5, speechFailureThreshold)) // 1-5の範囲に制限
        self.lastUpdated = Date()
    }
    
    // MARK: - メソッド
    
    /// 設定を更新
    func updateSettings(
        defaultInputMode: Bool? = nil,
        voiceAutoSubmit: Bool? = nil,
        voiceSensitivity: Double? = nil,
        autoFallbackEnabled: Bool? = nil,
        speechFailureThreshold: Int? = nil
    ) {
        AppLogger.shared.debug("設定更新開始")
        
        if let defaultInputMode = defaultInputMode {
            self.defaultInputMode = defaultInputMode
            AppLogger.shared.info("デフォルト入力方式を更新: \(defaultInputMode ? "音声入力" : "キーボード入力")")
        }
        
        if let voiceAutoSubmit = voiceAutoSubmit {
            self.voiceAutoSubmit = voiceAutoSubmit
            AppLogger.shared.info("音声自動提出を更新: \(voiceAutoSubmit)")
        }
        
        if let voiceSensitivity = voiceSensitivity {
            self.voiceSensitivity = max(0.0, min(1.0, voiceSensitivity))
            AppLogger.shared.info("音声感度を更新: \(self.voiceSensitivity)")
        }
        
        if let autoFallbackEnabled = autoFallbackEnabled {
            self.autoFallbackEnabled = autoFallbackEnabled
            AppLogger.shared.info("自動フォールバック機能を更新: \(autoFallbackEnabled)")
        }
        
        if let speechFailureThreshold = speechFailureThreshold {
            self.speechFailureThreshold = max(1, min(5, speechFailureThreshold))
            AppLogger.shared.info("音声認識失敗閾値を更新: \(self.speechFailureThreshold)")
        }
        
        self.lastUpdated = Date()
        AppLogger.shared.debug("設定更新完了")
    }
    
    /// デフォルト設定にリセット
    func resetToDefaults() {
        AppLogger.shared.info("設定をデフォルトにリセット")
        
        self.defaultInputMode = true  // 音声入力をデフォルト
        self.voiceAutoSubmit = true
        self.voiceSensitivity = 0.7
        self.autoFallbackEnabled = true
        self.speechFailureThreshold = 3
        self.lastUpdated = Date()
    }
}

// MARK: - 入力方式の列挙型

/// 入力方式の種類
public enum InputMode: String, CaseIterable, Identifiable {
    case voice = "voice"
    case keyboard = "keyboard"
    
    public var id: String { rawValue }
    
    /// 表示名
    public var displayName: String {
        switch self {
        case .voice:
            return "音声入力"
        case .keyboard:
            return "キーボード入力"
        }
    }
    
    /// アイコン名
    public var iconName: String {
        switch self {
        case .voice:
            return "mic.fill"
        case .keyboard:
            return "keyboard"
        }
    }
    
    /// 子供向けの説明
    public var childFriendlyDescription: String {
        switch self {
        case .voice:
            return "こえで ことばを いうよ"
        case .keyboard:
        return "ゆびで もじを うつよ"
        }
    }
}